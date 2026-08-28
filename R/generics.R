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
#' @param call Caller environment for error attribution.
#' @return The URL string (invisibly if browser is opened).
#' @export
az_browse <- S7::new_generic("az_browse", "x", function(x, browser = interactive(), ..., call = rlang::caller_env()) S7::S7_dispatch())

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
# Internal Method Helpers
# -------------------------------------------------------------------------

.print_s7 <- function(x, ...) {
  cli::cat_line(format(x, ...))
  invisible(x)
}

.format_cli_dl <- function(header_str, dl_list) {
  cli::cli_format_method({
    cli::cli_h3(header_str)
    cli::cli_dl(dl_list)
  })
}

.status_bullet <- function(status,
                           pass_rate = NULL,
                           success = c("completed", "succeeded", "closed", "done", "resolved"),
                           failure = c("failed", "abandoned")) {
  if (!is.null(pass_rate)) {
    if (pass_rate < 0.5) return("x")
    if (tolower(status) %in% success && pass_rate >= 0.9) return("v")
    return("i")
  }
  status_clean <- tolower(trimws(as.character(status)))
  if (status_clean %in% success) {
    "v"
  } else if (status_clean %in% failure) {
    "x"
  } else {
    "i"
  }
}


# -------------------------------------------------------------------------
# S7 Methods for base generics (format / print)
# -------------------------------------------------------------------------

