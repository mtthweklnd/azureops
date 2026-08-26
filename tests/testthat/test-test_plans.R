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
  
  with_mock_api(function(req) {
    if (grepl("TestCase", req$url)) {
      mock_response(mock_cases_payload)
    } else if (grepl("suites", req$url)) {
      mock_response(mock_suites_payload)
    } else {
      mock_response(mock_plans_payload)
    }
  }, {
    plans <- az_test_plans_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/testplan/plans?api-version=7.1-preview.1")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(plans), 1)
    expect_equal(plans$id, 10L)
    expect_equal(plans$name, "Q3 Release Test Plan")
    
    suites <- az_test_suites_list(10L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/testplan/Plans/10/suites?api-version=7.1-preview.1")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(suites), 1)
    expect_equal(suites$id, 20L)
    
    cases <- az_test_cases_list(10L, 20L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/testplan/Plans/10/Suites/20/TestCase?api-version=7.1-preview.1")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(cases), 1)
    expect_equal(cases$id, 301L)
    expect_equal(cases$title, "Valid login returns JWT")
  })
})

test_that("az_test_runs_list, az_test_run_metrics_get, and az_code_coverage_get retrieve quality metrics", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_runs_list_payload <- list(
    value = list(
      list(id = 900L, name = "Automated Unit Tests", state = "Completed", totalTests = 50L, passedTests = 48L, failedTests = 2L)
    )
  )
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
  
  with_mock_api(function(req) {
    if (grepl("codecoverage", req$url)) {
      mock_response(mock_coverage_payload)
    } else if (grepl("_apis/test/runs/900", req$url)) {
      mock_response(mock_run_payload)
    } else {
      mock_response(mock_runs_list_payload)
    }
  }, {
    runs <- az_test_runs_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/test/runs?api-version=7.0&%24top=50")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(runs), 1)
    expect_equal(runs$id, 900L)

    run_metrics <- az_test_run_metrics_get(900L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/test/runs/900?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_true(S7::S7_inherits(run_metrics, az_test_run))
    expect_equal(run_metrics@id, 900L)
    expect_equal(run_metrics@total_tests, 50L)
    expect_equal(run_metrics@pass_rate, 48 / 50)
    
    cov <- az_code_coverage_get(build_id = 1234L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/test/codecoverage?api-version=7.0&buildId=1234")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(cov), 2)
    expect_equal(cov$label, c("Lines", "Blocks"))
    expect_equal(cov$coverage_pct, c(0.9, 0.9))
  })
})
