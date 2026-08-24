test_that("az_projects_list returns a tibble of projects", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_projects_payload <- list(
    value = list(
      list(id = "proj-1", name = "Frontend", description = "Web App", state = "wellFormed", visibility = "private"),
      list(id = "proj-2", name = "Backend", description = "API Service", state = "wellFormed", visibility = "public")
    )
  )
  
  mock_handler <- function(req) {
    httr2::response(
      status_code = 200,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_projects_payload, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    projs <- az_projects_list(client = client)
    expect_s3_class(projs, "tbl_df")
    expect_equal(nrow(projs), 2)
    expect_equal(projs$name, c("Frontend", "Backend"))
  })
})

test_that("az_project_get retrieves a single project by ID", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_project_payload <- list(id = "proj-1", name = "Frontend", description = "Web App", state = "wellFormed", visibility = "private")
  
  mock_handler <- function(req) {
    httr2::response(
      status_code = 200,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_project_payload, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    proj <- az_project_get("proj-1", client = client)
    expect_equal(proj$id, "proj-1")
    expect_equal(proj$name, "Frontend")
  })
})

test_that("az_project_create sends POST request with parameters", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_create_response <- list(id = "op-123", status = "queued", url = "https://...")
  
  mock_handler <- function(req) {
    expect_equal(req$method, "POST")
    expect_equal(req$body$data$name, "NewMicroservice")
    expect_equal(req$body$data$visibility, "private")
    httr2::response(
      status_code = 202,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_create_response, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    res <- az_project_create("NewMicroservice", description = "Core service", visibility = "private", client = client)
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
  
  mock_handler <- function(req) {
    if (grepl("/members", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_members_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_teams_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    teams <- az_teams_list(client = client)
    expect_equal(nrow(teams), 1)
    expect_equal(teams$name, "Core Team")
    
    members <- az_team_members_list(project = "Proj", team_id = "team-1", client = client)
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
  
  mock_handler <- function(req) {
    if (grepl("userentitlements", req$url)) {
      expect_match(req$url, "vsaex.dev.azure.com")
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_entitlements_payload, auto_unbox = TRUE))
      )
    } else {
      expect_match(req$url, "vssps.dev.azure.com")
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_groups_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    groups <- az_security_groups_list(client = client)
    expect_s3_class(groups, "tbl_df")
    expect_equal(nrow(groups), 1)
    expect_equal(groups$display_name, "Contributors")
    
    entitlements <- az_user_entitlements_list(client = client)
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
  
  mock_handler <- function(req) {
    if (identical(req$method, "POST")) {
      httr2::response(
        status_code = 201,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_webhooks_payload$value[[1]], auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_webhooks_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    hooks <- az_webhooks_list(client = client)
    expect_s3_class(hooks, "tbl_df")
    expect_equal(nrow(hooks), 1)
    expect_equal(hooks$event_type, "workitem.created")
    
    created <- az_webhook_create(
      event_type = "workitem.created",
      consumer_inputs = list(url = "https://example.com/webhook"),
      client = client
    )
    expect_equal(created$id, "sub-1")
    expect_equal(created$status, "enabled")
  })
})
