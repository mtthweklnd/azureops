#' @include classes.R client.R generics.R
NULL

#' Parse Test Plan JSON into S7 az_test_plan
#' @noRd
.parse_test_plan <- function(item, call = rlang::caller_env()) {
  plan_id <- purrr::pluck(item, "id")
  if (is.null(plan_id) || is.na(plan_id) || as.integer(plan_id) <= 0L) {
    cli::cli_abort(c(
      "x" = "Unexpected API response: test plan has no valid ID.",
      "i" = "The Azure DevOps API returned an unexpected response structure."
    ), call = call)
  }
  az_test_plan(
    id = as.integer(plan_id),
    name = as.character(purrr::pluck(item, "name", .default = "")),
    state = as.character(purrr::pluck(item, "state", .default = "Active")),
    area_path = as.character(purrr::pluck(item, "areaPath", .default = "")),
    iteration = as.character(purrr::pluck(item, "iteration", .default = "")),
    web_url = as.character(purrr::pluck(item, "_links", "html", "href", .default = ""))
  )
}

#' Parse Test Run JSON into S7 az_test_run
#' @noRd
.parse_test_run <- function(item, call = rlang::caller_env()) {
  run_id <- purrr::pluck(item, "id")
  if (is.null(run_id) || is.na(run_id) || as.integer(run_id) <= 0L) {
    cli::cli_abort(c(
      "x" = "Unexpected API response: test run has no valid ID.",
      "i" = "The Azure DevOps API returned an unexpected response structure."
    ), call = call)
  }
  total <- as.integer(purrr::pluck(item, "totalTests", .default = 0L))
  passed <- as.integer(purrr::pluck(item, "passedTests", .default = 0L))
  rate <- if (total > 0) passed / total else 0.0
  
  az_test_run(
    id = as.integer(run_id),
    name = as.character(purrr::pluck(item, "name", .default = "")),
    state = as.character(purrr::pluck(item, "state", .default = "")),
    total_tests = total,
    pass_rate = rate,
    web_url = as.character(purrr::pluck(item, "webAccessUrl", .default = ""))
  )
}

#' List Test Plans
#'
#' Retrieves manual and automated test plans in a project.
#'
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of test plans.
#' @export
#' @examples
#' \dontrun{
#' az_test_plans_list()
#' }
az_test_plans_list <- function(project = NULL, client = NULL) {
  req <- az_request("_apis/testplan/plans", client = client, project = project, api_version = "7.1-preview.1")
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      name = character(),
      state = character(),
      area_path = character(),
      iteration = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    state = purrr::map_chr(items, ~ purrr::pluck(.x, "state", .default = "")),
    area_path = purrr::map_chr(items, ~ purrr::pluck(.x, "areaPath", .default = "")),
    iteration = purrr::map_chr(items, ~ purrr::pluck(.x, "iteration", .default = ""))
  )
}

#' List Test Suites for a Test Plan
#'
#' @param plan_id Integer ID of the test plan.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of test suites.
#' @export
az_test_suites_list <- function(plan_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/testplan/Plans/%s/suites", plan_id)
  req <- az_request(endpoint, client = client, project = project, api_version = "7.1-preview.1")
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      name = character(),
      suite_type = character(),
      parent_suite_id = integer()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    suite_type = purrr::map_chr(items, ~ purrr::pluck(.x, "suiteType", .default = "")),
    parent_suite_id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "parentSuite", "id", .default = 0L)))
  )
}

#' List Test Cases in a Test Suite
#'
#' @param plan_id Integer ID of the test plan.
#' @param suite_id Integer ID of the test suite.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of test cases.
#' @export
az_test_cases_list <- function(plan_id, suite_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/testplan/Plans/%s/Suites/%s/TestCase", plan_id, suite_id)
  req <- az_request(endpoint, client = client, project = project, api_version = "7.1-preview.1")
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      title = character(),
      state = character(),
      priority = integer()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "workItem", "id", .default = 0L))),
    title = purrr::map_chr(items, ~ purrr::pluck(.x, "workItem", "name", .default = "")),
    state = purrr::map_chr(items, ~ purrr::pluck(.x, "workItem", "state", .default = "")),
    priority = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "priority", .default = 0L)))
  )
}

#' List Test Execution Runs
#'
#' @param top Number of runs to retrieve (default: 50).
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of test runs.
#' @export
az_test_runs_list <- function(top = 50, project = NULL, client = NULL) {
  req <- az_request("_apis/test/runs", client = client, project = project, query = list(`$top` = top))
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      name = character(),
      state = character(),
      total_tests = integer(),
      passed_tests = integer(),
      failed_tests = integer()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    state = purrr::map_chr(items, ~ purrr::pluck(.x, "state", .default = "")),
    total_tests = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "totalTests", .default = 0L))),
    passed_tests = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "passedTests", .default = 0L))),
    failed_tests = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "failedTests", .default = 0L)))
  )
}

#' Get Test Run Metrics & Summary
#'
#' @param run_id Integer ID of the test run.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_test_run` object.
#' @export
az_test_run_metrics_get <- function(run_id, project = NULL, client = NULL, call = rlang::caller_env()) {
  endpoint <- sprintf("_apis/test/runs/%s", run_id)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  .parse_test_run(res, call = call)
}

#' Get Code Coverage Summary for a Build
#'
#' Retrieves code coverage data for a specific build or pipeline execution.
#'
#' @param build_id Integer ID of the build run.
#' @param flags Optional flags for coverage (e.g. 1 for blocks, 2 for lines).
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of code coverage metrics across modules.
#' @export
#' @examples
#' \dontrun{
#' coverage <- az_code_coverage_get(1024)
#' }
az_code_coverage_get <- function(build_id, flags = NULL, project = NULL, client = NULL) {
  query <- list(buildId = build_id)
  if (!is.null(flags)) {
    query$flags <- flags
  }
  
  req <- az_request("_apis/test/codecoverage", client = client, project = project, query = query)
  res <- az_perform(req)
  
  modules <- purrr::pluck(res, "coverageData", 1, "coverageStats", .default = list())
  if (length(modules) == 0) {
    return(tibble::tibble(
      label = character(),
      covered = integer(),
      total = integer(),
      coverage_pct = double()
    ))
  }
  
  tibble::tibble(
    label = purrr::map_chr(modules, ~ purrr::pluck(.x, "label", .default = "")),
    covered = purrr::map_int(modules, ~ as.integer(purrr::pluck(.x, "covered", .default = 0L))),
    total = purrr::map_int(modules, ~ as.integer(purrr::pluck(.x, "total", .default = 0L))),
    coverage_pct = ifelse(
      purrr::map_int(modules, ~ as.integer(purrr::pluck(.x, "total", .default = 0L))) > 0,
      purrr::map_int(modules, ~ as.integer(purrr::pluck(.x, "covered", .default = 0L))) / 
        purrr::map_int(modules, ~ as.integer(purrr::pluck(.x, "total", .default = 0L))),
      0.0
    )
  )
}
