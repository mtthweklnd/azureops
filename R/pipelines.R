#' @include classes.R client.R generics.R
#' @importFrom purrr pluck map_int map_chr imap
#' @importFrom tibble tibble
#' @importFrom cli cli_abort cli_inform
#' @importFrom httr2 req_method req_body_json req_perform resp_body_string
#' @importFrom S7 method method<-
NULL

#' Parse Pipeline JSON into S7 az_pipeline
#' @noRd
.parse_pipeline <- function(item) {
  az_pipeline(
    id = as.integer(purrr::pluck(item, "id", .default = 0L)),
    name = as.character(purrr::pluck(item, "name", .default = "")),
    folder = as.character(purrr::pluck(item, "folder", .default = "\\")),
    revision = as.integer(purrr::pluck(item, "revision", .default = 1L)),
    web_url = as.character(purrr::pluck(item, "_links", "web", "href", .default = ""))
  )
}

#' Parse Pipeline Run JSON into S7 az_pipeline_run
#' @noRd
.parse_pipeline_run <- function(item) {
  az_pipeline_run(
    id = as.integer(purrr::pluck(item, "id", .default = 0L)),
    pipeline_id = as.integer(purrr::pluck(item, "pipeline", "id", .default = 0L)),
    name = as.character(purrr::pluck(item, "name", .default = "")),
    status = as.character(purrr::pluck(item, "state", .default = purrr::pluck(item, "status", .default = "inProgress"))),
    result = as.character(purrr::pluck(item, "result", .default = "")),
    created_date = as.character(purrr::pluck(item, "createdDate", .default = "")),
    web_url = as.character(purrr::pluck(item, "_links", "web", "href", .default = "")),
    logs_url = as.character(purrr::pluck(item, "_links", "logs", "href", .default = ""))
  )
}

#' List Azure Pipelines
#'
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of pipelines.
#' @export
#' @examples
#' \dontrun{
#' az_pipelines_list()
#' }
az_pipelines_list <- function(project = NULL, client = NULL) {
  req <- az_request("_apis/pipelines", client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      name = character(),
      folder = character(),
      revision = integer(),
      web_url = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    folder = purrr::map_chr(items, ~ purrr::pluck(.x, "folder", .default = "\\")),
    revision = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "revision", .default = 1L))),
    web_url = purrr::map_chr(items, ~ purrr::pluck(.x, "_links", "web", "href", .default = ""))
  )
}

#' Get a Single Pipeline Definition
#'
#' @param pipeline_id Integer ID of the pipeline.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_pipeline` object.
#' @export
az_pipeline_get <- function(pipeline_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/pipelines/%s", pipeline_id)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  .parse_pipeline(res)
}

#' List Pipeline Runs
#'
#' @param pipeline_id Optional integer ID of the pipeline.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of pipeline runs.
#' @export
az_pipeline_runs_list <- function(pipeline_id = NULL, project = NULL, client = NULL) {
  endpoint <- if (!is.null(pipeline_id)) {
    sprintf("_apis/pipelines/%s/runs", pipeline_id)
  } else {
    "_apis/pipelines/runs"
  }
  
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      name = character(),
      status = character(),
      result = character(),
      created_date = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    status = purrr::map_chr(items, ~ purrr::pluck(.x, "state", .default = purrr::pluck(.x, "status", .default = ""))),
    result = purrr::map_chr(items, ~ purrr::pluck(.x, "result", .default = "")),
    created_date = purrr::map_chr(items, ~ purrr::pluck(.x, "createdDate", .default = ""))
  )
}

#' Get a Single Pipeline Run
#'
#' @param pipeline_id Integer ID of the pipeline.
#' @param run_id Integer ID of the run.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_pipeline_run` object.
#' @export
az_pipeline_run_get <- function(pipeline_id, run_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/pipelines/%s/runs/%s", pipeline_id, run_id)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  .parse_pipeline_run(res)
}

#' Trigger an Automated Pipeline Run
#'
#' Triggers an execution of a pipeline with specific repository branches,
#' runtime parameters, and variables.
#'
#' @param pipeline_id Integer ID of the pipeline to run.
#' @param branch Git branch to execute against (default: `"main"`).
#' @param template_parameters Optional named list of template parameters.
#' @param variables Optional named list of runtime variables.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_pipeline_run` object.
#' @export
#' @examples
#' \dontrun{
#' run <- az_pipeline_run_trigger(
#'   pipeline_id = 42,
#'   branch = "feature/my-branch",
#'   template_parameters = list(deployEnvironment = "staging")
#' )
#' az_status(run)
#' }
az_pipeline_run_trigger <- function(pipeline_id,
                                    branch = "main",
                                    template_parameters = list(),
                                    variables = list(),
                                    project = NULL,
                                    client = NULL) {
  branch_ref <- if (!grepl("^refs/heads/", branch)) paste0("refs/heads/", branch) else branch
  
  body <- list(
    resources = list(
      repositories = list(
        self = list(
          refName = branch_ref
        )
      )
    )
  )
  
  if (length(template_parameters) > 0) {
    body$templateParameters <- template_parameters
  }
  
  if (length(variables) > 0) {
    body$variables <- purrr::imap(variables, function(val, name) {
      if (is.list(val) && !is.null(val$value)) val else list(value = as.character(val))
    })
  }
  
  endpoint <- sprintf("_apis/pipelines/%s/runs", pipeline_id)
  
  req <- az_request(endpoint, client = client, project = project) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body)
    
  res <- az_perform(req)
  .parse_pipeline_run(res)
}

#' List Execution Logs for a Pipeline Run
#'
#' @param pipeline_id Integer ID of the pipeline.
#' @param run_id Integer ID of the run.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of log entries.
#' @export
az_pipeline_run_logs_list <- function(pipeline_id, run_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/pipelines/%s/runs/%s/logs", pipeline_id, run_id)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "logs", .default = purrr::pluck(res, "value", .default = list()))
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      line_count = integer(),
      created_on = character(),
      url = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "id", .default = 0L))),
    line_count = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "lineCount", .default = 0L))),
    created_on = purrr::map_chr(items, ~ purrr::pluck(.x, "createdOn", .default = "")),
    url = purrr::map_chr(items, ~ purrr::pluck(.x, "url", .default = ""))
  )
}

#' Get Log Content by Log ID
#'
#' @param pipeline_id Integer ID of the pipeline.
#' @param run_id Integer ID of the run.
#' @param log_id Integer ID of the log chunk.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A character vector of log lines.
#' @export
az_pipeline_run_log_get <- function(pipeline_id, run_id, log_id, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/pipelines/%s/runs/%s/logs/%s", pipeline_id, run_id, log_id)
  req <- az_request(endpoint, client = client, project = project)
  resp <- httr2::req_perform(req)
  httr2::resp_body_string(resp)
}

# S7 method registration for az_logs on az_pipeline_run
S7::method(az_logs, az_pipeline_run) <- function(x, client = NULL, ...) {
  if (x@pipeline_id == 0L) {
    cli::cli_abort("Pipeline ID is not available on this run object.")
  }
  logs <- az_pipeline_run_logs_list(pipeline_id = x@pipeline_id, run_id = x@id, client = client)
  if (nrow(logs) == 0) {
    cli::cli_inform("No logs found for this run.")
    return(character())
  }
  az_pipeline_run_log_get(pipeline_id = x@pipeline_id, run_id = x@id, log_id = max(logs$id), client = client)
}
