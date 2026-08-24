#' @include classes.R
#' @import S7
#' @importFrom S7 convert class_data.frame method method<-
#' @importFrom utils browseURL
NULL

# -------------------------------------------------------------------------
# S7 Generics
# -------------------------------------------------------------------------

#' Get Status of an Azure DevOps Resource
#'
#' Polymorphic generic to inspect the status of Azure DevOps resources
#' such as pipeline runs, pull requests, work items, and test runs.
#'
#' @param x An Azure DevOps S7 object (`az_pipeline_run`, `az_pull_request`, `az_work_item`, `az_test_run`).
#' @param ... Additional arguments passed to methods.
#' @return A character vector describing the status.
#' @export
az_status <- S7::new_generic("az_status", "x")

#' Browse an Azure DevOps Resource in Web UI
#'
#' Opens the corresponding Azure DevOps web page in the default web browser.
#'
#' @param x An Azure DevOps S7 object with a web URL.
#' @param browser Logical; whether to open in browser (defaults to `interactive()`).
#' @param ... Additional arguments passed to methods.
#' @return The URL string (invisibly if browser is opened).
#' @export
az_browse <- S7::new_generic("az_browse", "x", function(x, browser = interactive(), ...) S7::S7_dispatch())

#' Fetch Logs for an Azure DevOps Resource
#'
#' Retrieves execution logs for pipeline runs or test runs.
#'
#' @param x An Azure DevOps S7 object (`az_pipeline_run` or `az_test_run`).
#' @param client An `az_client` object (optional).
#' @param ... Additional arguments passed to methods.
#' @return A character vector or list of log contents.
#' @export
az_logs <- S7::new_generic("az_logs", "x", function(x, client = NULL, ...) S7::S7_dispatch())

#' Cancel an Azure DevOps Resource Operation
#'
#' Cancels an in-progress pipeline run or closes/abandons a pull request.
#'
#' @param x An Azure DevOps S7 object.
#' @param client An `az_client` object.
#' @param ... Additional arguments passed to methods.
#' @return Updated S7 object.
#' @export
az_cancel <- S7::new_generic("az_cancel", "x", function(x, client = NULL, ...) S7::S7_dispatch())


# -------------------------------------------------------------------------
# S7 Methods for base generics (format / print)
# -------------------------------------------------------------------------

S7::method(format, az_client) <- function(x, ...) {
  masked_pat <- if (nzchar(x@pat)) {
    paste0(substr(x@pat, 1, min(3, nchar(x@pat))), paste0(rep("*", max(4, nchar(x@pat) - 3)), collapse = ""))
  } else {
    "<none>"
  }
  c(
    "<Azure DevOps Client [S7]>",
    paste0("  Organization: ", x@organization),
    paste0("  Project:      ", if (nzchar(x@project)) x@project else "<none>"),
    paste0("  Base URL:     ", x@base_url),
    paste0("  API Version:  ", x@api_version),
    paste0("  PAT:          ", masked_pat)
  )
}

S7::method(print, az_client) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}


# -------------------------------------------------------------------------
# S7 Methods for az_status
# -------------------------------------------------------------------------

S7::method(az_status, az_pipeline_run) <- function(x, ...) {
  res <- if (nzchar(x@result)) paste0(" (", x@result, ")") else ""
  cli::cli_inform(c("i" = "Pipeline Run #{x@id} ({x@name}): {.strong {x@status}}{res}"))
  x@status
}

S7::method(az_status, az_pull_request) <- function(x, ...) {
  cli::cli_inform(c("i" = "Pull Request #{x@id} \"{x@title}\": {.strong {x@status}}"))
  x@status
}

S7::method(az_status, az_work_item) <- function(x, ...) {
  cli::cli_inform(c("i" = "Work Item #{x@id} [{x@type}] \"{x@title}\": {.strong {x@state}}"))
  x@state
}

S7::method(az_status, az_test_run) <- function(x, ...) {
  cli::cli_inform(c("i" = "Test Run #{x@id} ({x@name}): {.strong {x@state}} - Pass Rate: {round(x@pass_rate * 100, 1)}%"))
  x@state
}


# -------------------------------------------------------------------------
# S7 Methods for az_browse
# -------------------------------------------------------------------------

.browse_helper <- function(url, browser = interactive()) {
  if (!nzchar(url)) {
    cli::cli_abort("No web URL available for this resource.")
  }
  if (browser) {
    utils::browseURL(url)
    invisible(url)
  } else {
    url
  }
}

S7::method(az_browse, az_work_item) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_repo) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_pull_request) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_pipeline) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_pipeline_run) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_test_plan) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}

S7::method(az_browse, az_test_run) <- function(x, browser = interactive(), ...) {
  .browse_helper(x@web_url, browser)
}


# -------------------------------------------------------------------------
# S7 Coercion Methods to data.frame / tibble
# -------------------------------------------------------------------------

S7::method(convert, list(az_work_item, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    rev = from@rev,
    type = from@type,
    title = from@title,
    state = from@state,
    assigned_to = from@assigned_to,
    url = from@url,
    web_url = from@web_url
  )
}

S7::method(convert, list(az_repo, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    default_branch = from@default_branch,
    web_url = from@web_url,
    project = from@project
  )
}

S7::method(convert, list(az_pull_request, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    title = from@title,
    status = from@status,
    source_branch = from@source_branch,
    target_branch = from@target_branch,
    created_by = from@created_by,
    web_url = from@web_url,
    repository = from@repository
  )
}

S7::method(convert, list(az_pipeline, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    folder = from@folder,
    revision = from@revision,
    web_url = from@web_url
  )
}

S7::method(convert, list(az_pipeline_run, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    pipeline_id = from@pipeline_id,
    name = from@name,
    status = from@status,
    result = from@result,
    created_date = from@created_date,
    web_url = from@web_url,
    logs_url = from@logs_url
  )
}

S7::method(convert, list(az_test_plan, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    state = from@state,
    area_path = from@area_path,
    iteration = from@iteration,
    web_url = from@web_url
  )
}

S7::method(convert, list(az_test_run, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    state = from@state,
    total_tests = from@total_tests,
    pass_rate = from@pass_rate,
    web_url = from@web_url
  )
}
