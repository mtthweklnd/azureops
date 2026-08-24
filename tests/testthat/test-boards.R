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
  
  mock_handler <- function(req) {
    if (grepl("_apis/wit/workitems/123", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_item_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(value = list(mock_item_payload)), auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    item <- az_work_item_get(123L, client = client)
    expect_true(S7::S7_inherits(item, az_work_item))
    expect_equal(item@id, 123L)
    expect_equal(item@type, "Bug")
    expect_equal(item@title, "Database Connection Timeout")
    expect_equal(item@state, "Active")
    expect_equal(item@assigned_to, "Charlie Eng")
    expect_equal(item@web_url, "https://dev.azure.com/testorg/proj/_workitems/edit/123")
    
    # Batch get as tibble
    df <- az_work_items_get(c(123L), as_data_frame = TRUE, client = client)
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
  
  mock_handler <- function(req) {
    expect_equal(req$method, "POST")
    expect_equal(req$headers$`Content-Type`, "application/json-patch+json")
    httr2::response(
      status_code = 200,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_created_payload, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    item <- az_work_item_create(
      type = "User Story",
      title = "Implement OAuth",
      description = "Add Azure AD authentication",
      assigned_to = "dev@example.com",
      fields = list("Microsoft.VSTS.Common.Priority" = 1L),
      project = "MyProj",
      client = client
    )
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
  
  mock_handler <- function(req) {
    expect_equal(req$method, "PATCH")
    expect_equal(req$headers$`Content-Type`, "application/json-patch+json")
    httr2::response(
      status_code = 200,
      headers = list("content-type" = "application/json"),
      body = charToRaw(jsonlite::toJSON(mock_updated_payload, auto_unbox = TRUE))
    )
  }
  
  httr2::with_mocked_responses(mock_handler, {
    res <- az_work_item_update(456L, fields = list("System.State" = "Closed"), client = client)
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
  
  mock_handler <- function(req) {
    if (grepl("_apis/wit/wiql", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_wiql_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(list(value = list(mock_item_payload)), auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    items <- az_wiql_query("SELECT [System.Id] FROM WorkItems", client = client)
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
  
  mock_handler <- function(req) {
    if (grepl("/capacities", req$url)) {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_capacity_payload, auto_unbox = TRUE))
      )
    } else {
      httr2::response(
        status_code = 200,
        headers = list("content-type" = "application/json"),
        body = charToRaw(jsonlite::toJSON(mock_iterations_payload, auto_unbox = TRUE))
      )
    }
  }
  
  httr2::with_mocked_responses(mock_handler, {
    iterations <- az_iterations_list(project = "Proj", team = "TeamA", client = client)
    expect_s3_class(iterations, "tbl_df")
    expect_equal(nrow(iterations), 1)
    expect_equal(iterations$name, "Sprint 1")
    expect_equal(iterations$start_date, "2026-08-01T00:00:00Z")
    
    capacities <- az_sprint_capacity_get("sprint-1-guid", team = "TeamA", project = "Proj", client = client)
    expect_s3_class(capacities, "tbl_df")
    expect_equal(nrow(capacities), 1)
    expect_equal(capacities$display_name, "Alice Dev")
    expect_equal(capacities$total_capacity, 8) # 6 + 2
  })
})
