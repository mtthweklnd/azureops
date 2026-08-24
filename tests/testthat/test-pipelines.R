test_that("az_pipelines_list and az_pipeline_get work", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_pipelines_payload <- list(
    value = list(
      list(id = 12L, name = "Deploy WebApp", folder = "\\Production", revision = 4L, `_links` = list(web = list(href = "https://...")))
    )
  )
  
  mock_handler <- function(req) {
    if (grepl("_apis/pipelines/12", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_pipelines_payload$value[[1]], auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_pipelines_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    pipes <- az_pipelines_list(client = client)
    expect_equal(nrow(pipes), 1)
    expect_equal(pipes$id, 12L)
    expect_equal(pipes$name, "Deploy WebApp")
    
    pipe <- az_pipeline_get(12L, client = client)
    expect_true(S7::S7_inherits(pipe, az_pipeline))
    expect_equal(pipe@id, 12L)
    expect_equal(pipe@folder, "\\Production")
  })
})

test_that("az_pipeline_run_trigger, az_pipeline_run_get, and az_logs work", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_run_payload <- list(
    id = 555L,
    pipeline = list(id = 12L),
    name = "Deploy WebApp #555",
    state = "completed",
    result = "succeeded",
    createdDate = "2026-08-24T06:00:00Z",
    `_links` = list(web = list(href = "https://..."), logs = list(href = "https://..."))
  )
  
  mock_logs_payload <- list(
    logs = list(
      list(id = 1L, lineCount = 100L, createdOn = "2026-08-24T06:01:00Z", url = "https://.../logs/1")
    )
  )
  
  mock_handler <- function(req) {
    if (identical(req$method, "POST")) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_run_payload, auto_unbox = TRUE))
      )
    } else if (grepl("/logs/1", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "text/plain"),
        body = charToRaw("Step 1: Build succeeded\nStep 2: Test passed\n")
      )
    } else if (grepl("/logs", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_logs_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_run_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    # Trigger run
    run <- az_pipeline_run_trigger(
      pipeline_id = 12L,
      branch = "feature/test",
      template_parameters = list(env = "prod"),
      client = client
    )
    expect_true(S7::S7_inherits(run, az_pipeline_run))
    expect_equal(run@id, 555L)
    expect_equal(run@status, "completed")
    expect_equal(run@result, "succeeded")
    
    # Generic az_logs
    log_text <- az_logs(run, client = client)
    expect_match(log_text, "Step 1: Build succeeded")
  })
})
