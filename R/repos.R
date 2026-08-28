#' @include classes.R client.R generics.R
NULL

#' Parse Repository JSON into S7 az_repo
#' @noRd
.parse_repo <- function(item, call = rlang::caller_env()) {
  repo_id <- purrr::pluck(item, "id")
  if (is.null(repo_id) || !nzchar(as.character(repo_id))) {
    cli::cli_abort(c(
      "x" = "Unexpected API response: repository has no valid ID.",
      "i" = "The Azure DevOps API returned an unexpected response structure."
    ), call = call)
  }
  az_repo(
    id = as.character(repo_id),
    name = as.character(purrr::pluck(item, "name", .default = "")),
    default_branch = as.character(sub("^refs/heads/", "", purrr::pluck(item, "defaultBranch", .default = "main"))),
    web_url = as.character(purrr::pluck(item, "webUrl", .default = "")),
    project = as.character(purrr::pluck(item, "project", "name", .default = ""))
  )
}

#' Parse Pull Request JSON into S7 az_pull_request
#' @noRd
.parse_pull_request <- function(item, call = rlang::caller_env()) {
  pr_id <- purrr::pluck(item, "pullRequestId")
  if (!.is_valid_id(pr_id)) {
    cli::cli_abort(c(
      "x" = "Unexpected API response: pull request has no valid ID.",
      "i" = "The Azure DevOps API returned an unexpected response structure."
    ), call = call)
  }
  az_pull_request(
    id = as.integer(pr_id),
    title = as.character(purrr::pluck(item, "title", .default = "")),
    status = as.character(purrr::pluck(item, "status", .default = "")),
    source_branch = as.character(sub("^refs/heads/", "", purrr::pluck(item, "sourceRefName", .default = ""))),
    target_branch = as.character(sub("^refs/heads/", "", purrr::pluck(item, "targetRefName", .default = ""))),
    created_by = as.character(purrr::pluck(item, "createdBy", "displayName", .default = "")),
    web_url = as.character(purrr::pluck(item, "url", .default = "")),
    repository = as.character(purrr::pluck(item, "repository", "name", .default = ""))
  )
}

#' List Git Repositories
#'
#' @param project Project name or ID (optional).
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of repositories.
#' @export
#' @examples
#' \dontrun{
#' az_repos_list()
#' }
az_repos_list <- function(project = NULL, client = NULL) {
  req <- az_request("_apis/git/repositories", client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      name = character(),
      default_branch = character(),
      web_url = character(),
      project = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    name = purrr::map_chr(items, ~ purrr::pluck(.x, "name", .default = "")),
    default_branch = purrr::map_chr(items, ~ sub("^refs/heads/", "", purrr::pluck(.x, "defaultBranch", .default = ""))),
    web_url = purrr::map_chr(items, ~ purrr::pluck(.x, "webUrl", .default = "")),
    project = purrr::map_chr(items, ~ purrr::pluck(.x, "project", "name", .default = ""))
  )
}

#' Get a Single Git Repository
#'
#' @param repository_id Repository name or ID.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @param call Caller environment for error attribution.
#' @return An S7 `az_repo` object.
#' @export
az_repo_get <- function(repository_id, project = NULL, client = NULL, call = rlang::caller_env()) {
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s", repo_enc)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  .parse_repo(res, call = call)
}

#' List Branches in a Repository
#'
#' @param repository_id Repository name or ID.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of branch names and commit object IDs.
#' @export
az_branches_list <- function(repository_id, project = NULL, client = NULL) {
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s/refs", repo_enc)
  req <- az_request(endpoint, client = client, project = project, query = list(filter = "heads/"))
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      name = character(),
      object_id = character()
    ))
  }
  
  tibble::tibble(
    name = purrr::map_chr(items, ~ sub("^refs/heads/", "", purrr::pluck(.x, "name", .default = ""))),
    object_id = purrr::map_chr(items, ~ purrr::pluck(.x, "objectId", .default = ""))
  )
}

#' List Commits in a Repository
#'
#' @param repository_id Repository name or ID.
#' @param branch Branch name (e.g. `"main"`).
#' @param top Number of commits to fetch (default: 50).
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of commits.
#' @export
az_commits_list <- function(repository_id,
                            branch = NULL,
                            top = 50,
                            project = NULL,
                            client = NULL) {
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s/commits", repo_enc)
  query <- list(`$top` = top)
  if (!is.null(branch) && nzchar(branch)) {
    query$`searchCriteria.itemVersion.version` = branch
  }
  
  req <- az_request(endpoint, client = client, project = project, query = query)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      commit_id = character(),
      author = character(),
      comment = character(),
      date = character()
    ))
  }
  
  tibble::tibble(
    commit_id = purrr::map_chr(items, ~ purrr::pluck(.x, "commitId", .default = "")),
    author = purrr::map_chr(items, ~ purrr::pluck(.x, "author", "name", .default = "")),
    comment = purrr::map_chr(items, ~ purrr::pluck(.x, "comment", .default = "")),
    date = purrr::map_chr(items, ~ purrr::pluck(.x, "author", "date", .default = ""))
  )
}

