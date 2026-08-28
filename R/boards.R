#' @include classes.R client.R generics.R
NULL

#' Helper to Parse Azure DevOps Work Item JSON into S7 az_work_item
#' @noRd
.parse_work_item <- function(item) {
  item_id <- purrr::pluck(item, "id")
  if (is.null(item_id) || is.na(item_id) || as.integer(item_id) <= 0L) {
    cli::cli_abort(c(
      "x" = "Unexpected API response: work item has no valid ID.",
      "i" = "The Azure DevOps API returned an unexpected response structure."
    ))
  }
  fields <- purrr::pluck(item, "fields", .default = list())
  
  az_work_item(
    id = as.integer(item_id),
    rev = as.integer(purrr::pluck(item, "rev", .default = 1L)),
    type = as.character(purrr::pluck(fields, "System.WorkItemType", .default = "")),
    title = as.character(purrr::pluck(fields, "System.Title", .default = "")),
    state = as.character(purrr::pluck(fields, "System.State", .default = "")),
    assigned_to = as.character(purrr::pluck(fields, "System.AssignedTo", "displayName", .default = "")),
    url = as.character(purrr::pluck(item, "url", .default = "")),
    web_url = as.character(purrr::pluck(item, "_links", "html", "href", .default = "")),
    fields = fields
  )
}

