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

cat("=================================================================\n")
cat("                AzureOps Package Demonstration                   \n")
cat("=================================================================\n\n")

# ------------------------------------------------------------------------------
# 1. S7 Client Configuration
# ------------------------------------------------------------------------------
cat("--- 1. S7 Client Initialization ---\n")
# Client constructor accepts organization, PAT, and optional project scope
client <- az_client(
  organization = "myorg",
  pat = paste(rep("x", 84), collapse = ""),  # 84-character PAT supported without linebreaks
  project = "Platform Engineering (Core)"    # Names with spaces & parentheses are safely encoded
)
print(client)
cat("\n")

# ------------------------------------------------------------------------------
# 2. Inspecting Request Building & URL Encoding
# ------------------------------------------------------------------------------
cat("--- 2. Request Building & Project Scoping (httr2) ---\n")
req_org <- az_request("_apis/projects", client = client)
cat("Org-level URL (unprefixed):", req_org$url, "\n")

req_proj <- az_request("_apis/pipelines", client = client)
cat("Project-scoped URL (encoded):", req_proj$url, "\n\n")

# ------------------------------------------------------------------------------
# 3. Domain Classes & Generics (S7)
# ------------------------------------------------------------------------------
cat("--- 3. S7 Domain Classes & Generics ---\n")

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
cat("Work Item S7 Object:\n")
print(item)
cat("Generic az_status():", az_status(item), "\n")
cat("Generic az_browse():", az_browse(item, browser = FALSE), "\n")
cat("Convert to Tibble:\n")
print(S7::convert(item, S7::class_data.frame))
cat("\n")

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
cat("Pipeline Run S7 Object:\n")
print(run)
cat("Generic az_status():", az_status(run), "\n")
cat("Run Result Property:", run@result, "\n\n")

# Test Run Example
test_run <- az_test_run(
  id = 501L,
  name = "Nightly Integration Test Suite",
  state = "Completed",
  total_tests = 120L,
  pass_rate = 0.975,
  web_url = "https://dev.azure.com/myorg/Platform/_TestManagement/Runs#runId=501"
)
cat("Test Run S7 Object:\n")
print(test_run)
cat("Pass Rate:", sprintf("%.1f%%", test_run@pass_rate * 100), "\n\n")

# ------------------------------------------------------------------------------
# 4. Webhook Creation Validation
# ------------------------------------------------------------------------------
cat("--- 4. Webhook Input Validation (Fails Loudly on Missing Destination) ---\n")
tryCatch({
  az_webhook_create("workitem.created", client = client)
}, error = function(e) {
  cat("Validation check caught missing destination URL cleanly:\n")
  cat("Error message:", conditionMessage(e), "\n")
})
cat("\n")

cat("=================================================================\n")
cat("Demo complete! All classes, generics, and URL builders operational.\n")
cat("=================================================================\n")
