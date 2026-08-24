test_that("az_status generic dispatches across domain models", {
  item <- az_work_item(id = 1L, title = "Task 1", type = "Task", state = "In Progress")
  expect_message(st_item <- az_status(item), "Work Item #1")
  expect_equal(st_item, "In Progress")
  
  pr <- az_pull_request(id = 55L, title = "Refactor", status = "active")
  expect_message(st_pr <- az_status(pr), "Pull Request #55")
  expect_equal(st_pr, "active")
  
  run <- az_pipeline_run(id = 200L, name = "Deploy", status = "completed", result = "succeeded")
  expect_message(st_run <- az_status(run), "Pipeline Run #200")
  expect_equal(st_run, "completed")
  
  trun <- az_test_run(id = 9L, name = "Unit Tests", state = "Completed", pass_rate = 1.0)
  expect_message(st_trun <- az_status(trun), "Test Run #9")
  expect_equal(st_trun, "Completed")
})

test_that("az_browse returns URL when browser = FALSE", {
  item <- az_work_item(id = 1L, web_url = "https://dev.azure.com/myorg/proj/_workitems/edit/1")
  expect_equal(az_browse(item, browser = FALSE), "https://dev.azure.com/myorg/proj/_workitems/edit/1")
  
  repo <- az_repo(id = "r1", name = "my-repo", web_url = "https://dev.azure.com/myorg/proj/_git/my-repo")
  expect_equal(az_browse(repo, browser = FALSE), "https://dev.azure.com/myorg/proj/_git/my-repo")
  
  # Error if empty URL
  empty_repo <- az_repo(id = "r2", name = "empty")
  expect_error(az_browse(empty_repo, browser = FALSE), "No web URL available")
})

test_that("S7::convert to class_data.frame converts domain objects into tibbles", {
  item <- az_work_item(id = 10L, type = "User Story", title = "Setup Auth", state = "Active", assigned_to = "Dev")
  df_item <- S7::convert(item, to = S7::class_data.frame)
  expect_s3_class(df_item, "tbl_df")
  expect_equal(df_item$id, 10L)
  expect_equal(df_item$title, "Setup Auth")
  
  repo <- az_repo(id = "r1", name = "infra", default_branch = "main", project = "DevOps")
  df_repo <- S7::convert(repo, to = S7::class_data.frame)
  expect_s3_class(df_repo, "tbl_df")
  expect_equal(df_repo$name, "infra")
  
  pr <- az_pull_request(id = 99L, title = "New Endpoint", status = "active")
  df_pr <- S7::convert(pr, to = S7::class_data.frame)
  expect_s3_class(df_pr, "tbl_df")
  expect_equal(df_pr$id, 99L)
  
  run <- az_pipeline_run(id = 456L, pipeline_id = 2L, name = "Release", status = "completed", result = "succeeded")
  df_run <- S7::convert(run, to = S7::class_data.frame)
  expect_s3_class(df_run, "tbl_df")
  expect_equal(df_run$result, "succeeded")
})