#' Get a Single Work Item
#'
#' Retrieves a single work item by ID from Azure Boards.
#'
#' @param id Integer ID of the work item.
#' @param expand Expand options (`"all"`, `"relations"`, `"fields"`, `"none"`).
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_work_item` object.
#' @export
#' @examples
#' \dontrun{
#' item <- az_work_item_get(1234)
#' az_status(item)
#' }
az_work_item_get <- function(id, expand = c("all", "relations", "fields", "none"), client = NULL) {
  expand <- rlang::arg_match(expand)
  endpoint <- sprintf("_apis/wit/workitems/%s", id)
  
  req <- az_request(endpoint, client = client, query = list(`$expand` = expand))
  res <- az_perform(req)
  
  .parse_work_item(res)
}

#' Get Multiple Work Items by ID
#'
#' @param ids Numeric vector of work item IDs.
#' @param expand Expand options (`"all"`, `"relations"`, `"fields"`, `"none"`).
#' @param as_data_frame Logical; whether to return as a `tibble` (default `FALSE` returns list of S7 objects).
#' @param client Optional `az_client` S7 object.
#' @return A list of S7 `az_work_item` objects or a `tibble`.
#' @export
az_work_items_get <- function(ids,
                              expand = c("all", "relations", "fields", "none"),
                              as_data_frame = FALSE,
                              client = NULL) {
  if (length(ids) == 0) {
    return(if (as_data_frame) tibble::tibble() else list())
  }
  
  expand <- rlang::arg_match(expand)
  endpoint <- "_apis/wit/workitems"
  
  req <- az_request(
    endpoint,
    client = client,
    query = list(ids = paste(ids, collapse = ","), `$expand` = expand)
  )
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  
  if (length(items) > 1) {
    cli::cli_progress_step("Parsing {length(items)} work item{?s}", spinner = TRUE)
  }
  
  parsed <- purrr::map(items, .parse_work_item)
  
  if (as_data_frame) {
    purrr::map_dfr(parsed, ~ S7::convert(.x, S7::class_data.frame))
  } else {
    parsed
  }
}

#' Create a Work Item
#'
#' @param type Work item type (e.g. `"Bug"`, `"Task"`, `"User Story"`, `"Epic"`).
#' @param title Title of the work item.
#' @param description Optional description or repro steps.
#' @param assigned_to Optional email or display name of the assignee.
#' @param fields Named list of additional fields (e.g. `list("Microsoft.VSTS.Common.Priority" = 1)`).
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return An S7 `az_work_item` object.
#' @export
az_work_item_create <- function(type,
                                title,
                                description = NULL,
                                assigned_to = NULL,
                                fields = list(),
                                project = NULL,
                                client = NULL) {
  # Build JSON Patch operations
  patch <- list(
    list(op = "add", path = "/fields/System.Title", value = title)
  )
  
  if (!is.null(description) && nzchar(description)) {
    patch <- c(patch, list(list(op = "add", path = "/fields/System.Description", value = description)))
  }
  
  if (!is.null(assigned_to) && nzchar(assigned_to)) {
    patch <- c(patch, list(list(op = "add", path = "/fields/System.AssignedTo", value = assigned_to)))
  }
  
  for (f in names(fields)) {
    patch <- c(patch, list(list(op = "add", path = paste0("/fields/", f), value = fields[[f]])))
  }
  
  endpoint <- sprintf("_apis/wit/workitems/$%s", utils::URLencode(type, reserved = TRUE))
  
  req <- az_request(endpoint, client = client, project = project) |>
    httr2::req_method("POST") |>
    httr2::req_headers(`Content-Type` = "application/json-patch+json") |>
    httr2::req_body_json(patch)
    
  res <- az_perform(req)
  .parse_work_item(res)
}

#' Update a Work Item
#'
#' @param id Integer ID of the work item to update.
#' @param fields Named list of fields to update (e.g. `list("System.State" = "Closed", "System.Title" = "New Title")`).
#' @param client Optional `az_client` S7 object.
#' @return Updated S7 `az_work_item` object.
#' @export
az_work_item_update <- function(id, fields = list(), client = NULL) {
  if (length(fields) == 0) {
    cli::cli_abort("No fields provided for update.")
  }
  
  patch <- purrr::imap(fields, function(val, name) {
    list(op = "add", path = paste0("/fields/", name), value = val)
  }) |> unname()
  
  endpoint <- sprintf("_apis/wit/workitems/%s", id)
  
  req <- az_request(endpoint, client = client) |>
    httr2::req_method("PATCH") |>
    httr2::req_headers(`Content-Type` = "application/json-patch+json") |>
    httr2::req_body_json(patch)
    
  res <- az_perform(req)
  .parse_work_item(res)
}

#' Query Work Items using WIQL (Work Item Query Language)
#'
#' Executes a WIQL query and optionally resolves full work item details.
#'
#' @param query Work Item Query Language (WIQL) string.
#' @param project Project scope (optional).
#' @param top Maximum number of results to return.
#' @param resolve Logical; whether to resolve and fetch full work item objects (default `TRUE`).
#' @param as_data_frame Logical; whether to return results as a `tibble`.
#' @param client Optional `az_client` S7 object.
#' @return A list of S7 `az_work_item` objects, a `tibble`, or raw query results.
#' @export
#' @examples
#' \dontrun{
#' az_wiql_query("SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Bug'")
#' }
az_wiql_query <- function(query,
                          project = NULL,
                          top = NULL,
                          resolve = TRUE,
                          as_data_frame = FALSE,
                          client = NULL) {
  query_params <- list()
  if (!is.null(top)) {
    query_params$`$top` <- top
  }
  
  req <- az_request("_apis/wit/wiql", client = client, project = project, query = query_params) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(list(query = query))
    
  res <- az_perform(req)
  
  work_items_ref <- purrr::pluck(res, "workItems", .default = list())
  ids <- purrr::map_int(work_items_ref, ~ as.integer(purrr::pluck(.x, "id", .default = 0L)))
  ids <- ids[ids > 0]
  
  if (!resolve || length(ids) == 0) {
    if (as_data_frame) {
      return(tibble::tibble(id = ids))
    }
    return(res)
  }
  
  az_work_items_get(ids, as_data_frame = as_data_frame, client = client)
}

#' List Iterations (Sprints) for a Team
#'
#' @param project Project name or ID.
#' @param team Team name or ID.
#' @param timeframe Optional filter (`"current"`, `"past"`, `"future"`).
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of iterations.
#' @export
az_iterations_list <- function(project = NULL, team = NULL, timeframe = NULL, client = NULL) {
  endpoint <- if (!is.null(team) && nzchar(team)) {
    sprintf("_apis/work/teamsettings/iterations")
  } else {
    "_apis/work/teamsettings/iterations"
  }
  
  query <- list()
  if (!is.null(timeframe) && nzchar(timeframe)) {
    query$`$timeframe` <- timeframe
  }
  
  req <- az_request(endpoint, client = client, project = project, query = query)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      name = character(),
      path = character(),
      start_date = character(),
      finish_date = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    path = purrr::map_chr(items, ~ purrr::pluck(.x, "path", .default = "")),
    start_date = purrr::map_chr(items, ~ purrr::pluck(.x, "attributes", "startDate", .default = "")),
    finish_date = purrr::map_chr(items, ~ purrr::pluck(.x, "attributes", "finishDate", .default = ""))
  )
}

#' Get Sprint Capacity
#'
#' Retrieves team and member capacity metrics for a given iteration/sprint.
#'
#' @param iteration_id UUID or ID of the iteration.
#' @param team Team name or ID.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of team member capacities.
#' @export
az_sprint_capacity_get <- function(iteration_id, team = NULL, project = NULL, client = NULL) {
  endpoint <- sprintf("_apis/work/teamsettings/iterations/%s/capacities", iteration_id)
  
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      display_name = character(),
      total_capacity = numeric()
    ))
  }
  
  tibble::tibble(
    display_name = purrr::map_chr(items, ~ purrr::pluck(.x, "teamMember", "displayName", .default = "")),
    total_capacity = purrr::map_dbl(items, function(x) {
      activities <- purrr::pluck(x, "activities", .default = list())
      if (length(activities) == 0) return(0)
      sum(purrr::map_dbl(activities, ~ purrr::pluck(.x, "capacityPerDay", .default = 0)))
    })
  )
}
