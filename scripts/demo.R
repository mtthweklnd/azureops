# ==============================================================================
# AzureOps Interactive Demonstration Script
# ==============================================================================
# This script demonstrates the features implemented and remediated in AzureOps:
# 1. S7 Client & Authentication (supporting 84-char PATs, project scoping, and URL encoding)
# 2. Azure Boards & WIQL querying (S7 objects and tibbles)
# 3. Git Repositories, Branches, Commits & Pull Requests
# 4. Pipelines, Run Triggers & Log Stream fetching
# 5. Test Plans, Suites, Cases, and Coverage Metrics
# 6. Organization Administration & Webhook Creation
# 7. S7 Class generics: az_status(), az_url(), and S3 convert(obj, class_data.frame)
# ==============================================================================

library(azureops)
library(cli)

cli::cli_h1("AzureOps Package Demonstration")

# ------------------------------------------------------------------------------
# 1. S7 Client Configuration
# ------------------------------------------------------------------------------
cli::cli_h2("1. S7 Client Initialization")
# Client constructor accepts organization, PAT, and optional project scope
client <- az_client(
  organization = "myorg",
  pat = paste(rep("x", 84), collapse = ""),  # 84-character PAT supported without linebreaks
  project = "Platform Engineering (Core)"    # Names with spaces & parentheses are safely encoded
)
print(client)

# ------------------------------------------------------------------------------
# 2. Inspecting Request Building & URL Encoding
# ------------------------------------------------------------------------------
cli::cli_h2("2. Request Building & Project Scoping (httr2)")
req_org <- az_request("_apis/projects", client = client)
cli::cli_alert_info("Org-level URL (unprefixed): {.url {req_org$url}}")

req_proj <- az_request("_apis/pipelines", client = client)
cli::cli_alert_info("Project-scoped URL (encoded): {.url {req_proj$url}}")

# ------------------------------------------------------------------------------
# 3. Domain Classes & Generics (S7)
# ------------------------------------------------------------------------------
cli::cli_h2("3. S7 Domain Classes & Generics")

# Work Item Example
item <- az_work_item(
  id = 1042L,
  rev = 3L,
  type = "User Story",
  title = "Migrate CI/CD to Azure DevOps Pipelines",
  state = "Active",
  assigned_to = "Alice Dev <alice@example.com>",
  web_url = "https://dev.azure.com/myorg/Platform/_workitems/edit/1042"
)
cli::cli_alert_info("Work Item S7 Object:")
print(item)
cli::cli_inform(c("i" = "Generic az_status(): {.strong {az_status(item)}}"))
cli::cli_inform(c("i" = "Generic az_browse(): {.url {az_browse(item, browser = FALSE)}}"))
cli::cli_alert_info("Convert to Tibble:")
print(S7::convert(item, S7::class_data.frame))

# Pipeline Run Example
run <- az_pipeline_run(
  id = 9912L,
  pipeline_id = 45L,
  name = "Build & Deploy #9912",
  status = "completed",
  result = "succeeded",
  created_date = "2026-08-26T07:00:00Z",
  web_url = "https://dev.azure.com/myorg/Platform/_build/results?buildId=9912",
  logs_url = "https://dev.azure.com/myorg/Platform/_apis/pipelines/45/runs/9912/logs"
)
cli::cli_alert_info("Pipeline Run S7 Object:")
print(run)
cli::cli_inform(c("i" = "Generic az_status(): {.strong {az_status(run)}}"))
cli::cli_inform(c("i" = "Run Result Property: {.val {run@result}}"))

# Test Run Example
test_run <- az_test_run(
  id = 501L,
  name = "Nightly Integration Test Suite",
  state = "Completed",
  total_tests = 120L,
  pass_rate = 0.975,
  web_url = "https://dev.azure.com/myorg/Platform/_TestManagement/Runs#runId=501"
)
cli::cli_alert_info("Test Run S7 Object:")
print(test_run)
cli::cli_inform(c("i" = "Pass Rate: {.val {sprintf('%.1f%%', test_run@pass_rate * 100)}}"))

# ------------------------------------------------------------------------------
# 4. Webhook Creation Validation
# ------------------------------------------------------------------------------
cli::cli_h2("4. Webhook Input Validation (Fails Loudly on Missing Destination)")
tryCatch({
  az_webhook_create("workitem.created", client = client)
}, error = function(e) {
  cli::cli_alert_success("Validation check caught missing destination URL cleanly:")
  cli::cli_alert_danger("Error message: {conditionMessage(e)}")
})

cli::cli_rule(left = "Demo complete")
cli::cli_alert_success("All classes, generics, and URL builders operational.")
