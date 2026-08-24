test_that("az_client creates valid object and masks PAT in format", {
  client <- az_client(organization = "myorg", pat = "secret_pat_12345", project = "MyProject")
  
  expect_true(S7::S7_inherits(client, az_client))
  expect_equal(client@organization, "myorg")
  expect_equal(client@pat, "secret_pat_12345")
  expect_equal(client@project, "MyProject")
  expect_equal(client@base_url, "https://dev.azure.com")
  
  # Format masks token
  fmt <- format(client)
  expect_true(any(grepl("sec\\*\\*\\*\\*", fmt)))
  expect_false(any(grepl("secret_pat_12345", fmt)))
})

test_that("az_client validator catches empty fields", {
  expect_error(
    az_client(organization = "myorg", pat = ""),
    "Personal Access Token.*not found|cannot be empty"
  )
})

test_that("az_work_item creates valid S7 object", {
  item <- az_work_item(
    id = 42L,
    rev = 2L,
    type = "Bug",
    title = "Crash on login",
    state = "Active",
    assigned_to = "Alice",
    web_url = "https://dev.azure.com/myorg/proj/_workitems/edit/42"
  )
  
  expect_true(S7::S7_inherits(item, az_work_item))
  expect_equal(item@id, 42L)
  expect_equal(item@type, "Bug")
  expect_equal(item@title, "Crash on login")
  expect_equal(item@state, "Active")
  expect_equal(item@assigned_to, "Alice")
})

test_that("az_repo and az_pull_request create valid objects", {
  repo <- az_repo(
    id = "uuid-1",
    name = "backend-service",
    default_branch = "main",
    web_url = "https://dev.azure.com/myorg/proj/_git/backend-service",
    project = "Platform"
  )
  expect_true(S7::S7_inherits(repo, az_repo))
  expect_equal(repo@name, "backend-service")
  
  pr <- az_pull_request(
    id = 101L,
    title = "Add OAuth2 support",
    status = "active",
    source_branch = "feature/oauth",
    target_branch = "main",
    created_by = "Bob",
    web_url = "https://dev.azure.com/myorg/proj/_git/backend-service/pullrequest/101"
  )
  expect_true(S7::S7_inherits(pr, az_pull_request))
  expect_equal(pr@id, 101L)
  expect_equal(pr@source_branch, "feature/oauth")
})

test_that("az_pipeline and az_pipeline_run create valid objects", {
  pipe <- az_pipeline(id = 5L, name = "CI Build")
  expect_true(S7::S7_inherits(pipe, az_pipeline))
  
  run <- az_pipeline_run(
    id = 120L,
    pipeline_id = 5L,
    name = "CI Build 2026.01",
    status = "completed",
    result = "succeeded"
  )
  expect_true(S7::S7_inherits(run, az_pipeline_run))
  expect_equal(run@status, "completed")
  expect_equal(run@result, "succeeded")
})

test_that("az_test_plan and az_test_run validate properly", {
  plan <- az_test_plan(id = 12L, name = "Sprint 10 Regression")
  expect_true(S7::S7_inherits(plan, az_test_plan))
  
  run <- az_test_run(
    id = 88L,
    name = "Nightly E2E",
    state = "Completed",
    total_tests = 100L,
    pass_rate = 0.98
  )
  expect_true(S7::S7_inherits(run, az_test_run))
  expect_equal(run@pass_rate, 0.98)
  
  # Invalid pass rate
  expect_error(
    az_test_run(id = 89L, name = "Bad", pass_rate = 1.5),
    "@pass_rate must be between 0.0 and 1.0"
  )
})
