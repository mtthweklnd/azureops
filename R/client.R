#' @include classes.R auth.R
NULL

#' Resolve Client Object or Credentials
#'
#' Internal helper to resolve an S7 `az_client` instance from explicitly supplied
#' client or individual parameters/environment variables.
#'
#' @noRd
az_resolve_client <- function(client = NULL, organization = NULL, pat = NULL, project = NULL) {
  if (!is.null(client) && S7::S7_inherits(client, az_client)) {
    if (!is.null(project) && nzchar(project) && !nzchar(client@project)) {
      client@project <- project
    }
    return(client)
  }
  az_client(organization = organization, pat = pat, project = project)
}

#' Parse Azure DevOps API Error Body
#'
#' Extracts descriptive error messages from Azure DevOps JSON error responses.
#'
#' @param resp An `httr2_response` object.
#' @return A character string explaining the error.
#' @noRd
az_error_body <- function(resp) {
  content_type <- httr2::resp_content_type(resp)
  if (grepl("json", content_type, ignore.case = TRUE)) {
    tryCatch({
      body <- httr2::resp_body_json(resp)
      if (!is.null(body$message)) {
        return(body$message)
      }
      if (!is.null(body$value$message)) {
        return(body$value$message)
      }
      if (!is.null(body$error$message)) {
        return(body$error$message)
      }
    }, error = function(e) NULL)
  }
  if (httr2::resp_has_body(resp)) {
    httr2::resp_body_string(resp)
  } else {
    NULL
  }
}

#' Construct an Azure DevOps HTTP Request
#'
#' Builds an `httr2` request configured with authentication, API version,
#' and Azure DevOps error handling.
#'
#' @param endpoint Relative or absolute API path (e.g., `"_apis/projects"`).
#' @param client An `az_client` S7 object. If `NULL`, created from environment.
#' @param project Project scope (optional).
#' @param query Named list of additional query parameters.
#' @param api_version API version string (defaults to client version or `"7.0"`).
#' @param base_url Custom base URL for specialized services (e.g., `vssps.dev.azure.com`).
#' @return An `httr2_request` object.
#' @export
az_request <- function(endpoint,
                       client = NULL,
                       project = NULL,
                       query = list(),
                       api_version = NULL,
                       base_url = NULL) {
  cli_obj <- az_resolve_client(client, project = project)
  
  api_ver <- api_version %||% cli_obj@api_version
  host <- base_url %||% cli_obj@base_url
  
  # Check if endpoint is already a full URL
  if (grepl("^https?://", endpoint)) {
    url <- endpoint
  } else {
    # Remove leading slash
    clean_endpoint <- sub("^/", "", endpoint)
    org_enc <- utils::URLencode(as.character(cli_obj@organization), reserved = TRUE)
    
    # Check if project should be inserted into path
    proj <- if (!is.null(project) && nzchar(project)) {
      project
    } else if (nzchar(cli_obj@project)) {
      cli_obj@project
    } else {
      NULL
    }
    
    # Endpoints that are genuinely organisation-level must remain unprefixed
    is_org_level <- grepl("^_apis/(projects|teams|hooks|graph|userentitlements)", clean_endpoint)
    
    if (!is.null(proj) && nzchar(proj) && !is_org_level) {
      proj_enc <- utils::URLencode(as.character(proj), reserved = TRUE)
      
      # Literal comparison to check if project is already prefixed
      if (startsWith(clean_endpoint, paste0(proj, "/"))) {
        remainder <- substring(clean_endpoint, nchar(proj) + 2)
        url <- sprintf("%s/%s/%s/%s", host, org_enc, proj_enc, remainder)
      } else if (startsWith(clean_endpoint, paste0(proj_enc, "/"))) {
        remainder <- substring(clean_endpoint, nchar(proj_enc) + 2)
        url <- sprintf("%s/%s/%s/%s", host, org_enc, proj_enc, remainder)
      } else {
        url <- sprintf("%s/%s/%s/%s", host, org_enc, proj_enc, clean_endpoint)
      }
    } else {
      url <- sprintf("%s/%s/%s", host, org_enc, clean_endpoint)
    }
  }

  req <- httr2::request(url) |>
    httr2::req_auth_basic(username = "", password = cli_obj@pat) |>
    httr2::req_user_agent("azureops R package (httr2)") |>
    httr2::req_error(body = az_error_body)

  # Add api-version query param if not already present in url
  if (!grepl("api-version=", url)) {
    req <- httr2::req_url_query(req, `api-version` = api_ver)
  }

  # Add additional query params if provided
  if (length(query) > 0) {
    req <- do.call(httr2::req_url_query, c(list(req), query))
  }

  req
}

#' Perform Request and Parse Response
#'
#' Executes an `httr2` request and parses the JSON response body.
#'
#' @param req An `httr2_request` object.
#' @param simplifyVector Logical; whether to simplify JSON to vectors/data frames.
#' @return Parsed JSON object (list or data.frame), or `NULL` if empty.
#' @export
az_perform <- function(req, simplifyVector = FALSE) {
  resp <- httr2::req_perform(req)
  
  # Status 204 No Content or empty response body
  if (httr2::resp_status(resp) == 204 || !httr2::resp_has_body(resp)) {
    return(invisible(NULL))
  }
  
  body_text <- httr2::resp_body_string(resp)
  if (!nzchar(body_text)) {
    return(invisible(NULL))
  }
  
  jsonlite::fromJSON(body_text, simplifyVector = simplifyVector)
}
