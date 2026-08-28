# azureops 0.1.0

* Initial release of `azureops` providing an `{S7}` and `{httr2}` powered interface to the Azure DevOps REST API (v7.0/v7.1).
* Added core `az_client` S7 class with PAT credential masking, validator, and automatic environment variable resolution (`AZURE_DEVOPS_ORG`, `AZURE_DEVOPS_PAT`, `AZURE_DEVOPS_PROJECT`).
* Implemented polymorphic S7 generics:
  * `az_status()`: Multi-dispatch status summaries across pipeline runs, pull requests, work items, and test runs.
  * `az_browse()`: Opens resource links directly in browser.
  * `az_logs()`: Streams and retrieves execution logs.
  * `az_cancel()`: Polymorphic cancellation.
* Implemented S7 coercion methods (`convert(x, class_data.frame)`) for all domain entities.
* Added **Azure Boards** module: `az_work_item_get()`, `az_work_items_get()`, `az_work_item_create()`, `az_work_item_update()`, `az_wiql_query()`, `az_my_work_items()`, `az_feature_work_items()`, `az_iterations_list()`, `az_sprint_capacity_get()`.
* Added **Azure Repos** module: `az_repos_list()`, `az_repo_get()`, `az_branches_list()`, `az_commits_list()`, `az_commit_get()`, `az_pull_requests_list()`, `az_pull_request_get()`, `az_pull_request_create()`, `az_pull_request_reviewers_get()`.
* Added **Azure Pipelines** module: `az_pipelines_list()`, `az_pipeline_get()`, `az_pipeline_runs_list()`, `az_pipeline_run_get()`, `az_pipeline_run_trigger()`, `az_pipeline_run_logs_list()`, `az_pipeline_run_log_get()`.
* Added **Azure Test Plans** module: `az_test_plans_list()`, `az_test_suites_list()`, `az_test_cases_list()`, `az_test_runs_list()`, `az_test_run_metrics_get()`, `az_code_coverage_get()`.
* Added **Administration** module: `az_projects_list()`, `az_project_get()`, `az_project_create()`, `az_teams_list()`, `az_team_members_list()`, `az_security_groups_list()`, `az_user_entitlements_list()`, `az_webhooks_list()`, `az_webhook_create()`.
