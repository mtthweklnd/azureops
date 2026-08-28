test_that("az_work_item_get and az_work_items_get parse S7 objects", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_item_payload <- list(
    id = 123L,
    rev = 3L,
    url = "https://dev.azure.com/testorg/_apis/wit/workitems/123",
    `_links` = list(html = list(href = "https://dev.azure.com/testorg/proj/_workitems/edit/123")),
    fields = list(
      `System.WorkItemType` = "Bug",
      `System.Title` = "Database Connection Timeout",
      `System.State` = "Active",
      `System.AssignedTo` = list(displayName = "Charlie Eng")
    )
  )
  
  with_mock_api(function(req) {
    if (grepl("_apis/wit/workitems/123", req$url)) {
      mock_response(mock_item_payload)
    } else {
      mock_response(list(value = list(mock_item_payload)))
    }
  }, {
    item <- az_work_item_get(123L, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/wit/workitems/123?api-version=7.0&%24expand=all")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_true(S7::S7_inherits(item, az_work_item))
    expect_equal(item@id, 123L)
    expect_equal(item@type, "Bug")
    expect_equal(item@title, "Database Connection Timeout")
    expect_equal(item@state, "Active")
    expect_equal(item@assigned_to, "Charlie Eng")
    expect_equal(item@web_url, "https://dev.azure.com/testorg/proj/_workitems/edit/123")
    
    # Batch get as tibble
    df <- az_work_items_get(c(123L), as_data_frame = TRUE, client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/_apis/wit/workitems?api-version=7.0&ids=123&%24expand=all")
    expect_equal(last_request()$method %||% "GET", "GET")
    expect_s3_class(df, "tbl_df")
    expect_equal(nrow(df), 1)
    expect_equal(df$id, 123L)
  })
})

test_that("az_work_item_create constructs JSON patch and returns S7 object", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_created_payload <- list(
    id = 456L,
    rev = 1L,
    fields = list(
      `System.WorkItemType` = "User Story",
      `System.Title` = "Implement OAuth",
      `System.Description` = "Add Azure AD authentication",
      `System.AssignedTo` = list(displayName = "Dev User"),
      `Microsoft.VSTS.Common.Priority` = 1L
    )
  )
  
  with_mock_api(function(req) {
    mock_response(mock_created_payload)
  }, {
    item <- az_work_item_create(
      type = "User Story",
      title = "Implement OAuth",
      description = "Add Azure AD authentication",
      assigned_to = "dev@example.com",
      fields = list("Microsoft.VSTS.Common.Priority" = 1L),
      project = "MyProj",
      client = client
    )
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/MyProj/_apis/wit/workitems/%24User%20Story?api-version=7.0")
    expect_equal(req$method, "POST")
    expect_equal(req$headers$`Content-Type`, "application/json-patch+json")
    expect_true(S7::S7_inherits(item, az_work_item))
    expect_equal(item@id, 456L)
    expect_equal(item@type, "User Story")
    expect_equal(item@title, "Implement OAuth")
  })
})

test_that("az_work_item_update sends PATCH request and handles empty fields", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  # Error on empty fields
  expect_error(az_work_item_update(456L, fields = list(), client = client), "No fields provided")
  
  mock_updated_payload <- list(
    id = 456L,
    fields = list(`System.State` = "Closed", `System.Title` = "Implement OAuth (Done)")
  )
  
  with_mock_api(function(req) {
    mock_response(mock_updated_payload)
  }, {
    res <- az_work_item_update(456L, fields = list("System.State" = "Closed"), client = client)
    req <- last_request()
    expect_equal(req$url, "https://dev.azure.com/testorg/_apis/wit/workitems/456?api-version=7.0")
    expect_equal(req$method, "PATCH")
    expect_equal(req$headers$`Content-Type`, "application/json-patch+json")
    expect_equal(res@state, "Closed")
  })
})

