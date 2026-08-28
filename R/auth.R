#' Retrieve or Validate Azure DevOps Personal Access Token (PAT)
#'
#' Retrieves the PAT from the provided argument, or checks the
#' `AZURE_DEVOPS_PAT` and `AZURE_PAT` environment variables.
#'
#' @param pat Optional PAT string. If `NULL`, looks in environment variables.
#' @return A non-empty PAT string.
#' @export
#' @examples
#' \dontrun{
#' az_pat()
#' }
az_pat <- function(pat = NULL, call = rlang::caller_env()) {
  if (!is.null(pat) && nzchar(pat)) {
    return(pat)
  }
  env_pat <- Sys.getenv("AZURE_DEVOPS_PAT", unset = Sys.getenv("AZURE_PAT", unset = ""))
  if (!nzchar(env_pat)) {
    cli::cli_abort(c(
      "x" = "Azure DevOps Personal Access Token (PAT) not found.",
      "i" = "Provide {.arg pat} or set the {.envvar AZURE_DEVOPS_PAT} environment variable in your {.file .Renviron}."
    ), call = call)
  }
  env_pat
}

#' Retrieve Azure DevOps Default Organization
#'
#' Retrieves the organization name from the provided argument, or checks
#' the `AZURE_DEVOPS_ORG` and `AZURE_ORG` environment variables.
#'
#' @param organization Optional organization string.
#' @return An organization string.
#' @export
az_org <- function(organization = NULL, call = rlang::caller_env()) {
  if (!is.null(organization) && nzchar(organization)) {
    return(organization)
  }
  env_org <- Sys.getenv("AZURE_DEVOPS_ORG", unset = Sys.getenv("AZURE_ORG", unset = ""))
  if (!nzchar(env_org)) {
    cli::cli_abort(c(
      "x" = "Azure DevOps organization not found.",
      "i" = "Provide {.arg organization} or set the {.envvar AZURE_DEVOPS_ORG} environment variable."
    ), call = call)
  }
  env_org
}

#' Retrieve Azure DevOps Default Project
#'
#' Retrieves the default project name from the provided argument or
#' `AZURE_DEVOPS_PROJECT` / `AZURE_PROJECT` environment variables.
#'
#' @param project Optional project string.
#' @return A character string (empty string if not specified).
#' @export
az_project <- function(project = NULL) {
  if (!is.null(project) && nzchar(project)) {
    return(project)
  }
  Sys.getenv("AZURE_DEVOPS_PROJECT", unset = Sys.getenv("AZURE_PROJECT", unset = ""))
}
