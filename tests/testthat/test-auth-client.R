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
  
  req <- az_request("_apis/projects", client = client)
  expect_s3_class(req, "httr2_request")
  expect_equal(req$url, "https://dev.azure.com/testorg/_apis/projects?api-version=7.0")
  
  # Request with custom query and scoped to project
  req_proj <- az_request("test_endpoint", client = client, query = list(top = 10))
  expect_equal(req_proj$url, "https://dev.azure.com/testorg/DemoProject/test_endpoint?api-version=7.0&top=10")
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

test_that("az_perform handles 204 No Content gracefully", {
  mock_handler <- function(req) {
    httr2::response(status_code = 204)
  }
  
  client <- az_client(organization = "testorg", pat = "secret_pat")
  httr2::with_mocked_responses(mock_handler, {
    req <- az_request("_apis/dummy", client = client)
    res <- az_perform(req)
    expect_null(res)
  })
})