# az_client
#' @keywords internal
#' @export
S7::method(format, az_client) <- function(x, ...) {
  masked_pat <- if (nzchar(x@pat)) {
    paste0(substr(x@pat, 1, min(3, nchar(x@pat))), paste0(rep("*", max(4, nchar(x@pat) - 3)), collapse = ""))
  } else {
    "<none>"
  }
  .format_cli_dl(
    "<Azure DevOps Client [S7]>",
    c(
      "Organization" = x@organization,
      "Project"      = if (nzchar(x@project)) x@project else "<none>",
      "Base URL"     = x@base_url,
      "API Version"  = x@api_version,
      "PAT"          = masked_pat
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_client) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_work_item
#' @keywords internal
#' @export
S7::method(format, az_work_item) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Work Item #%d [%s]>", x@id, x@type),
    c(
      "Title"       = x@title,
      "State"       = x@state,
      "Assigned To" = if (nzchar(x@assigned_to)) x@assigned_to else "<unassigned>",
      "Revision"    = as.character(x@rev),
      "Web URL"     = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_work_item) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_repo
#' @keywords internal
#' @export
S7::method(format, az_repo) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Repository [%s]>", x@name),
    c(
      "ID"             = x@id,
      "Default Branch" = x@default_branch,
      "Project"        = if (nzchar(x@project)) x@project else "<none>",
      "Web URL"        = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_repo) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_pull_request
#' @keywords internal
#' @export
S7::method(format, az_pull_request) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Pull Request #%d>", x@id),
    c(
      "Title"         = x@title,
      "Status"        = x@status,
      "Source Branch" = x@source_branch,
      "Target Branch" = x@target_branch,
      "Created By"    = if (nzchar(x@created_by)) x@created_by else "<unknown>",
      "Repository"    = if (nzchar(x@repository)) x@repository else "<none>",
      "Web URL"       = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_pull_request) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_pipeline
#' @keywords internal
#' @export
S7::method(format, az_pipeline) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Pipeline #%d [%s]>", x@id, x@name),
    c(
      "Folder"   = x@folder,
      "Revision" = as.character(x@revision),
      "Web URL"  = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_pipeline) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_pipeline_run
#' @keywords internal
#' @export
S7::method(format, az_pipeline_run) <- function(x, ...) {
  res <- if (nzchar(x@result)) paste0(" (", x@result, ")") else ""
  .format_cli_dl(
    sprintf("<Azure DevOps Pipeline Run #%d>", x@id),
    c(
      "Pipeline ID"  = as.character(x@pipeline_id),
      "Name"         = x@name,
      "Status"       = paste0(x@status, res),
      "Created Date" = if (nzchar(x@created_date)) x@created_date else "<unknown>",
      "Web URL"      = if (nzchar(x@web_url)) x@web_url else "<none>",
      "Logs URL"     = if (nzchar(x@logs_url)) x@logs_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_pipeline_run) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_test_plan
#' @keywords internal
#' @export
S7::method(format, az_test_plan) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Test Plan #%d [%s]>", x@id, x@name),
    c(
      "State"     = x@state,
      "Area Path" = if (nzchar(x@area_path)) x@area_path else "<none>",
      "Iteration" = if (nzchar(x@iteration)) x@iteration else "<none>",
      "Web URL"   = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_test_plan) <- function(x, ...) {
  .print_s7(x, ...)
}

# az_test_run
#' @keywords internal
#' @export
S7::method(format, az_test_run) <- function(x, ...) {
  .format_cli_dl(
    sprintf("<Azure DevOps Test Run #%d [%s]>", x@id, x@name),
    c(
      "State"       = x@state,
      "Total Tests" = as.character(x@total_tests),
      "Pass Rate"   = sprintf("%.1f%%", x@pass_rate * 100),
      "Web URL"     = if (nzchar(x@web_url)) x@web_url else "<none>"
    )
  )
}

#' @keywords internal
#' @export
S7::method(print, az_test_run) <- function(x, ...) {
  .print_s7(x, ...)
}


# -------------------------------------------------------------------------
# S7 Methods for az_status
# -------------------------------------------------------------------------

#' @rdname az_status
#' @export
S7::method(az_status, az_pipeline_run) <- function(x, ...) {
  res <- if (nzchar(x@result)) paste0(" (", x@result, ")") else ""
  target_status <- if (nzchar(x@result)) x@result else x@status
  bullet <- .status_bullet(target_status)
  msg <- setNames("Pipeline Run #{x@id} ({x@name}): {.strong {x@status}}{res}", bullet)
  cli::cli_inform(msg)
  x@status
}

#' @rdname az_status
#' @export
S7::method(az_status, az_pull_request) <- function(x, ...) {
  bullet <- .status_bullet(x@status)
  msg <- setNames("Pull Request #{x@id} \"{x@title}\": {.strong {x@status}}", bullet)
  cli::cli_inform(msg)
  x@status
}

#' @rdname az_status
#' @export
S7::method(az_status, az_work_item) <- function(x, ...) {
  bullet <- .status_bullet(x@state)
  msg <- setNames("Work Item #{x@id} [{x@type}] \"{x@title}\": {.strong {x@state}}", bullet)
  cli::cli_inform(msg)
  x@state
}

#' @rdname az_status
#' @export
S7::method(az_status, az_test_run) <- function(x, ...) {
  bullet <- .status_bullet(x@state, pass_rate = x@pass_rate)
  msg <- setNames("Test Run #{x@id} ({x@name}): {.strong {x@state}} - Pass Rate: {round(x@pass_rate * 100, 1)}%", bullet)
  cli::cli_inform(msg)
  x@state
}


# -------------------------------------------------------------------------
# S7 Methods for az_browse
# -------------------------------------------------------------------------

.browse_helper <- function(url, browser = interactive(), call = rlang::caller_env()) {
  if (!nzchar(url)) {
    cli::cli_abort("No web URL available for this resource.", call = call)
  }
  if (browser) {
    utils::browseURL(url)
    invisible(url)
  } else {
    url
  }
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_work_item) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_repo) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_pull_request) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_pipeline) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_pipeline_run) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_test_plan) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}

#' @rdname az_browse
#' @export
S7::method(az_browse, az_test_run) <- function(x, browser = interactive(), ..., call = rlang::caller_env()) {
  .browse_helper(x@web_url, browser, call = call)
}


# -------------------------------------------------------------------------
# S7 Coercion Methods to data.frame / tibble
# -------------------------------------------------------------------------

#' @keywords internal
#' @export
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

#' @keywords internal
#' @export
S7::method(convert, list(az_repo, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    default_branch = from@default_branch,
    web_url = from@web_url,
    project = from@project
  )
}

#' @keywords internal
#' @export
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

#' @keywords internal
#' @export
S7::method(convert, list(az_pipeline, class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id = from@id,
    name = from@name,
    folder = from@folder,
    revision = from@revision,
    web_url = from@web_url
  )
}

#' @keywords internal
#' @export
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

#' @keywords internal
#' @export
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

#' @keywords internal
#' @export
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
