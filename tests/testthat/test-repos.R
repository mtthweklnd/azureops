test_that("az_repos_list and az_repo_get return repository entities with project scoping and encoding", {
  client <- az_client(organization = "testorg", pat = "testpat", project = "Core App")
  
  mock_repos_payload <- list(
    value = list(
      list(
        id = "repo-101",
        name = "data-pipeline",
        defaultBranch = "refs/heads/main",
        webUrl = "https://dev.azure.com/testorg/proj/_git/data-pipeline",
        project = list(name = "Core App")
      )
    )
  )
  
  with_mock_api(function(req) {
    if (grepl("_apis/git/repositories/", req$url)) {
      mock_response(mock_repos_payload$value[[1]])
    } else {
      mock_response(mock_repos_payload)
    }
  }, {
    repos <- az_repos_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_s3_class(repos, "tbl_df")
    expect_equal(nrow(repos), 1)
    expect_equal(repos$name, "data-pipeline")
    expect_equal(repos$default_branch, "main")
    
    repo_obj <- az_repo_get("my repo (v2)", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_true(S7::S7_inherits(repo_obj, az_repo))
    expect_equal(repo_obj@name, "data-pipeline")
    expect_equal(repo_obj@default_branch, "main")
    expect_equal(repo_obj@project, "Core App")
  })
})

test_that("az_branches_list, az_commits_list, and az_commit_get return structured data with project scoping", {
  client <- az_client(organization = "testorg", pat = "testpat", project = "Core App")
  
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
  mock_single_commit <- list(commitId = "c123", comment = "Initial commit")
  
  with_mock_api(function(req) {
    if (grepl("/refs", req$url)) {
      mock_response(mock_branches_payload)
    } else if (grepl("/commits/c123", req$url)) {
      mock_response(mock_single_commit)
    } else {
      mock_response(mock_commits_payload)
    }
  }, {
    branches <- az_branches_list("my repo (v2)", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/refs?api-version=7.0&filter=heads%2F")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(branches), 2)
    expect_equal(branches$name, c("main", "feature/api"))
    
    commits <- az_commits_list("my repo (v2)", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/commits?api-version=7.0&%24top=50")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(commits), 1)
    expect_equal(commits$commit_id, "c123")

    commit_detail <- az_commit_get("my repo (v2)", "c123", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/commits/c123?api-version=7.0")
    expect_equal(commit_detail$commitId, "c123")
  })
})

test_that("az_pull_requests_list, az_pull_request_get, az_pull_request_create, and az_pull_request_reviewers_get work with project scoping", {
  client <- az_client(organization = "testorg", pat = "testpat", project = "Core App")
  
  mock_pr_payload <- list(
    pullRequestId = 77L,
    title = "Add REST API feature",
    status = "active",
    sourceRefName = "refs/heads/feature/rest",
    targetRefName = "refs/heads/main",
    createdBy = list(displayName = "Alice"),
    url = "https://dev.azure.com/testorg/proj/_git/repo/pullrequest/77",
    repository = list(name = "my repo (v2)")
  )
  mock_reviewers_payload <- list(
    value = list(
      list(id = "rev-1", displayName = "Alice", vote = 10L, isRequired = TRUE)
    )
  )
  
  with_mock_api(function(req) {
    if (identical(req$method, "POST")) {
      mock_response(mock_pr_payload, status_code = 201)
    } else if (grepl("reviewers", req$url)) {
      mock_response(mock_reviewers_payload)
    } else if (grepl("pullrequests/77", req$url)) {
      mock_response(mock_pr_payload)
    } else {
      mock_response(list(value = list(mock_pr_payload)))
    }
  }, {
    prs <- az_pull_requests_list("my repo (v2)", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/pullrequests?api-version=7.0&searchCriteria.status=active&%24top=50")
    expect_equal(nrow(prs), 1)
    expect_equal(prs$id, 77L)
    expect_equal(prs$source_branch, "feature/rest")
    
    pr_get <- az_pull_request_get(77L, repository_id = "my repo (v2)", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/pullrequests/77?api-version=7.0")
    expect_true(S7::S7_inherits(pr_get, az_pull_request))
    expect_equal(pr_get@id, 77L)
    expect_equal(pr_get@title, "Add REST API feature")
    expect_equal(pr_get@source_branch, "feature/rest")
    
    new_pr <- az_pull_request_create("my repo (v2)", title = "Add REST API feature", source_branch = "feature/rest", client = client)
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/pullrequests?api-version=7.0")
    expect_equal(req$method, "POST")
    expect_equal(req$body$data$title, "Add REST API feature")
    expect_equal(req$body$data$sourceRefName, "refs/heads/feature/rest")
    expect_equal(new_pr@id, 77L)

    reviewers <- az_pull_request_reviewers_get("my repo (v2)", 77L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Core%20App/_apis/git/repositories/my%20repo%20%28v2%29/pullrequests/77/reviewers?api-version=7.0")
    expect_equal(nrow(reviewers), 1)
    expect_equal(reviewers$display_name, "Alice")
  })
})

test_that("repository parsers fail loudly on unexpected responses without ID", {
  expect_error(
    .parse_repo(list(name = "No Repo ID")),
    "repository has no valid ID"
  )
  expect_error(
    .parse_pull_request(list(title = "No PR ID")),
    "pull request has no valid ID"
  )
})
