# Request capture storage for test assertions
.captured_requests <- new.env(parent = emptyenv())
.captured_requests$stack <- list()

#' Reset captured requests
#' @noRd
reset_captured_requests <- function() {
  .captured_requests$stack <- list()
}

#' Retrieve last captured request
#' @noRd
last_request <- function() {
  reqs <- .captured_requests$stack
  if (length(reqs) == 0) return(NULL)
  reqs[[length(reqs)]]
}

#' Retrieve all captured requests in chronological order
#' @noRd
captured_requests <- function() {
  .captured_requests$stack
}

#' Create a mocked httr2_response object
#' @noRd
mock_response <- function(body = list(),
                          status_code = 200,
                          headers = list("content-type" = "application/json")) {
  if (is.null(body) || (status_code == 204 && length(body) == 0)) {
    raw_body <- raw(0)
  } else if (is.raw(body)) {
    raw_body <- body
  } else if (is.character(body) && length(body) == 1 && !is.null(headers[["content-type"]]) && grepl("text/plain", headers[["content-type"]])) {
    raw_body <- charToRaw(body)
  } else {
    raw_body <- charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"))
  }
  
  httr2::response(
    status_code = status_code,
    headers = headers,
    body = raw_body
  )
}

#' Helper to evaluate expression with mock responses and request recording
#' @noRd
with_mock_api <- function(handler, expr) {
  prior <- .captured_requests$stack
  .captured_requests$stack <- list()
  on.exit({
    .captured_requests$stack <- prior
  }, add = TRUE)
  
  mock_fun <- function(req) {
    .captured_requests$stack <<- c(.captured_requests$stack, list(req))
    if (is.function(handler)) {
      handler(req)
    } else if (inherits(handler, "httr2_response")) {
      handler
    } else if (is.list(handler) && !inherits(handler, "httr2_response")) {
      for (rule in handler) {
        if (is.function(rule$pattern) && rule$pattern(req)) {
          return(if (is.function(rule$response)) rule$response(req) else rule$response)
        }
        if (is.character(rule$pattern) && grepl(rule$pattern, req$url)) {
          return(if (is.function(rule$response)) rule$response(req) else rule$response)
        }
      }
      mock_response()
    } else {
      mock_response()
    }
  }
  
  httr2::with_mocked_responses(mock_fun, expr)
}
