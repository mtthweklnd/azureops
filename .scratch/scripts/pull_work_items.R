#!/usr/bin/env Rscript

# ==============================================================================
# Azure DevOps - Pull "Active" and "New" Work Items for a User (S7 OOP)
# ==============================================================================
#
# Environment variables used:
#   - AZURE_DEVOPS_ORG     (or AZURE_ORG)     : Azure DevOps Organization
#   - AZURE_DEVOPS_PROJECT (or AZURE_PROJECT) : Azure DevOps Project Name
#   - AZURE_DEVOPS_PAT     (or AZURE_PAT)     : Personal Access Token (PAT)
#   - AZURE_DEVOPS_USER    (or AZURE_USER)    : Optional target user (if not passed as CLI arg)
#
# Usage:
#   Rscript scripts/pull_work_items.R "user@example.com"
#   Rscript scripts/pull_work_items.R "Jane Doe"
#   Rscript scripts/pull_work_items.R            # Uses AZURE_DEVOPS_USER env var
#
# ==============================================================================

suppressPackageStartupMessages({
  if (!requireNamespace("S7", quietly = TRUE)) {
    stop("Package 'S7' is required. Install with install.packages('S7')", call. = FALSE)
  }
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("Package 'httr2' is required. Install with install.packages('httr2')", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Install with install.packages('jsonlite')", call. = FALSE)
  }
  if (!requireNamespace("tibble", quietly = TRUE)) {
    stop("Package 'tibble' is required. Install with install.packages('tibble')", call. = FALSE)
  }
})

library(S7)

# ------------------------------------------------------------------------------
# 1. Package Integration or Standalone S7 Class Definitions
# ------------------------------------------------------------------------------

# Try loading the local azureops package if available
suppressWarnings(suppressMessages({
  if (!requireNamespace("azureops", quietly = TRUE)) {
    if (file.exists("DESCRIPTION") && requireNamespace("pkgload", quietly = TRUE)) {
      tryCatch(pkgload::load_all(".", quiet = TRUE), error = function(e) NULL)
    }
  }
}))

# If azureops is loaded, use its S7 classes and generics; otherwise define them standalone
if (requireNamespace("azureops", quietly = TRUE) && exists("az_client", asNamespace("azureops"))) {
  az_client    <- azureops::az_client
  az_work_item <- azureops::az_work_item
  az_status    <- azureops::az_status
} else {
  # Formal S7 Class: az_client
  az_client <- S7::new_class(
    name = "az_client",
    package = "azureops",
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
        "@pat must be a non-empty Personal Access Token string"
      } else {
        NULL
      }
    }
  )

  # Formal S7 Class: az_work_item
  az_work_item <- S7::new_class(
    name = "az_work_item",
    package = "azureops",
    properties = list(
      id          = S7::class_integer,
      rev         = S7::new_property(S7::class_integer, default = 1L),
      type        = S7::new_property(S7::class_character, default = ""),
      title       = S7::new_property(S7::class_character, default = ""),
      state       = S7::new_property(S7::class_character, default = ""),
      assigned_to = S7::new_property(S7::class_character, default = ""),
      url         = S7::new_property(S7::class_character, default = ""),
      web_url     = S7::new_property(S7::class_character, default = ""),
      fields      = S7::new_property(S7::class_list, default = list())
    )
  )

  # S7 Generic: az_status
  az_status <- S7::new_generic("az_status", "x")

  # S7 Method: az_status for az_work_item
  S7::method(az_status, az_work_item) <- function(x, ...) {
    cat(sprintf("Work Item #%d [%s] \"%s\": %s\n", x@id, x@type, x@title, x@state))
    invisible(x@state)
  }

  # S7 Coercion Method: az_work_item -> data.frame / tibble
  S7::method(S7::convert, list(az_work_item, S7::class_data.frame)) <- function(from, to) {
    tibble::tibble(
      id          = from@id,
      rev         = from@rev,
      type        = from@type,
      title       = from@title,
      state       = from@state,
      assigned_to = from@assigned_to,
      url         = from@url,
      web_url     = from@web_url
    )
  }
}

# ------------------------------------------------------------------------------
# 2. Helper Functions & S7 API Client Pipeline
# ------------------------------------------------------------------------------

`%||%` <- function(a, b) if (!is.null(a) && nzchar(as.character(a))) a else b

