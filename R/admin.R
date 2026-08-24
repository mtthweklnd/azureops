#' @include classes.R client.R generics.R
#' @importFrom purrr pluck map_chr
#' @importFrom rlang arg_match
#' @importFrom tibble tibble
#' @importFrom httr2 req_method req_body_json
NULL

#' List Azure DevOps Projects
#'
#' Retrieves all projects accessible to the authenticated user in the organization.
#'
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of project summaries.
#' @export
#' @examples
#' \dontrun{
#' az_projects_list()
#' }
az_projects_list <- function(client = NULL) {
  req <- az_request("_apis/projects", client = client)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      name = character(),
      description = character(),
      state = character(),
      visibility = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    description = purrr::map_chr(items, ~ purrr::pluck(.x, "description", .default = "")),
    state = purrr::map_chr(items, ~ purrr::pluck(.x, "state", .default = "")),
    visibility = purrr::map_chr(items, ~ purrr::pluck(.x, "visibility", .default = ""))
  )
}

#' Get an Azure DevOps Project
#'
#' Retrieves detailed information about a specific project.
#'
#' @param project_id Project ID or project name.
#' @param client Optional `az_client` S7 object.
#' @return A list representing the project details.
#' @export
az_project_get <- function(project_id, client = NULL) {
  endpoint <- sprintf("_apis/projects/%s", project_id)
  req <- az_request(endpoint, client = client)
  az_perform(req)
}

#' Create an Azure DevOps Project
#'
#' Triggers the asynchronous creation of a new project.
#'
#' @param name Name of the project.
#' @param description Description of the project.
#' @param visibility Visibility of the project (`"private"` or `"public"`).
#' @param capabilities Optional capabilities list (e.g. version control, process template).
#' @param client Optional `az_client` S7 object.
#' @return A list with operation status details.
#' @export
az_project_create <- function(name,
                              description = "",
                              visibility = c("private", "public"),
                              capabilities = NULL,
                              client = NULL) {
  visibility <- rlang::arg_match(visibility)
  
  body <- list(
    name = name,
    description = description,
    visibility = visibility
  )
  
  if (!is.null(capabilities)) {
    body$capabilities <- capabilities
  } else {
    body$capabilities <- list(
      versioncontrol = list(sourceControlType = "Git"),
      processTemplate = list(templateTypeId = "6b724908-ef14-45cf-84f8-768b5384da45") # Agile default
    )
  }
  
  req <- az_request("_apis/projects", client = client) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body)
    
  az_perform(req)
}

#' List Teams in a Project or Organization
#'
#' @param project Project name or ID (optional).
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of teams.
#' @export
az_teams_list <- function(project = NULL, client = NULL) {
  endpoint <- if (!is.null(project) && nzchar(project)) {
    sprintf("_apis/projects/%s/teams", project)
  } else {
    "_apis/teams"
  }
  
  req <- az_request(endpoint, client = client)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      name = character(),
      description = character(),
      identity_url = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    description = purrr::map_chr(items, ~ purrr::pluck(.x, "description", .default = "")),
    identity_url = purrr::map_chr(items, ~ purrr::pluck(.x, "identityUrl", .default = ""))
  )
}

#' List Team Members
#'
#' @param project Project name or ID.
#' @param team_id Team name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of team members.
#' @export
az_team_members_list <- function(project, team_id, client = NULL) {
  endpoint <- sprintf("_apis/projects/%s/teams/%s/members", project, team_id)
  req <- az_request(endpoint, client = client)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      display_name = character(),
      unique_name = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "identity", "id", .default = "")),
    display_name = purrr::map_chr(items, ~ purrr::pluck(.x, "identity", "displayName", .default = "")),
    unique_name = purrr::map_chr(items, ~ purrr::pluck(.x, "identity", "uniqueName", .default = ""))
  )
}

#' List Security Groups
#'
#' Retrieves security groups in the organization or project via the VSSPS Graph API.
#'
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of security groups.
#' @export
az_security_groups_list <- function(client = NULL) {
  req <- az_request(
    "_apis/graph/groups",
    client = client,
    base_url = "https://vssps.dev.azure.com",
    api_version = "7.1-preview.1"
  )
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      principal_name = character(),
      display_name = character(),
      description = character(),
      descriptor = character()
    ))
  }
  
  tibble::tibble(
    principal_name = purrr::map_chr(items, ~ purrr::pluck(.x, "principalName", .default = "")),
    display_name = purrr::map_chr(items, ~ purrr::pluck(.x, "displayName", .default = "")),
    description = purrr::map_chr(items, ~ purrr::pluck(.x, "description", .default = "")),
    descriptor = purrr::map_chr(items, ~ purrr::pluck(.x, "descriptor", .default = ""))
  )
}

#' List User Entitlements
#'
#' Retrieves user entitlements and license assignments across the organization.
#'
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of user entitlements.
#' @export
az_user_entitlements_list <- function(client = NULL) {
  req <- az_request(
    "_apis/userentitlements",
    client = client,
    base_url = "https://vsaex.dev.azure.com",
    api_version = "7.1-preview.3"
  )
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "items", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      display_name = character(),
      email = character(),
      account_license_type = character(),
      access_level = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    display_name = purrr::map_chr(items, ~ purrr::pluck(.x, "user", "displayName", .default = "")),
    email = purrr::map_chr(items, ~ purrr::pluck(.x, "user", "mailAddress", .default = "")),
    account_license_type = purrr::map_chr(items, ~ purrr::pluck(.x, "accessLevel", "accountLicenseType", .default = "")),
    access_level = purrr::map_chr(items, ~ purrr::pluck(.x, "accessLevel", "licenseDisplayName", .default = ""))
  )
}

#' List Webhook Subscriptions (Service Hooks)
#'
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of webhook subscriptions.
#' @export
az_webhooks_list <- function(client = NULL) {
  req <- az_request("_apis/hooks/subscriptions", client = client)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      event_type = character(),
      consumer_id = character(),
      status = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    event_type = purrr::map_chr(items, ~ purrr::pluck(.x, "eventType", .default = "")),
    consumer_id = purrr::map_chr(items, ~ purrr::pluck(.x, "consumerId", .default = "")),
    status = purrr::map_chr(items, ~ purrr::pluck(.x, "status", .default = ""))
  )
}

#' Create a Webhook Subscription (Service Hook)
#'
#' @param publisher_id Publisher identifier (e.g. `"tfs"`).
#' @param event_type Event type (e.g. `"workitem.created"`, `"git.pullrequest.created"`).
#' @param consumer_id Consumer identifier (e.g. `"webHooks"`).
#' @param consumer_action_id Consumer action (e.g. `"httpRequest"`).
#' @param consumer_inputs Named list of inputs (e.g. `list(url = "https://example.com/webhook")`).
#' @param publisher_inputs Named list of publisher filters (e.g. `list(projectId = "...")`).
#' @param client Optional `az_client` S7 object.
#' @return A list containing the created subscription details.
#' @export
az_webhook_create <- function(publisher_id = "tfs",
                              event_type,
                              consumer_id = "webHooks",
                              consumer_action_id = "httpRequest",
                              consumer_inputs = list(),
                              publisher_inputs = list(),
                              client = NULL) {
  body <- list(
    publisherId = publisher_id,
    eventType = event_type,
    consumerId = consumer_id,
    consumerActionId = consumer_action_id,
    consumerInputs = consumer_inputs,
    publisherInputs = publisher_inputs
  )
  
  req <- az_request("_apis/hooks/subscriptions", client = client) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body)
    
  az_perform(req)
}
