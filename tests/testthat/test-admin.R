test_that("az_projects_list returns a tibble of projects", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_projects_payload <- list(
    value = list(
      list(id = "proj-1", name = "Frontend", description = "Web App", state = "wellFormed", visibility = "private"),
      list(id = "proj-2", name = "Backend", description = "API Service", state = "wellFormed", visibility = "public")
    )
  )
  
  with_mock_api(function(req) {
    mock_response(mock_projects_payload)
  }, {
    projs <- az_projects_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/projects?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_s3_class(projs, "tbl_df")
    expect_equal(nrow(projs), 2)
    expect_equal(projs$name, c("Frontend", "Backend"))
  })
})

test_that("az_project_get retrieves a single project by ID", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_project_payload <- list(id = "proj-1", name = "Frontend", description = "Web App", state = "wellFormed", visibility = "private")
  
  with_mock_api(function(req) {
    mock_response(mock_project_payload)
  }, {
    proj <- az_project_get("proj-1", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/projects/proj-1?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(proj$id, "proj-1")
    expect_equal(proj$name, "Frontend")
  })
})

test_that("az_project_create sends POST request with parameters", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_create_response <- list(id = "op-123", status = "queued", url = "https://...")
  
  with_mock_api(function(req) {
    mock_response(mock_create_response, status_code = 202)
  }, {
    res <- az_project_create("NewMicroservice", description = "Core service", visibility = "private", client = client)
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/_apis/projects?api-version=7.0")
    expect_equal(req$method, "POST")
    expect_equal(req$body$data$name, "NewMicroservice")
    expect_equal(req$body$data$visibility, "private")
    expect_equal(res$id, "op-123")
  })
})

test_that("az_teams_list and az_team_members_list work", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_teams_payload <- list(
    value = list(
      list(id = "team-1", name = "Core Team", description = "Core devs", identityUrl = "https://...")
    )
  )
  
  mock_members_payload <- list(
    value = list(
      list(identity = list(id = "user-1", displayName = "Alice Dev", uniqueName = "alice@example.com"))
    )
  )
  
  with_mock_api(function(req) {
    if (grepl("/members", req$url)) {
      mock_response(mock_members_payload)
    } else {
      mock_response(mock_teams_payload)
    }
  }, {
    teams <- az_teams_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/teams?api-version=7.0")
    expect_equal(nrow(teams), 1)
    expect_equal(teams$name, "Core Team")
    
    members <- az_team_members_list(project = "Proj", team_id = "team-1", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/projects/Proj/teams/team-1/members?api-version=7.0")
    expect_equal(nrow(members), 1)
    expect_equal(members$display_name, "Alice Dev")
  })
})

test_that("az_security_groups_list and az_user_entitlements_list parse VSSPS / VSAEX services", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_groups_payload <- list(
    value = list(
      list(principalName = "[Proj]\\Contributors", displayName = "Contributors", description = "Can contribute", descriptor = "vssgp.123")
    )
  )
  
  mock_entitlements_payload <- list(
    items = list(
      list(
        id = "user-ent-1",
        user = list(displayName = "Bob DevOps", mailAddress = "bob@example.com"),
        accessLevel = list(accountLicenseType = "express", licenseDisplayName = "Basic")
      )
    )
  )
  
  with_mock_api(function(req) {
    if (grepl("userentitlements", req$url)) {
      mock_response(mock_entitlements_payload)
    } else {
      mock_response(mock_groups_payload)
    }
  }, {
    groups <- az_security_groups_list(client = client)
    expect_equal(last_request()$url, "https://vssps.dev.azure.com/testorg/_apis/graph/groups?api-version=7.1-preview.1")
    expect_s3_class(groups, "tbl_df")
    expect_equal(nrow(groups), 1)
    expect_equal(groups$display_name, "Contributors")
    
    entitlements <- az_user_entitlements_list(client = client)
    expect_equal(last_request()$url, "https://vsaex.dev.azure.com/testorg/_apis/userentitlements?api-version=7.1-preview.3")
    expect_s3_class(entitlements, "tbl_df")
    expect_equal(nrow(entitlements), 1)
    expect_equal(entitlements$display_name, "Bob DevOps")
    expect_equal(entitlements$access_level, "Basic")
  })
})

test_that("az_webhooks_list and az_webhook_create manage service hooks", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_webhooks_payload <- list(
    value = list(
      list(id = "sub-1", eventType = "workitem.created", consumerId = "webHooks", status = "enabled")
    )
  )
  
  with_mock_api(function(req) {
    if (identical(req$method, "POST")) {
      mock_response(mock_webhooks_payload$value[[1]], status_code = 201)
    } else {
      mock_response(mock_webhooks_payload)
    }
  }, {
    hooks <- az_webhooks_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/hooks/subscriptions?api-version=7.0")
    expect_s3_class(hooks, "tbl_df")
    expect_equal(nrow(hooks), 1)
    expect_equal(hooks$event_type, "workitem.created")
    
    # Missing URL raises error before request
    expect_error(az_webhook_create("workitem.created", client = client), "destination URL is required")
    
    created <- az_webhook_create(
      event_type = "workitem.created",
      url = "https://example.com/webhook",
      client = client
    )
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/_apis/hooks/subscriptions?api-version=7.0")
    expect_equal(req$method, "POST")
    expect_equal(req$body$data$eventType, "workitem.created")
    expect_equal(req$body$data$consumerInputs$url, "https://example.com/webhook")
    # Verify inputs are objects/named lists (not empty arrays)
    expect_true(is.list(req$body$data$consumerInputs))
    expect_true(is.list(req$body$data$publisherInputs))
    expect_equal(created$id, "sub-1")
    expect_equal(created$status, "enabled")
  })
})