test_that("az_wiql_query executes and resolves items", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_wiql_payload <- list(
    queryType = "flat",
    workItems = list(list(id = 123L, url = "https://..."))
  )
  
  mock_item_payload <- list(
    id = 123L,
    fields = list(`System.Title` = "Test Query Item", `System.State` = "New", `System.WorkItemType` = "Task")
  )
  
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      mock_response(mock_wiql_payload)
    } else {
      mock_response(list(value = list(mock_item_payload)))
    }
  }, {
    items <- az_wiql_query("SELECT [System.Id] FROM WorkItems", project = "MyProj", client = client)
    reqs <- captured_requests()
    expect_equal(length(reqs), 2)
    expect_equal(reqs[[1]]$url, "https://dev.azure.com/testorg/MyProj/_apis/wit/wiql?api-version=7.0")
    expect_equal(reqs[[1]]$method, "POST")
    expect_equal(reqs[[2]]$url, "https://dev.azure.com/testorg/_apis/wit/workitems?api-version=7.0&ids=123&%24expand=all")
    expect_equal(length(items), 1)
    expect_equal(items[[1]]@id, 123L)
    expect_equal(items[[1]]@title, "Test Query Item")
  })
})

test_that("az_iterations_list and az_sprint_capacity_get return sprint analytics", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_iterations_payload <- list(
    value = list(
      list(
        id = "sprint-1-guid",
        name = "Sprint 1",
        path = "Project\\Sprint 1",
        attributes = list(startDate = "2026-08-01T00:00:00Z", finishDate = "2026-08-14T00:00:00Z")
      )
    )
  )
  
  mock_capacity_payload <- list(
    value = list(
      list(
        teamMember = list(displayName = "Alice Dev"),
        activities = list(
          list(name = "Development", capacityPerDay = 6),
          list(name = "Review", capacityPerDay = 2)
        )
      )
    )
  )
  
  with_mock_api(function(req) {
    if (grepl("/capacities", req$url)) {
      mock_response(mock_capacity_payload)
    } else {
      mock_response(mock_iterations_payload)
    }
  }, {
    iterations <- az_iterations_list(project = "Proj", team = "TeamA", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Proj/_apis/work/teamsettings/iterations?api-version=7.0")
    expect_s3_class(iterations, "tbl_df")
    expect_equal(nrow(iterations), 1)
    expect_equal(iterations$name, "Sprint 1")
    expect_equal(iterations$start_date, "2026-08-01T00:00:00Z")
    
    capacities <- az_sprint_capacity_get("sprint-1-guid", team = "TeamA", project = "Proj", client = client)
    expect_equal(last_request()$url, "https://dev.azure.com/testorg/Proj/_apis/work/teamsettings/iterations/sprint-1-guid/capacities?api-version=7.0")
    expect_s3_class(capacities, "tbl_df")
    expect_equal(nrow(capacities), 1)
    expect_equal(capacities$display_name, "Alice Dev")
    expect_equal(capacities$total_capacity, 8) # 6 + 2
  })
})

test_that("work item parsing fails loudly when response has no valid ID", {
  expect_error(
    .parse_work_item(list(fields = list(`System.Title` = "Missing ID"))),
    "work item has no valid ID"
  )
  expect_error(
    .parse_work_item(list(id = 0L)),
    "work item has no valid ID"
  )
  expect_error(
    .parse_work_item(NULL),
    "work item has no valid ID"
  )
})

test_that(".build_my_work_items_wiql constructs expected WIQL queries", {
  # Defaults: @me and active state
  q1 <- .build_my_work_items_wiql()
  expect_true(grepl("\\[System.AssignedTo\\] = @me", q1))
  expect_true(grepl("\\[System.State\\] NOT IN \\('Closed', 'Completed', 'Resolved', 'Removed'\\)", q1))
  
  # Explicit email and specific state
  q2 <- .build_my_work_items_wiql(email = "alice@example.com", state = "New")
  expect_true(grepl("\\[System.AssignedTo\\] CONTAINS 'alice@example.com'", q2))
  expect_true(grepl("\\[System.State\\] = 'New'", q2))
  
  # Single type filter
  q3 <- .build_my_work_items_wiql(type = "Bug")
  expect_true(grepl("\\[System.WorkItemType\\] = 'Bug'", q3))
  
  # Multiple type filters
  q4 <- .build_my_work_items_wiql(type = c("Bug", "Task"))
  expect_true(grepl("\\[System.WorkItemType\\] IN \\('Bug', 'Task'\\)", q4))
  
  # State = "all" excludes state filter from WHERE clause
  q5 <- .build_my_work_items_wiql(state = "all")
  expect_false(grepl("WHERE .* \\[System.State\\]", q5))
  
  # sprint_only = TRUE
  q6 <- .build_my_work_items_wiql(sprint_only = TRUE)
  expect_true(grepl("\\[System.IterationPath\\] = @currentIteration", q6))
  
  # String escaping single quotes
  q7 <- .build_my_work_items_wiql(email = "o'connor@example.com")
  expect_true(grepl("o''connor@example.com", q7))
})

