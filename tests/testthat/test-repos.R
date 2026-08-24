test_that("az_repos_list and az_repo_get return repository entities", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_repos_payload <- list(
    value = list(
      list(
        id = "repo-101",
        name = "data-pipeline",
        defaultBranch = "refs/heads/main",
        webUrl = "https://dev.azure.com/testorg/proj/_git/data-pipeline",
        project = list(name = "Analytics")
      )
    )
  )
  
  mock_handler <- function(req) {
    if (grepl("_apis/git/repositories/repo-101", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_repos_payload$value[[1]], auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_repos_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    repos <- az_repos_list(client = client)
    expect_s3_class(repos, "tbl_df")
    expect_equal(nrow(repos), 1)
    expect_equal(repos$name, "data-pipeline")
    expect_equal(repos$default_branch, "main")
    
    repo_obj <- az_repo_get("repo-101", client = client)
    expect_true(S7::S7_inherits(repo_obj, az_repo))
    expect_equal(repo_obj@name, "data-pipeline")
    expect_equal(repo_obj@default_branch, "main")
    expect_equal(repo_obj@project, "Analytics")
  })
})

test_that("az_branches_list and az_commits_list return structured tabular data", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_branches_payload <- list(
    value = list(
      list(name = "refs/heads/main", objectId = "sha-main-123"),
      list(name = "refs/heads/feature/api", objectId = "sha-feat-456")
    )
  )
  
  mock_commits_payload <- list(
    value = list(
      list(commitId = "c123", author = list(name = "Dev", date = "2026-08-24T00:00:00Z"), comment = "Initial commit")
    )
  )
  
  mock_handler <- function(req) {
    if (grepl("/refs", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_branches_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_commits_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    branches <- az_branches_list("repo-101", client = client)
    expect_equal(nrow(branches), 2)
    expect_equal(branches$name, c("main", "feature/api"))
    
    commits <- az_commits_list("repo-101", client = client)
    expect_equal(nrow(commits), 1)
    expect_equal(commits$commit_id, "c123")
  })
})

test_that("az_pull_requests_list, az_pull_request_get, and az_pull_request_create manage PR lifecycle", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_pr_payload <- list(
    pullRequestId = 77L,
    title = "Add REST API feature",
    status = "active",
    sourceRefName = "refs/heads/feature/rest",
    targetRefName = "refs/heads/main",
    createdBy = list(displayName = "Alice"),
    url = "https://dev.azure.com/testorg/proj/_git/repo/pullrequest/77",
    repository = list(name = "myrepo")
  )
  
  mock_handler <- function(req) {
    if (identical(req$method, "POST")) {
      httr2::response(
        status_code = 201,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_pr_payload, auto_unbox = TRUE))
      )
    } else if (grepl("pullrequests/77", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_pr_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(value = list(mock_pr_payload)), auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    prs <- az_pull_requests_list(client = client)
    expect_equal(nrow(prs), 1)
    expect_equal(prs$id, 77L)
    expect_equal(prs$source_branch, "feature/rest")
    
    pr_get <- az_pull_request_get(77L, client = client)
    expect_true(S7::S7_inherits(pr_get, az_pull_request))
    expect_equal(pr_get@id, 77L)
    expect_equal(pr_get@title, "Add REST API feature")
    expect_equal(pr_get@source_branch, "feature/rest")
    
    new_pr <- az_pull_request_create("myrepo", title = "Add REST API feature", source_branch = "feature/rest", client = client)
    expect_equal(new_pr@id, 77L)
  })
})
