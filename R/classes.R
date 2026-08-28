#' @include auth.R
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
                         api_version = "7.0",
                         call = rlang::caller_env()) {
    org <- az_org(organization, call = call)
    token <- az_pat(pat, call = call)
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
#' An S7 class representing a work item (Bug, Task, User Story, Epic, Feature) in Azure Boards.
#' Corresponds to the Azure DevOps Work Item REST API resource (`/_apis/wit/workitems`).
#'
#' @param id Integer ID of the work item (`integer`).
#' @param rev Integer revision number (`integer`).
#' @param type Work item type string (e.g. `"Bug"`, `"Task"`, `"User Story"`, `"Epic"`) (`character`).
#' @param title Title of the work item (`character`).
#' @param state Current workflow state (e.g. `"Active"`, `"Closed"`, `"New"`) (`character`).
#' @param assigned_to Display name or email of the assigned user (`character`).
#' @param url REST API self-link URL for the work item (`character`).
#' @param web_url Web browser URL to view/edit the work item in Azure Boards (`character`).
#' @param fields Named list containing all raw fields returned by the Azure DevOps API (`list`).
#' @return An S7 `az_work_item` object.
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
#' An S7 class representing a Git repository in Azure Repos.
#' Corresponds to the Azure DevOps Git Repository REST API resource (`/_apis/git/repositories`).
#'
#' @param id Unique identifier (UUID string) of the repository (`character`).
#' @param name Name of the repository (`character`).
#' @param default_branch Default branch name without `refs/heads/` prefix (e.g. `"main"`) (`character`).
#' @param web_url Web browser URL for the repository in Azure Repos (`character`).
#' @param project Name of the project containing the repository (`character`).
#' @return An S7 `az_repo` object.
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
#' An S7 class representing a pull request in Azure Repos.
#' Corresponds to the Azure DevOps Pull Request REST API resource (`/_apis/git/repositories/{repositoryId}/pullrequests`).
#'
#' @param id Integer ID of the pull request (`integer`).
#' @param title Title of the pull request (`character`).
#' @param status Current status of the pull request (e.g. `"active"`, `"abandoned"`, `"completed"`) (`character`).
#' @param source_branch Source branch name without `refs/heads/` prefix (`character`).
#' @param target_branch Target branch name without `refs/heads/` prefix (`character`).
#' @param created_by Display name of the user who created the pull request (`character`).
#' @param web_url Web browser URL for the pull request (`character`).
#' @param repository Name of the repository containing the pull request (`character`).
#' @return An S7 `az_pull_request` object.
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
#' An S7 class representing a build or release pipeline definition in Azure Pipelines.
#' Corresponds to the Azure DevOps Pipeline REST API resource (`/_apis/pipelines`).
#'
#' @param id Integer ID of the pipeline (`integer`).
#' @param name Name of the pipeline (`character`).
#' @param folder Folder path where the pipeline definition resides (`character`).
#' @param revision Integer revision number of the pipeline definition (`integer`).
#' @param web_url Web browser URL for the pipeline in Azure Pipelines (`character`).
#' @return An S7 `az_pipeline` object.
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
#' An S7 class representing an execution run of an Azure Pipeline.
#' Corresponds to the Azure DevOps Pipeline Run REST API resource (`/_apis/pipelines/{pipelineId}/runs`).
#'
#' @param id Integer ID of the pipeline run (`integer`).
#' @param pipeline_id Integer ID of the associated pipeline definition (`integer`).
#' @param name Name or build number of the pipeline run (`character`).
#' @param status Current execution state (e.g. `"completed"`, `"inProgress"`, `"canceling"`) (`character`).
#' @param result Final execution result (e.g. `"succeeded"`, `"failed"`, `"canceled"`) (`character`).
#' @param created_date ISO 8601 timestamp string when the run was queued/created (`character`).
#' @param web_url Web browser URL for the pipeline run in Azure Pipelines (`character`).
#' @param logs_url REST API URL to retrieve logs for the run (`character`).
#' @return An S7 `az_pipeline_run` object.
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
#' An S7 class representing a test plan in Azure Test Plans.
#' Corresponds to the Azure DevOps Test Plan REST API resource (`/_apis/testplan/plans`).
#'
#' @param id Integer ID of the test plan (`integer`).
#' @param name Name of the test plan (`character`).
#' @param state Current state of the test plan (e.g. `"Active"`, `"Inactive"`) (`character`).
#' @param area_path Area path associated with the test plan (`character`).
#' @param iteration Iteration or sprint path associated with the test plan (`character`).
#' @param web_url Web browser URL for the test plan in Azure Test Plans (`character`).
#' @return An S7 `az_test_plan` object.
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
#' An S7 class representing an executed test run in Azure Test Plans.
#' Corresponds to the Azure DevOps Test Run REST API resource (`/_apis/test/runs`).
#'
#' @param id Integer ID of the test run (`integer`).
#' @param name Name of the test run (`character`).
#' @param state Current execution state (e.g. `"Completed"`, `"InProgress"`) (`character`).
#' @param total_tests Integer total number of tests in the run (`integer`).
#' @param pass_rate Proportional pass rate between `0.0` and `1.0` (`double`).
#' @param web_url Web browser URL for the test run (`character`).
#' @return An S7 `az_test_run` object.
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