escape_wiql <- function(str) {
  gsub("'", "''", str, fixed = TRUE)
}

parse_work_item_s7 <- function(item, org, project) {
  fields <- item[["fields"]] %||% list()
  assigned <- fields[["System.AssignedTo"]]
  assigned_name <- if (is.list(assigned)) {
    assigned[["displayName"]] %||% assigned[["uniqueName"]] %||% ""
  } else if (is.character(assigned)) {
    assigned
  } else {
    ""
  }
  
  html_url <- item[["_links"]][["html"]][["href"]] %||% 
    sprintf("https://dev.azure.com/%s/%s/_workitems/edit/%s", org, project, item[["id"]])

  az_work_item(
    id          = as.integer(item[["id"]] %||% 0L),
    rev         = as.integer(item[["rev"]] %||% 1L),
    type        = as.character(fields[["System.WorkItemType"]] %||% ""),
    title       = as.character(fields[["System.Title"]] %||% ""),
    state       = as.character(fields[["System.State"]] %||% ""),
    assigned_to = as.character(assigned_name),
    url         = as.character(item[["url"]] %||% ""),
    web_url     = as.character(html_url),
    fields      = fields
  )
}

#' Pull "Active" and "New" Work Items for a User using S7
#'
#' @param client An S7 `az_client` object.
#' @param user Character string specifying the target user's display name or email.
#' @param states Character vector of work item states (default: `c("Active", "New")`).
#' @param as_data_frame Logical; whether to convert the result to a `tibble` (default: `FALSE`).
#' @return A list of S7 `az_work_item` objects or a `tibble`.
pull_work_items <- function(client,
                            user,
                            states = c("Active", "New"),
                            as_data_frame = FALSE) {
  if (!S7::S7_inherits(client, az_client)) {
    stop("'client' must be an S7 'az_client' object.", call. = FALSE)
  }
  if (!nzchar(user)) {
    stop("'user' must be a non-empty character string.", call. = FALSE)
  }

  org     <- client@organization
  project <- client@project
  pat     <- client@pat
  api_ver <- client@api_version
  base_url<- client@base_url

  auth_hdr <- paste0("Basic ", trimws(jsonlite::base64_enc(paste0(":", pat))))
  
  # Format states and escape WIQL parameters
  formatted_states <- paste(sprintf("'%s'", escape_wiql(states)), collapse = ", ")
  escaped_user     <- escape_wiql(user)
  
  # Project filter in WIQL if project is configured
  project_clause <- if (nzchar(project)) {
    sprintf("[System.TeamProject] = '%s' AND ", escape_wiql(project))
  } else {
    ""
  }

  wiql <- sprintf(
    "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.AssignedTo], [System.ChangedDate]
     FROM WorkItems
     WHERE %s[System.State] IN (%s)
       AND [System.AssignedTo] CONTAINS '%s'
     ORDER BY [System.ChangedDate] DESC",
    project_clause,
    formatted_states,
    escaped_user
  )

  # Step 1: Execute WIQL Query
  wiql_endpoint <- if (nzchar(project)) {
    sprintf("%s/%s/%s/_apis/wit/wiql", base_url, utils::URLencode(org), utils::URLencode(project))
  } else {
    sprintf("%s/%s/_apis/wit/wiql", base_url, utils::URLencode(org))
  }

  wiql_req <- httr2::request(wiql_endpoint) |>
    httr2::req_headers(
      Authorization  = auth_hdr,
      `Content-Type` = "application/json"
    ) |>
    httr2::req_url_query(`api-version` = api_ver) |>
    httr2::req_body_json(list(query = wiql)) |>
    httr2::req_user_agent("azureops-s7-script")

  wiql_resp <- httr2::req_perform(wiql_req)
  wiql_data <- httr2::resp_body_json(wiql_resp)

  work_items_ref <- wiql_data$workItems
  if (is.null(work_items_ref) || length(work_items_ref) == 0) {
    return(if (as_data_frame) tibble::tibble() else list())
  }

  ids <- vapply(work_items_ref, function(x) as.integer(x$id %||% 0L), integer(1))
  ids <- ids[ids > 0]

  # Step 2: Fetch Work Item Details in Batches (max 200 items per call)
  chunk_size <- 200
  id_chunks  <- split(ids, ceiling(seq_along(ids) / chunk_size))
  raw_items  <- list()

  for (chunk in id_chunks) {
    items_endpoint <- if (nzchar(project)) {
      sprintf("%s/%s/%s/_apis/wit/workitems", base_url, utils::URLencode(org), utils::URLencode(project))
    } else {
      sprintf("%s/%s/_apis/wit/workitems", base_url, utils::URLencode(org))
    }

    items_req <- httr2::request(items_endpoint) |>
      httr2::req_headers(Authorization = auth_hdr) |>
      httr2::req_url_query(
        ids           = paste(chunk, collapse = ","),
        `$expand`     = "fields",
        `api-version` = api_ver
      ) |>
      httr2::req_user_agent("azureops-s7-script")

    items_resp <- httr2::req_perform(items_req)
    items_data <- httr2::resp_body_json(items_resp)
    raw_items  <- c(raw_items, items_data$value)
  }

  # Step 3: Instantiate S7 az_work_item objects
  parsed_s7 <- lapply(raw_items, parse_work_item_s7, org = org, project = project)

  if (as_data_frame) {
    do.call(rbind, lapply(parsed_s7, function(item) S7::convert(item, S7::class_data.frame)))
  } else {
    parsed_s7
  }
}

