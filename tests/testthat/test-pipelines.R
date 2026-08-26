test_that("az_pipelines_list, az_pipeline_get, az_pipeline_runs_list, az_pipeline_run_get work with project scoping", {
  client <- az_client(organization = "testorg", pat = "testpat", project = "MyProject")
  
  mock_pipelines_payload <- list(
    value = list(
      list(id = 12L, name = "Deploy WebApp", folder = "\\Production", revision = 4L, `_links` = list(web = list(href = "https://...")))
    )
  )
  mock_run_payload <- list(
    id = 555L,
    pipeline = list(id = 12L),
    name = "Deploy WebApp #555",
    state = "completed",
    result = "succeeded",
    createdDate = "2026-08-24T06:00:00Z"
  )
  
  with_mock_api(function(req) {
    if (grepl("_apis/pipelines/12/runs/555", req$url)) {
      mock_response(mock_run_payload)
    } else if (grepl("_apis/pipelines/runs", req$url) || grepl("_apis/pipelines/12/runs", req$url)) {
      mock_response(list(value = list(mock_run_payload)))
    } else if (grepl("_apis/pipelines/12", req$url)) {
      mock_response(mock_pipelines_payload$value[[1]])
    } else {
      mock_response(mock_pipelines_payload)
    }
  }, {
    pipes <- az_pipelines_list(client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines?api-version=7.0")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_equal(nrow(pipes), 1)
    expect_equal(pipes$id, 12L)
    expect_equal(pipes$name, "Deploy WebApp")
    
    pipe <- az_pipeline_get(12L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12?api-version=7.0")
    expect_true(S7::S7_inherits(pipe, az_pipeline))
    expect_equal(pipe@id, 12L)
    expect_equal(pipe@folder, "\\Production")

    runs <- az_pipeline_runs_list(12L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12/runs?api-version=7.0")
    expect_equal(nrow(runs), 1)
    expect_equal(runs$id, 555L)

    run_obj <- az_pipeline_run_get(12L, 555L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12/runs/555?api-version=7.0")
    expect_true(S7::S7_inherits(run_obj, az_pipeline_run))
    expect_equal(run_obj@id, 555L)
  })
})

test_that("az_pipeline_run_trigger, az_pipeline_run_logs_list, and az_logs work with project scoping", {
  client <- az_client(organization = "testorg", pat = "testpat", project = "MyProject")
  
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
  
  with_mock_api(function(req) {
    if (identical(req$method, "POST")) {
      mock_response(mock_run_payload)
    } else if (grepl("/logs/1", req$url)) {
      mock_response("Step 1: Build succeeded\nStep 2: Test passed\n", headers = list("content-type" = "text/plain"))
    } else if (grepl("/logs", req$url)) {
      mock_response(mock_logs_payload)
    } else {
      mock_response(mock_run_payload)
    }
  }, {
    # Trigger run
    run <- az_pipeline_run_trigger(
      pipeline_id = 12L,
      branch = "feature/test",
      template_parameters = list(env = "prod"),
      client = client
    )
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12/runs?api-version=7.0")
    expect_equal(req$method, "POST")
    expect_equal(req$body$data$resources$repositories$self$refName, "refs/heads/feature/test")
    expect_equal(req$body$data$templateParameters$env, "prod")
    expect_true(S7::S7_inherits(run, az_pipeline_run))
    expect_equal(run@id, 555L)
    expect_equal(run@status, "completed")
    expect_equal(run@result, "succeeded")
    
    # Generic az_logs
    log_text <- az_logs(run, client = client)
    reqs <- captured_requests()
    # Should have called logs list and then log get
    expect_equal(reqs[[length(reqs) - 1]]$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12/runs/555/logs?api-version=7.0")
    expect_equal(reqs[[length(reqs)]]$url, "https://dev.azure.com/testorg/MyProject/_apis/pipelines/12/runs/555/logs/1?api-version=7.0")
    expect_match(log_text, "Step 1: Build succeeded")
  })
})

test_that("pipeline parsers fail loudly on unexpected responses without ID", {
  expect_error(
    .parse_pipeline(list(name = "No ID")),
    "pipeline definition has no valid ID"
  )
  expect_error(
    .parse_pipeline_run(list(name = "No Run ID")),
    "pipeline run has no valid ID"
  )
})
