# ==============================================================================
# Azure Boards Minimum Viable Demo with S7 & httr2
# ==============================================================================
# Modern packages used:
#   - S7: Modern OOP (classes, properties, validation, generics, coercion)
#   - httr2: Modern, pipeable HTTP client with basic auth & error handling
#   - purrr & tibble: Functional iteration and tidy data conversion
#   - cli & rlang: Rich console formatting and standard error signaling
# ==============================================================================

suppressPackageStartupMessages({
  library(S7)
  library(httr2)
  library(purrr)
  library(tibble)
  library(cli)
  library(rlang)
})

cli::cli_h1("Azure Boards API + S7 Object System Demo")

# ==============================================================================
# 1. S7 CLASS DEFINITIONS
# ==============================================================================
cli::cli_h2("1. S7 Class Definitions & Validators")

# 1.1 S7 Client Class with typed properties and custom validator
az_client <- S7::new_class(
  name = "az_client",
  properties = list(
    organization = S7::class_character,
    pat          = S7::class_character,
    project      = S7::new_property(S7::class_character, default = ""),
    base_url     = S7::new_property(S7::class_character, default = "https://dev.azure.com"),
    api_version  = S7::new_property(S7::class_character, default = "7.0")
  ),
  validator = function(self) {
    if (length(self@organization) != 1L || !nzchar(self@organization)) {
      "@organization must be a non-empty character string"
    } else if (length(self@pat) != 1L || !nzchar(self@pat)) {
      "@pat must be a non-empty Personal Access Token"
    } else {
      NULL
    }
  }
)

# 1.2 S7 Work Item Class representing Azure Boards resources
az_work_item <- S7::new_class(
  name = "az_work_item",
  properties = list(
    id          = S7::class_integer,
    rev         = S7::new_property(S7::class_integer, default = 1L),
    type        = S7::new_property(S7::class_character, default = "Task"),
    title       = S7::new_property(S7::class_character, default = ""),
    description = S7::new_property(S7::class_character, default = ""),
    state       = S7::new_property(S7::class_character, default = "New"),
    assigned_to = S7::new_property(S7::class_character, default = ""),
    web_url     = S7::new_property(S7::class_character, default = ""),
    fields      = S7::new_property(S7::class_list, default = list())
  ),
  validator = function(self) {
    if (length(self@id) != 1L || self@id <= 0L) {
      "@id must be a positive integer"
    } else {
      NULL
    }
  }
)

# ==============================================================================
# 2. S7 GENERICS, METHODS, AND CONVERSION (COERCION)
# ==============================================================================
cli::cli_h2("2. S7 Generics, Methods, & Tibble Coercion")

# 2.1 S7 Polymorphic Generic
az_status <- S7::new_generic("az_status", "x")

# 2.2 S7 Method for az_work_item
S7::method(az_status, az_work_item) <- function(x, ...) {
  icon <- if (tolower(x@state) %in% c("closed", "completed", "done", "resolved")) "v" else "i"
  msg <- setNames(
    sprintf("Work Item #%d [%s] \"%s\": {.strong %s}", x@id, x@type, x@title, x@state),
    icon
  )
  cli::cli_inform(msg)
  invisible(x@state)
}

# 2.3 S7 Pretty Printing via base::format method (with description preview)
S7::method(format, az_work_item) <- function(x, ...) {
  # Clean HTML tags and excessive whitespace for preview
  desc_clean <- gsub("<[^>]+>", " ", x@description)
  desc_clean <- trimws(gsub("\\s+", " ", desc_clean))
  desc_preview <- if (nzchar(desc_clean)) {
    if (nchar(desc_clean) > 60) paste0(substr(desc_clean, 1, 57), "...") else desc_clean
  } else {
    "<none>"
  }

  cli::cli_format_method({
    cli::cli_h3(sprintf("<Azure DevOps Work Item #%d [%s]>", x@id, x@type))
    cli::cli_dl(c(
      "Title"       = x@title,
      "Description" = desc_preview,
      "State"       = x@state,
      "Assigned To" = if (nzchar(x@assigned_to)) x@assigned_to else "<unassigned>",
      "Revision"    = as.character(x@rev),
      "Web URL"     = if (nzchar(x@web_url)) x@web_url else "<none>"
    ))
  })
}