test_that(".build_feature_work_items_wiql constructs expected queries and validates input", {
  q1 <- .build_feature_work_items_wiql(100L)
  expect_true(grepl("\\[System.Parent\\] = 100", q1))
  
  q2 <- .build_feature_work_items_wiql(100L, state = "active")
  expect_true(grepl("\\[System.Parent\\] = 100 AND \\[System.State\\] NOT IN", q2))
  
  expect_error(.build_feature_work_items_wiql(NULL), "must be a positive integer")
  expect_error(.build_feature_work_items_wiql(-5L), "must be a positive integer")
})

test_that("az_my_work_items executes WIQL query and returns work items", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_wiql_payload <- list(
    queryType = "flat",
    workItems = list(list(id = 777L, url = "https://..."))
  )
  
  mock_item_payload <- list(
    id = 777L,
    fields = list(
      `System.Title` = "User Task",
      `System.State` = "Active",
      `System.WorkItemType` = "Task",
      `System.AssignedTo` = list(displayName = "Charlie Eng")
    )
  )
  
  last_wiql_sent <- NULL
  
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      if (!is.null(req$body$data)) {
        last_wiql_sent <<- req$body$data$query
      }
      mock_response(mock_wiql_payload)
    } else {
      mock_response(list(value = list(mock_item_payload)))
    }
  }, {
    items <- az_my_work_items(client = client)
    reqs <- captured_requests()
    expect_equal(length(reqs), 2)
    expect_equal(reqs[[1]]$url, "https://dev.azure.com/testorg/_apis/wit/wiql?api-version=7.0")
    expect_true(grepl("\\[System.AssignedTo\\] = @me", last_wiql_sent))
    
    expect_equal(length(items), 1)
    expect_equal(items[[1]]@id, 777L)
    expect_equal(items[[1]]@type, "Task")
    
    # Return as tibble
    df <- az_my_work_items(as_data_frame = TRUE, client = client)
    expect_s3_class(df, "tbl_df")
    expect_equal(nrow(df), 1)
    expect_equal(df$id, 777L)
  })
})

test_that("az_feature_work_items handles feature_id and feature_title lookup", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  mock_feature_wiql_payload <- list(
    queryType = "flat",
    workItems = list(list(id = 500L, url = "https://..."))
  )
  
  mock_child_wiql_payload <- list(
    queryType = "flat",
    workItems = list(list(id = 501L, url = "https://..."))
  )
  
  mock_child_item_payload <- list(
    id = 501L,
    fields = list(
      `System.Title` = "Feature Child Story",
      `System.State` = "New",
      `System.WorkItemType` = "User Story"
    )
  )
  
  last_wiql_sent <- NULL
  
  # By feature_id
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      if (!is.null(req$body$data)) {
        last_wiql_sent <<- req$body$data$query
      }
      mock_response(mock_child_wiql_payload)
    } else {
      mock_response(list(value = list(mock_child_item_payload)))
    }
  }, {
    items <- az_feature_work_items(feature_id = 500L, client = client)
    expect_true(grepl("\\[System.Parent\\] = 500", last_wiql_sent))
    expect_equal(items[[1]]@id, 501L)
  })
  
  # By feature_title search
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      query_str <- if (!is.null(req$body$data)) req$body$data$query else ""
      if (grepl("WorkItemType\\] = 'Feature'", query_str)) {
        mock_response(mock_feature_wiql_payload)
      } else {
        mock_response(mock_child_wiql_payload)
      }
    } else {
      mock_response(list(value = list(mock_child_item_payload)))
    }
  }, {
    items <- az_feature_work_items(feature_title = "OAuth Login", client = client)
    reqs <- captured_requests()
    expect_equal(length(reqs), 3) # 1. title search WIQL, 2. child items WIQL, 3. batch get items
    expect_equal(items[[1]]@id, 501L)
  })
  
  # Error when feature_title lookup returns no match
  with_mock_api(function(req) {
    mock_response(list(queryType = "flat", workItems = list()))
  }, {
    expect_error(
      az_feature_work_items(feature_title = "Nonexistent Feature", client = client),
      "No Feature work item found matching title"
    )
  })
  
  # Error when neither parameter is supplied
  expect_error(
    az_feature_work_items(client = client),
    "Must provide either a valid `feature_id`"
  )
})

