test_that("az_pat, az_org, az_project read environment variables", {
  withr::with_envvar(c(
    AZURE_DEVOPS_PAT = "test_env_pat_99",
    AZURE_DEVOPS_ORG = "test_env_org",
    AZURE_DEVOPS_PROJECT = "test_env_proj"
  ), {
    expect_equal(az_pat(), "test_env_pat_99")
    expect_equal(az_org(), "test_env_org")
    expect_equal(az_project(), "test_env_proj")
    
    # Client constructor uses environment
    cli <- az_client()
    expect_equal(cli@organization, "test_env_org")
    expect_equal(cli@pat, "test_env_pat_99")
    expect_equal(cli@project, "test_env_proj")
  })
})

test_that("az_pat errors when no token is present", {
  withr::with_envvar(c(AZURE_DEVOPS_PAT = "", AZURE_PAT = ""), {
    expect_error(az_pat(), "Personal Access Token.*not found")
  })
})

test_that("az_request builds valid httr2 request with custom query and project", {
  client <- az_client(organization = "testorg", pat = "secret_pat", project = "DemoProject")
  
  # Org-level endpoint remains unprefixed even when client has a project
  req <- az_request("_apis/projects", client = client)
  expect_s3_class(req, "httr2_request")
  expect_equal(req$url, "https://dev.azure.com/testorg/_apis/projects?api-version=7.0")
  
  # Project-scoped endpoint gets project prefix
  req_proj <- az_request("_apis/pipelines", client = client, query = list(top = 10))
  expect_equal(req_proj$url, "https://dev.azure.com/testorg/DemoProject/_apis/pipelines?api-version=7.0&top=10")

  # Project name containing spaces and parentheses is properly URL-encoded
  client_special <- az_client(organization = "testorg", pat = "secret_pat", project = "My Project (Alpha)")
  req_special <- az_request("_apis/wit/workitems", client = client_special)
  expect_equal(req_special$url, "https://dev.azure.com/testorg/My%20Project%20%28Alpha%29/_apis/wit/workitems?api-version=7.0")

  # Literal comparison when project is already present in endpoint
  req_already <- az_request("My Project (Alpha)/_apis/wit/workitems", client = client_special)
  expect_equal(req_already$url, "https://dev.azure.com/testorg/My%20Project%20%28Alpha%29/_apis/wit/workitems?api-version=7.0")

  # Genuinely org-level endpoints remain unprefixed
  expect_equal(az_request("_apis/teams", client = client_special)$url, "https://dev.azure.com/testorg/_apis/teams?api-version=7.0")
  expect_equal(az_request("_apis/hooks/subscriptions", client = client_special)$url, "https://dev.azure.com/testorg/_apis/hooks/subscriptions?api-version=7.0")
  expect_equal(az_request("_apis/graph/groups", client = client_special, base_url = "https://vssps.dev.azure.com")$url, "https://vssps.dev.azure.com/testorg/_apis/graph/groups?api-version=7.0")
  expect_equal(az_request("_apis/userentitlements", client = client_special, base_url = "https://vsaex.dev.azure.com")$url, "https://vsaex.dev.azure.com/testorg/_apis/userentitlements?api-version=7.0")
})

test_that("az_perform extracts Azure DevOps JSON error messages on HTTP failures", {
  client <- az_client(organization = "testorg", pat = "secret_pat")
  
  mock_error_payload <- list(
    `$id` = "1",
    message = "TF400813: Resource not found for the specified project ID."
  )
  
  mock_handler <- function(req) {
    httr2::response(
      status_code = 404,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_error_payload, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    req <- az_request("_apis/projects/missing-proj", client = client)
    expect_error(
      az_perform(req),
      "TF400813: Resource not found"
    )
  })
})

test_that("az_perform handles 204 No Content and empty 200/202 bodies gracefully", {
  client <- az_client(organization = "testorg", pat = "secret_pat")

  # Status 204 No Content
  with_mock_api(function(req) {
    mock_response(NULL, status_code = 204)
  }, {
    req <- az_request("_apis/dummy", client = client)
    res <- az_perform(req)
    expect_null(res)
  })

  # Status 200 with empty body (raw(0))
  with_mock_api(function(req) {
    mock_response(NULL, status_code = 200)
  }, {
    req <- az_request("_apis/dummy", client = client)
    res <- az_perform(req)
    expect_null(res)
  })

  # Status 202 with empty body (raw(0))
  with_mock_api(function(req) {
    mock_response(NULL, status_code = 202)
  }, {
    req <- az_request("_apis/dummy", client = client)
    res <- az_perform(req)
    expect_null(res)
  })
})

test_that("az_request handles 52-character and 84-character PATs without line breaks", {
  pat_52 <- paste(rep("a", 52), collapse = "")
  pat_84 <- paste(rep("b", 84), collapse = "")
  
  cli_52 <- az_client(organization = "testorg", pat = pat_52)
  cli_84 <- az_client(organization = "testorg", pat = pat_84)
  
  req_52 <- az_request("_apis/projects", client = cli_52)
  req_84 <- az_request("_apis/projects", client = cli_84)
  
  expect_s3_class(req_52, "httr2_request")
  expect_s3_class(req_84, "httr2_request")
  
  dry_52 <- httr2::req_dry_run(req_52, quiet = TRUE)
  dry_84 <- httr2::req_dry_run(req_84, quiet = TRUE)
  expect_true(!is.null(dry_52$headers$authorization))
  expect_true(!is.null(dry_84$headers$authorization))
  
  auth_val_52 <- openssl::base64_encode(paste0(":", pat_52))
  auth_val_84 <- openssl::base64_encode(paste0(":", pat_84))
  expect_false(grepl("[\r\n]", auth_val_52))
  expect_false(grepl("[\r\n]", auth_val_84))
  
  with_mock_api(function(req) {
    mock_response(list(count = 0, value = list()))
  }, {
    res <- az_perform(req_84)
    expect_equal(res$count, 0)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/projects?api-version=7.0")
  })
})

