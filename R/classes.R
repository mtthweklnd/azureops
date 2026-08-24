#' @include auth.R
#' @import S7
NULL

#' Azure DevOps Client Class
#'
#' An S7 class representing connection and authentication configuration
#' for the Azure DevOps REST API.
#'
#' @param organization Azure DevOps organization name.
#' @param pat Personal Access Token (PAT).
#' @param project Default project name (optional).
#' @param base_url Base URL for REST API (default: `"https://dev.azure.com"`).
#' @param api_version Default API version (default: `"7.0"`).
#' @return An S7 `az_client` object.
#' @export
#' @examples
#' \dontrun{
#' client <- az_client("myorg", "secret_pat")
#' }
az_client <- S7::new_class(
  name = "az_client",
  package = "azureops",
  properties = list(
    organization = S7::class_character,
    pat = S7::class_character,
    project = S7::new_property(S7::class_character, default = ""),
    base_url = S7::new_property(S7::class_character, default = "https://dev.azure.com"),
    api_version = S7::new_property(S7::class_character, default = "7.0")
  ),
  constructor = function(organization = NULL,
                         pat = NULL,
                         project = NULL,
                         base_url = "https://dev.azure.com",
                         api_version = "7.0") {
    org <- az_org(organization)
    token <- az_pat(pat)
    proj <- az_project(project)
    
    S7::new_object(
      S7::S7_object(),
      organization = org,
      pat = token,
      project = if (is.null(proj)) "" else proj,
      base_url = base_url,
      api_version = api_version
    )
  },
  validator = function(self) {
    if (length(self@organization) != 1L) {
      "@organization must be length 1"
    } else if (!nzchar(self@organization)) {
      "@organization cannot be empty"
    } else if (length(self@pat) != 1L) {
      "@pat must be length 1"
    } else if (!nzchar(self@pat)) {
      "@pat cannot be empty"
    } else if (length(self@base_url) != 1L || !nzchar(self@base_url)) {
      "@base_url must be a valid URL string"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Work Item Class
#'
#' Represents a work item (Bug, Task, User Story, Epic, Feature) in Azure Boards.
#'
#' @export
az_work_item <- S7::new_class(
  name = "az_work_item",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    rev = S7::new_property(S7::class_integer, default = 1L),
    type = S7::new_property(S7::class_character, default = ""),
    title = S7::new_property(S7::class_character, default = ""),
    state = S7::new_property(S7::class_character, default = ""),
    assigned_to = S7::new_property(S7::class_character, default = ""),
    url = S7::new_property(S7::class_character, default = ""),
    web_url = S7::new_property(S7::class_character, default = ""),
    fields = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else if (self@id < 0L) {
      "@id must be non-negative"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Repository Class
#'
#' Represents a Git repository in Azure Repos.
#'
#' @export
az_repo <- S7::new_class(
  name = "az_repo",
  package = "azureops",
  properties = list(
    id = S7::class_character,
    name = S7::class_character,
    default_branch = S7::new_property(S7::class_character, default = "main"),
    web_url = S7::new_property(S7::class_character, default = ""),
    project = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@name) != 1L || !nzchar(self@name)) {
      "@name must be a non-empty character string"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Pull Request Class
#'
#' Represents a pull request in Azure Repos.
#'
#' @export
az_pull_request <- S7::new_class(
  name = "az_pull_request",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    title = S7::class_character,
    status = S7::class_character,
    source_branch = S7::new_property(S7::class_character, default = ""),
    target_branch = S7::new_property(S7::class_character, default = ""),
    created_by = S7::new_property(S7::class_character, default = ""),
    web_url = S7::new_property(S7::class_character, default = ""),
    repository = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else if (self@id < 0L) {
      "@id must be non-negative"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Pipeline Definition Class
#'
#' Represents a build/release pipeline definition in Azure Pipelines.
#'
#' @export
az_pipeline <- S7::new_class(
  name = "az_pipeline",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    name = S7::class_character,
    folder = S7::new_property(S7::class_character, default = "\\"),
    revision = S7::new_property(S7::class_integer, default = 1L),
    web_url = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Pipeline Run Class
#'
#' Represents an execution run of an Azure Pipeline.
#'
#' @export
az_pipeline_run <- S7::new_class(
  name = "az_pipeline_run",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    pipeline_id = S7::new_property(S7::class_integer, default = 0L),
    name = S7::new_property(S7::class_character, default = ""),
    status = S7::new_property(S7::class_character, default = "inProgress"),
    result = S7::new_property(S7::class_character, default = ""),
    created_date = S7::new_property(S7::class_character, default = ""),
    web_url = S7::new_property(S7::class_character, default = ""),
    logs_url = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Test Plan Class
#'
#' Represents a test plan in Azure Test Plans.
#'
#' @export
az_test_plan <- S7::new_class(
  name = "az_test_plan",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    name = S7::class_character,
    state = S7::new_property(S7::class_character, default = "Active"),
    area_path = S7::new_property(S7::class_character, default = ""),
    iteration = S7::new_property(S7::class_character, default = ""),
    web_url = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else {
      NULL
    }
  }
)

#' Azure DevOps Test Run Class
#'
#' Represents an executed test run in Azure Test Plans.
#'
#' @export
az_test_run <- S7::new_class(
  name = "az_test_run",
  package = "azureops",
  properties = list(
    id = S7::class_integer,
    name = S7::class_character,
    state = S7::new_property(S7::class_character, default = "InProgress"),
    total_tests = S7::new_property(S7::class_integer, default = 0L),
    pass_rate = S7::new_property(S7::class_double, default = 0.0),
    web_url = S7::new_property(S7::class_character, default = "")
  ),
  validator = function(self) {
    if (length(self@id) != 1L) {
      "@id must be length 1"
    } else if (self@pass_rate < 0.0 || self@pass_rate > 1.0) {
      "@pass_rate must be between 0.0 and 1.0"
    } else {
      NULL
    }
  }
)