test_that("error call context correctly attributes errors to caller environment", {
  client <- az_client(organization = "testorg", pat = "testpat")
  
  # When helper .build_feature_work_items_wiql fails inside az_feature_work_items,
  # error call is attributed to caller frame (wrapper_fn1), not .build_feature_work_items_wiql
  wrapper_fn1 <- function() {
    az_feature_work_items(feature_id = -1, client = client)
  }
  cnd <- rlang::catch_cnd(wrapper_fn1(), classes = "error")
  expect_s3_class(cnd, "rlang_error")
  expect_equal(rlang::call_name(cnd$call), "wrapper_fn1")

  # Non-numeric string feature_id produces clean error attributed to caller frame
  wrapper_fn_str <- function() {
    az_feature_work_items(feature_id = "abc", client = client)
  }
  cnd_str <- rlang::catch_cnd(wrapper_fn_str(), classes = "error")
  expect_s3_class(cnd_str, "rlang_error")
  expect_equal(rlang::call_name(cnd_str$call), "wrapper_fn_str")
  expect_match(cnd_str$message, "Must provide either a valid `feature_id`")

  # When helper .parse_work_item fails inside az_work_item_get,
  # error call is attributed to caller frame (wrapper_fn2), not .parse_work_item
  wrapper_fn2 <- function() {
    az_work_item_get(123L, client = client)
  }
  with_mock_api(function(req) {
    mock_response(list(id = NULL))
  }, {
    cnd2 <- rlang::catch_cnd(wrapper_fn2(), classes = "error")
    expect_s3_class(cnd2, "rlang_error")
    expect_equal(rlang::call_name(cnd2$call), "wrapper_fn2")
  })

  # When az_work_items_get encounters malformed work item,
  # error call is attributed to caller frame (wrapper_fn3), bypassing purrr::map wrapper
  wrapper_fn3 <- function() {
    az_work_items_get(c(101L, 102L), client = client)
  }
  with_mock_api(function(req) {
    mock_response(list(value = list(list(id = 101L, fields = list()), list(id = NULL))))
  }, {
    cnd3 <- rlang::catch_cnd(wrapper_fn3(), classes = "error")
    expect_s3_class(cnd3, "rlang_error")
    expect_equal(rlang::call_name(cnd3$call), "wrapper_fn3")
  })

  # When az_my_work_items with resolve = TRUE encounters malformed work item response
  wrapper_fn4 <- function() {
    az_my_work_items(client = client)
  }
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      mock_response(list(queryType = "flat", workItems = list(list(id = 201L))))
    } else {
      mock_response(list(value = list(list(id = NULL))))
    }
  }, {
    cnd4 <- rlang::catch_cnd(wrapper_fn4(), classes = "error")
    expect_s3_class(cnd4, "rlang_error")
    expect_equal(rlang::call_name(cnd4$call), "wrapper_fn4")
  })

  # When az_feature_work_items with resolve = TRUE encounters malformed work item response
  wrapper_fn5 <- function() {
    az_feature_work_items(feature_id = 999L, client = client)
  }
  with_mock_api(function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      mock_response(list(queryType = "flat", workItems = list(list(id = 301L))))
    } else {
      mock_response(list(value = list(list(id = NULL))))
    }
  }, {
    cnd5 <- rlang::catch_cnd(wrapper_fn5(), classes = "error")
    expect_s3_class(cnd5, "rlang_error")
    expect_equal(rlang::call_name(cnd5$call), "wrapper_fn5")
  })
})
