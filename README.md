# azureops <img src="man/figures/logo.png" align="right" height="139" alt="" />

<!-- badges: start -->
<!-- badges: end -->

`azureops` is a modern R package for programmatically querying resources and triggering automated workflows in **Azure DevOps** using the Azure DevOps REST API (v7.0/v7.1), built on top of `{httr2}` and `{S7}`.

## Features

- 🔒 **Secure Credentials & OOP**: Powered by `{S7}` formal classes (`az_client`, `az_work_item`, `az_pipeline_run`, `az_pull_request`, etc.) with automatic Personal Access Token (PAT) masking.
- ⚡ **HTTP Client (`httr2`)**: Resilient request pipeline with custom error parsing and JSON-patch support.
- 🎯 **Polymorphic Generics**:
  - `az_status()`: Inspect status across pipelines, PRs, work items, and test runs.
  - `az_browse()`: Instant jump to web UI pages in browser.
  - `az_logs()`: Retrieve run logs seamlessly.
  - `convert(x, class_data.frame)`: Seamless coercion to `tibble` data frames.
- 🛠️ **Full Service Coverage**:
  - **Azure Boards**: Work items, WIQL queries, sprint iterations, capacity.
  - **Azure Repos**: Git repositories, branches, commits, pull requests & reviewers.
  - **Azure Pipelines**: Pipeline definitions, run triggering with runtime parameters, execution logs.
  - **Azure Test Plans**: Test plans, test suites, test cases, test run metrics, code coverage.
  - **Administration**: Projects, teams, security groups, entitlements, webhooks.

## Installation

```r
# Install development version
# devtools::install_github("org/azureops")
```

## Quick Start

### 1. Configure Authentication

Set your environment variables in `.Renviron`:

```env
AZURE_DEVOPS_ORG="myorganization"
AZURE_DEVOPS_PAT="your_personal_access_token"
AZURE_DEVOPS_PROJECT="MyProject"
```

Or instantiate a client explicitly:

```r
library(azureops)

client <- az_client(
  organization = "myorganization",
  pat = "secret_pat_value",
  project = "MyProject"
)
```

### 2. Azure Boards & WIQL

```r
# Query work items using WIQL
bugs <- az_wiql_query(
  "SELECT [System.Id], [System.Title] FROM WorkItems WHERE [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
)

# Inspect status of first item
az_status(bugs[[1]])

# Convert collection to a tidy tibble
az_work_items_get(c(101, 102, 103), as_data_frame = TRUE)
```

### 3. Azure Repos & Pull Requests

```r
# List active pull requests
prs <- az_pull_requests_list(status = "active")

# Create a new PR
pr <- az_pull_request_create(
  repository_id = "backend-service",
  title = "Feature: Add OAuth2 Authentication",
  source_branch = "feature/oauth",
  target_branch = "main"
)

# Open in browser
az_browse(pr)
```

### 4. Azure Pipelines Automation

```r
# Trigger an automated pipeline run with custom parameters
run <- az_pipeline_run_trigger(
  pipeline_id = 42,
  branch = "feature/oauth",
  template_parameters = list(deployEnv = "staging")
)

# Check status
az_status(run)

# Retrieve execution logs
logs <- az_logs(run)
cat(logs)
```

### 5. Azure Test Plans & Code Coverage

```r
# Retrieve code coverage for a build
coverage <- az_code_coverage_get(build_id = 1024)
print(coverage)
```

## License

MIT © 2026 AzureOps Authors