#' Get a Single Commit Details
#'
#' @param repository_id Repository name or ID.
#' @param commit_id Full SHA or prefix of commit.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A list representing commit details.
#' @export
az_commit_get <- function(repository_id, commit_id, project = NULL, client = NULL) {
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  com_enc <- utils::URLencode(as.character(commit_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s/commits/%s", repo_enc, com_enc)
  req <- az_request(endpoint, client = client, project = project)
  az_perform(req)
}

#' List Pull Requests
#'
#' @param repository_id Optional repository name or ID.
#' @param status Filter by status (`"active"`, `"abandoned"`, `"completed"`, `"all"`).
#' @param top Maximum number of pull requests to retrieve.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @param call Caller environment for error attribution.
#' @return A `tibble` of pull requests.
#' @export
az_pull_requests_list <- function(repository_id = NULL,
                                  status = c("active", "abandoned", "completed", "all"),
                                  top = 50,
                                  project = NULL,
                                  client = NULL,
                                  call = rlang::caller_env()) {
  status <- rlang::arg_match(status, error_call = call)
  
  endpoint <- if (!is.null(repository_id) && nzchar(repository_id)) {
    repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
    sprintf("_apis/git/repositories/%s/pullrequests", repo_enc)
  } else {
    "_apis/git/pullrequests"
  }
  
  query <- list(
    `searchCriteria.status` = status,
    `$top` = top
  )
  
  req <- az_request(endpoint, client = client, project = project, query = query)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = integer(),
      title = character(),
      status = character(),
      source_branch = character(),
      target_branch = character(),
      created_by = character()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "pullRequestId", .default = 0L))),
    title = purrr::map_chr(items, ~ purrr::pluck(.x, "title", .default = "")),
    status = purrr::map_chr(items, ~ purrr::pluck(.x, "status", .default = "")),
    source_branch = purrr::map_chr(items, ~ sub("^refs/heads/", "", purrr::pluck(.x, "sourceRefName", .default = ""))),
    target_branch = purrr::map_chr(items, ~ sub("^refs/heads/", "", purrr::pluck(.x, "targetRefName", .default = ""))),
    created_by = purrr::map_chr(items, ~ purrr::pluck(.x, "createdBy", "displayName", .default = ""))
  )
}

#' Get a Single Pull Request
#'
#' @param pull_request_id Integer ID of the pull request.
#' @param repository_id Optional repository name or ID.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @param call Caller environment for error attribution.
#' @return An S7 `az_pull_request` object.
#' @export
az_pull_request_get <- function(pull_request_id,
                                repository_id = NULL,
                                project = NULL,
                                client = NULL,
                                call = rlang::caller_env()) {
  endpoint <- if (!is.null(repository_id) && nzchar(repository_id)) {
    repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
    sprintf("_apis/git/repositories/%s/pullrequests/%s", repo_enc, pull_request_id)
  } else {
    sprintf("_apis/git/pullrequests/%s", pull_request_id)
  }
  
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  .parse_pull_request(res, call = call)
}

#' Create a Pull Request
#'
#' @param repository_id Repository name or ID.
#' @param title Pull request title.
#' @param source_branch Source branch name (e.g. `"feature/auth"`).
#' @param target_branch Target branch name (default: `"main"`).
#' @param description Optional description or markdown summary.
#' @param is_draft Logical; whether to create as a draft pull request.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @param call Caller environment for error attribution.
#' @return An S7 `az_pull_request` object.
#' @export
az_pull_request_create <- function(repository_id,
                                   title,
                                   source_branch,
                                   target_branch = "main",
                                   description = "",
                                   is_draft = FALSE,
                                   project = NULL,
                                   client = NULL,
                                   call = rlang::caller_env()) {
  source_ref <- if (!grepl("^refs/heads/", source_branch)) paste0("refs/heads/", source_branch) else source_branch
  target_ref <- if (!grepl("^refs/heads/", target_branch)) paste0("refs/heads/", target_branch) else target_branch
  
  body <- list(
    sourceRefName = source_ref,
    targetRefName = target_ref,
    title = title,
    description = description,
    isDraft = is_draft
  )
  
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s/pullrequests", repo_enc)
  
  req <- az_request(endpoint, client = client, project = project) |>
    httr2::req_method("POST") |>
    httr2::req_body_json(body)
    
  res <- az_perform(req)
  .parse_pull_request(res, call = call)
}

#' List Pull Request Reviewers
#'
#' @param repository_id Repository name or ID.
#' @param pull_request_id Integer ID of the pull request.
#' @param project Project name or ID.
#' @param client Optional `az_client` S7 object.
#' @return A `tibble` of reviewers and vote statuses.
#' @export
az_pull_request_reviewers_get <- function(repository_id,
                                          pull_request_id,
                                          project = NULL,
                                          client = NULL) {
  repo_enc <- utils::URLencode(as.character(repository_id), reserved = TRUE)
  endpoint <- sprintf("_apis/git/repositories/%s/pullrequests/%s/reviewers", repo_enc, pull_request_id)
  req <- az_request(endpoint, client = client, project = project)
  res <- az_perform(req)
  
  items <- purrr::pluck(res, "value", .default = list())
  if (length(items) == 0) {
    return(tibble::tibble(
      id = character(),
      display_name = character(),
      vote = integer(),
      is_required = logical()
    ))
  }
  
  tibble::tibble(
    id = purrr::map_chr(items, ~ purrr::pluck(.x, "id", .default = "")),
    display_name = purrr::map_chr(items, ~ purrr::pluck(.x, "displayName", .default = "")),
    vote = purrr::map_int(items, ~ as.integer(purrr::pluck(.x, "vote", .default = 0L))),
    is_required = purrr::map_lgl(items, ~ as.logical(purrr::pluck(.x, "isRequired", .default = FALSE)))
  )
}