# ------------------------------------------------------------------------------
# 3. CLI Execution & Environment Resolution
# ------------------------------------------------------------------------------

get_env_var <- function(keys, required = TRUE, name = NULL) {
  for (k in keys) {
    val <- Sys.getenv(k, unset = "")
    if (nzchar(val)) return(val)
  }
  if (required) {
    var_names <- paste(keys, collapse = " or ")
    stop(sprintf("Missing required environment variable: %s (%s)", var_names, name %||% "required parameter"), call. = FALSE)
  }
  ""
}

# Resolve Configuration
env_org     <- get_env_var(c("AZURE_DEVOPS_ORG", "AZURE_ORG"), required = TRUE, name = "Organization")
env_project <- get_env_var(c("AZURE_DEVOPS_PROJECT", "AZURE_PROJECT"), required = TRUE, name = "Project")
env_pat     <- get_env_var(c("AZURE_DEVOPS_PAT", "AZURE_PAT", "AZURE_DEVOPS_KEY"), required = TRUE, name = "Personal Access Token")

# Resolve Target User
args <- commandArgs(trailingOnly = TRUE)
target_user <- if (length(args) >= 1 && nzchar(args[1])) {
  args[1]
} else {
  get_env_var(c("AZURE_DEVOPS_USER", "AZURE_USER"), required = FALSE)
}

if (!nzchar(target_user)) {
  stop(
    "Target user not specified.\n",
    "Provide the user name or email as a command-line argument:\n",
    "  Rscript scripts/pull_work_items.R \"jane.doe@example.com\"\n",
    "or set the AZURE_DEVOPS_USER environment variable.",
    call. = FALSE
  )
}

# Instantiate S7 Client Object
client <- az_client(
  organization = env_org,
  pat          = env_pat,
  project      = env_project
)

cat(sprintf("\n=== Azure DevOps Work Items Query (S7 OOP) ===\n"))
cat(sprintf("Client Org   : %s\n", client@organization))
cat(sprintf("Client Proj  : %s\n", client@project))
cat(sprintf("Assigned To  : %s\n", target_user))
cat(sprintf("Target States: Active, New\n\n"))

tryCatch({
  # Pull S7 az_work_item objects
  work_items <- pull_work_items(client, user = target_user)

  if (length(work_items) == 0) {
    cat("No 'Active' or 'New' work items found for user '", target_user, "'.\n\n", sep = "")
  } else {
    cat(sprintf("Found %d matching S7 work item(s):\n\n", length(work_items)))

    for (item in work_items) {
      cat(sprintf("<S7 az_work_item #%d> [%s]\n", item@id, item@type))
      cat(sprintf("  Title       : %s\n", item@title))
      cat(sprintf("  State       : %s\n", item@state))
      cat(sprintf("  Assigned To : %s\n", item@assigned_to))
      cat(sprintf("  Web URL     : %s\n\n", item@web_url))
    }
  }

  invisible(work_items)
}, error = function(e) {
  cat(sprintf("Error querying Azure DevOps: %s\n\n", conditionMessage(e)), file = stderr())
  quit(status = 1, save = "no")
})
