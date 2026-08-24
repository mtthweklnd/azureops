test_that("az_test_plans_list, az_test_suites_list, and az_test_cases_list work", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_plans_payload <- list(
    value = list(
      list(id = 10L, name = "Q3 Release Test Plan", state = "Active", areaPath = "Backend", iteration = "Sprint 1")
    )
  )
  
  mock_suites_payload <- list(
    value = list(
      list(id = 20L, name = "Auth Suite", suiteType = "StaticTestSuite", parentSuite = list(id = 10L))
    )
  )
  
  mock_cases_payload <- list(
    value = list(
      list(workItem = list(id = 301L, name = "Valid login returns JWT", state = "Design"), priority = 1L)
    )
  )
  
  mock_handler <- function(req) {
    if (grepl("TestCase", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_cases_payload, auto_unbox = TRUE))
      )
    } else if (grepl("suites", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_suites_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_plans_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    plans <- az_test_plans_list(client = client)
    expect_equal(nrow(plans), 1)
    expect_equal(plans$id, 10L)
    expect_equal(plans$name, "Q3 Release Test Plan")
    
    suites <- az_test_suites_list(10L, client = client)
    expect_equal(nrow(suites), 1)
    expect_equal(suites$id, 20L)
    
    cases <- az_test_cases_list(10L, 20L, client = client)
    expect_equal(nrow(cases), 1)
    expect_equal(cases$id, 301L)
    expect_equal(cases$title, "Valid login returns JWT")
  })
})

test_that("az_test_run_metrics_get and az_code_coverage_get retrieve quality metrics", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_run_payload <- list(
    id = 900L,
    name = "Automated Unit Tests",
    state = "Completed",
    totalTests = 50L,
    passedTests = 48L,
    failedTests = 2L,
    webAccessUrl = "https://dev.azure.com/testorg/proj/_TestManagement/Runs#runId=900"
  )
  
  mock_coverage_payload <- list(
    coverageData = list(
      list(
        coverageStats = list(
          list(label = "Lines", covered = 900L, total = 1000L),
          list(label = "Blocks", covered = 450L, total = 500L)
        )
      )
    )
  )
  
  mock_handler <- function(req) {
    if (grepl("codecoverage", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_coverage_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_run_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    run_metrics <- az_test_run_metrics_get(900L, client = client)
    expect_true(S7::S7_inherits(run_metrics, az_test_run))
    expect_equal(run_metrics@id, 900L)
    expect_equal(run_metrics@total_tests, 50L)
    expect_equal(run_metrics@pass_rate, 48 / 50)
    
    cov <- az_code_coverage_get(build_id = 1234L, client = client)
    expect_equal(nrow(cov), 2)
    expect_equal(cov$label, c("Lines", "Blocks"))
    expect_equal(cov$coverage_pct, c(0.9, 0.9))
  })
})