S7::method(print, az_work_item) <- function(x, ...) {
  cli::cat_line(format(x, ...))
  invisible(x)
}

# 2.4 S7 Coercion to Tibble / data.frame
S7::method(convert, list(az_work_item, S7::class_data.frame)) <- function(from, to) {
  tibble::tibble(
    id          = from@id,
    rev         = from@rev,
    type        = from@type,
    title       = from@title,
    description = from@description,
    state       = from@state,
    assigned_to = from@assigned_to,
    web_url     = from@web_url
  )
}

# ==============================================================================
# 3. SCOPED HTTP API LAYER (httr2)
# ==============================================================================
cli::cli_h2("3. Concise httr2 API Functions")

# 3.1 Build httr2 request using az_client
az_request <- function(endpoint, client, query = list(), project = NULL) {
  proj <- if (!is.null(project) && nzchar(project)) project else client@project
  
  clean_ep <- sub("^/", "", endpoint)
  org_enc  <- utils::URLencode(client@organization, reserved = TRUE)
  
  url <- if (nzchar(proj)) {
    proj_enc <- utils::URLencode(proj, reserved = TRUE)
    sprintf("%s/%s/%s/%s", client@base_url, org_enc, proj_enc, clean_ep)
  } else {
    sprintf("%s/%s/%s", client@base_url, org_enc, clean_ep)
  }
  
  req <- httr2::request(url) |>
    httr2::req_auth_basic(username = "", password = client@pat) |>
    httr2::req_url_query(`api-version` = client@api_version) |>
    httr2::req_user_agent("AzureOps-Boards-Demo/1.0 (httr2; S7)")
  
  if (length(query) > 0) {
    req <- do.call(httr2::req_url_query, c(list(req), query))
  }
  req
}

# 3.2 Perform request and parse JSON
az_perform <- function(req) {
  resp <- httr2::req_perform(req)
  if (httr2::resp_status(resp) == 204 || !httr2::resp_has_body(resp)) return(NULL)
  jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE)
}

# 3.3 Parser from JSON payload to S7 az_work_item
parse_work_item <- function(item) {
  fields <- purrr::pluck(item, "fields", .default = list())
  
  az_work_item(
    id          = as.integer(purrr::pluck(item, "id", .default = 0L)),
    rev         = as.integer(purrr::pluck(item, "rev", .default = 1L)),
    type        = as.character(purrr::pluck(fields, "System.WorkItemType", .default = "Task")),
    title       = as.character(purrr::pluck(fields, "System.Title", .default = "")),
    description = as.character(purrr::pluck(fields, "System.Description", .default = purrr::pluck(fields, "Microsoft.VSTS.TCM.ReproSteps", .default = ""))),
    state       = as.character(purrr::pluck(fields, "System.State", .default = "New")),
    assigned_to = as.character(purrr::pluck(fields, "System.AssignedTo", "displayName", .default = "")),
    web_url     = as.character(purrr::pluck(item, "_links", "html", "href", .default = "")),
    fields      = fields
  )
}

# 3.4 Get single work item
az_work_item_get <- function(id, client) {
  req <- az_request(sprintf("_apis/wit/workitems/%d", as.integer(id)), client = client)
  res <- az_perform(req)
  parse_work_item(res)
}

# 3.5 Query Work Items via WIQL
az_wiql_query <- function(query, client, as_data_frame = FALSE) {
  req <- az_request("_apis/wit/wiql", client = client) |>
    httr2::req_method("POST") |>
    httr2::req_headers(`Content-Type` = "application/json") |>
    httr2::req_body_json(list(query = query))
  
  res <- az_perform(req)
  refs <- purrr::pluck(res, "workItems", .default = list())
  ids <- purrr::map_int(refs, ~ as.integer(.x$id))
  
  if (length(ids) == 0) {
    return(if (as_data_frame) tibble::tibble() else list())
  }
  
  # Fetch full item details in batch
  req_batch <- az_request(
    "_apis/wit/workitems",
    client = client,
    query = list(ids = paste(ids, collapse = ","))
  )
  batch_res <- az_perform(req_batch)
  items_json <- purrr::pluck(batch_res, "value", .default = list())
  items_s7 <- lapply(items_json, parse_work_item)
  
  if (as_data_frame) {
    purrr::map_dfr(items_s7, ~ S7::convert(.x, S7::class_data.frame))
  } else {
    items_s7
  }
}

