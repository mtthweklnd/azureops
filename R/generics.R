#' @include classes.R
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

# az_client
S7::method(format, az_client) <- function(x, ...) {
  masked_pat <- if (nzchar(x@pat)) {
    paste0(substr(x@pat, 1, min(3, nchar(x@pat))), paste0(rep("*", max(4, nchar(x@pat) - 3)), collapse = ""))
  } else {
    "<none>"
  }
  cli::cli_format_method({
    cli::cli_h3("<Azure DevOps Client [S7]>")
    cli::cli_dl(c(
      "Organization" = x@organization,
      "Project"      = if (nzchar(x@project)) x@project else "<none>",
      "Base URL"     = x@base_url,
      "API Version"  = x@api_version,
      "PAT"          = masked_pat
    ))
  })
}

S7::method(print, az_client) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_work_item
S7::method(format, az_work_item) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Work Item #%d [%s]>", x@id, x@type))
    cli::cli_dl(c(
      "Title"       = x@title,
      "State"       = x@state,
      "Assigned To" = if (nzchar(x@assigned_to)) x@assigned_to else "<unassigned>",
      "Revision"    = as.character(x@rev),
      "Web URL"     = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_work_item) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_repo
S7::method(format, az_repo) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Repository [%s]>", x@name))
    cli::cli_dl(c(
      "ID"             = x@id,
      "Default Branch" = x@default_branch,
      "Project"        = if (nzchar(x@project)) x@project else "<none>",
      "Web URL"        = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_repo) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_pull_request
S7::method(format, az_pull_request) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Pull Request #%d>", x@id))
    cli::cli_dl(c(
      "Title"         = x@title,
      "Status"        = x@status,
      "Source Branch" = x@source_branch,
      "Target Branch" = x@target_branch,
      "Created By"    = if (nzchar(x@created_by)) x@created_by else "<unknown>",
      "Repository"    = if (nzchar(x@repository)) x@repository else "<none>",
      "Web URL"       = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_pull_request) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_pipeline
S7::method(format, az_pipeline) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Pipeline #%d [%s]>", x@id, x@name))
    cli::cli_dl(c(
      "Folder"   = x@folder,
      "Revision" = as.character(x@revision),
      "Web URL"  = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_pipeline) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_pipeline_run
S7::method(format, az_pipeline_run) <- function(x, ...) {
  res <- if (nzchar(x@result)) paste0(" (", x@result, ")") else ""
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Pipeline Run #%d>", x@id))
    cli::cli_dl(c(
      "Pipeline ID"  = as.character(x@pipeline_id),
      "Name"         = x@name,
      "Status"       = paste0(x@status, res),
      "Created Date" = if (nzchar(x@created_date)) x@created_date else "<unknown>",
      "Web URL"      = if (nzchar(x@web_url)) x@web_url else "<none>",
      "Logs URL"     = if (nzchar(x@logs_url)) x@logs_url else "<none>"
    ))
  })
}

S7::method(print, az_pipeline_run) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_test_plan
S7::method(format, az_test_plan) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Test Plan #%d [%s]>", x@id, x@name))
    cli::cli_dl(c(
      "State"     = x@state,
      "Area Path" = if (nzchar(x@area_path)) x@area_path else "<none>",
      "Iteration" = if (nzchar(x@iteration)) x@iteration else "<none>",
      "Web URL"   = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_test_plan) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

# az_test_run
S7::method(format, az_test_run) <- function(x, ...) {
  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Test Run #%d [%s]>", x@id, x@name))
    cli::cli_dl(c(
      "State"       = x@state,
      "Total Tests" = as.character(x@total_tests),
      "Pass Rate"   = sprintf("%.1f%%", x@pass_rate * 100),
      "Web URL"     = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_test_run) <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}


# -------------------------------------------------------------------------
# S7 Methods for az_status
# -------------------------------------------------------------------------

S7::method(az_status, az_pipeline_run) <- function(x, ...) {
  res <- if (nzchar(x@result)) paste0(" (", x@result, ")") else ""
  bullet <- if (identical(x@result, "succeeded") || identical(x@status, "completed")) "v" else if (identical(x@result, "failed")) "x" else "i"
  msg <- setNames("Pipeline Run #{x@id} ({x@name}): {.strong {x@status}}{res}", bullet)
  cli::cli_inform(msg)
  x@status
}

S7::method(az_status, az_pull_request) <- function(x, ...) {
  bullet <- if (identical(x@status, "completed")) "v" else if (identical(x@status, "abandoned")) "x" else "i"
  msg <- setNames("Pull Request #{x@id} \"{x@title}\": {.strong {x@status}}", bullet)
  cli::cli_inform(msg)
  x@status
}

S7::method(az_status, az_work_item) <- function(x, ...) {
  bullet <- if (tolower(x@state) %in% c("closed", "done", "resolved")) "v" else "i"
  msg <- setNames("Work Item #{x@id} [{x@type}] \"{x@title}\": {.strong {x@state}}", bullet)
  cli::cli_inform(msg)
  x@state
}

S7::method(az_status, az_test_run) <- function(x, ...) {
  bullet <- if (tolower(x@state) == "completed" && x@pass_rate >= 0.9) "v" else if (x@pass_rate < 0.5) "x" else "i"
  msg <- setNames("Test Run #{x@id} ({x@name}): {.strong {x@state}} - Pass Rate: {round(x@pass_rate * 100, 1)}%", bullet)
  cli::cli_inform(msg)
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