# 3.6 Create a Work Item via JSON Patch
az_work_item_create <- function(type, title, description = NULL, client = NULL) {
  patch <- list(
    list(op = "add", path = "/fields/System.Title", value = title)
  )
  if (!is.null(description) && nzchar(description)) {
    patch <- c(patch, list(list(op = "add", path = "/fields/System.Description", value = description)))
  }
  
  endpoint <- sprintf("_apis/wit/workitems/$%s", utils::URLencode(type, reserved = TRUE))
  
  req <- az_request(endpoint, client = client) |>
    httr2::req_method("POST") |>
    httr2::req_headers(`Content-Type` = "application/json-patch+json") |>
    httr2::req_body_json(patch)
  
  res <- az_perform(req)
  parse_work_item(res)
}

# ==============================================================================
# 4. INTERACTIVE DEMONSTRATION WALKTHROUGH
# ==============================================================================
cli::cli_h2("4. Interactive Demonstration")

# --- Step A: Client Initialization & Validation Check ---
cli::cli_h3("Step A: Creating & Validating S7 Client")
client <- az_client(
  organization = "myorg",
  pat          = Sys.getenv("AZURE_DEVOPS_PAT", "demo_pat_token_value_12345"),
  project      = "Core Platform"
)
cli::cli_alert_success("Client successfully initialized with S7 validation.")
cli::cli_inform(c("i" = "Organization: {.val {client@organization}}", "i" = "Project: {.val {client@project}}"))

# Validate that bad S7 instantiation is prevented
tryCatch({
  az_client(organization = "", pat = "test")
}, error = function(e) {
  cli::cli_alert_info("S7 Validator proactively stopped invalid client: {.emph {conditionMessage(e)}}")
})

# --- Step B: S7 Work Item Instantiation & Inspection ---
cli::cli_h3("Step B: Instantiating S7 az_work_item object (with description preview)")
demo_item <- az_work_item(
  id          = 1054L,
  rev         = 2L,
  type        = "Bug",
  title       = "Fix memory leak during background sync",
  description = "<p>Observed continuous heap allocation increase during large batch iterations over 5000+ work items. Repro steps: 1. Start worker thread, 2. Run sync pipeline.</p>",
  state       = "Active",
  assigned_to = "Jane Engineer <jane@example.com>",
  web_url     = "https://dev.azure.com/myorg/Core%20Platform/_workitems/edit/1054"
)

# Custom S7 print method (shows truncated preview of description)
print(demo_item)

# Direct access to full description property
cli::cli_alert_info("Full Description via property: {.val {demo_item@description}}")

# --- Step C: S7 Polymorphic Generic Dispatch ---
cli::cli_h3("Step C: S7 Generic Function Dispatch (az_status)")
az_status(demo_item)

# --- Step D: S7 Conversion to Tidy Tibble ---
cli::cli_h3("Step D: S7 Coercion to Tibble (S7::convert)")
item_df <- S7::convert(demo_item, S7::class_data.frame)
print(item_df)

# --- Step E: httr2 Request Pipeline Preview ---
cli::cli_h3("Step E: httr2 WIQL Request Generation")
wiql <- "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
demo_req <- az_request("_apis/wit/wiql", client = client) |>
  httr2::req_method("POST") |>
  httr2::req_headers(`Content-Type` = "application/json") |>
  httr2::req_body_json(list(query = wiql))

cli::cli_alert_info("Prepared httr2 Request URL: {.url {demo_req$url}}")
cli::cli_alert_info("Request Method: {.val {demo_req$method}}")

cli::cli_rule(left = "Demo Complete")
cli::cli_alert_success("Minimum viable Azure Boards + S7 workflow ready to present!")
