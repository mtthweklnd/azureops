# Implementation Plan: Preconfigured User & Feature Work Item Requests

This plan outlines the implementation of preconfigured request helpers in `azureops` to easily query user-specific work items/tasks (by email or `@me`) and feature-linked work items (by Feature ID or Title).

## Phase 1: WIQL Builder & Helper Functions
- [x] Task 1.1: Implement `.build_my_work_items_wiql(email, type, state, sprint_only)` helper function for constructing sanitized WIQL queries for user work items.
- [x] Task 1.2: Implement `.build_feature_work_items_wiql(feature_id, state)` helper function for querying child work items under a target Feature.

## Phase 2: High-Level Preconfigured Request APIs
- [x] Task 2.1: Implement `az_my_work_items()` in `R/boards.R` with roxygen2 documentation supporting `email`, `type`, `state`, `sprint_only`, `project`, `top`, `resolve`, `as_data_frame`, and `client`.
- [x] Task 2.2: Implement `az_feature_work_items()` in `R/boards.R` with roxygen2 documentation supporting `feature_id`, `feature_title`, `state`, `project`, `top`, `resolve`, `as_data_frame`, and `client`.
- [x] Task 2.3: Generate updated documentation files (`NAMESPACE`, `man/*.Rd`) via `devtools::document()`.

## Phase 3: Unit Testing & Suite Verification
- [x] Task 3.1: Create unit tests for `az_my_work_items()` in `tests/testthat/test-boards.R`.
- [x] Task 3.2: Add unit tests for `az_feature_work_items()` in `tests/testthat/test-boards.R`.
- [x] Task 3.3: Execute full test suite `testthat::test_local()` to ensure zero failures or warnings across all tests.

## Phase 4: Documentation & Final Cleanup
- [x] Task 4.1: Update `NEWS.md` describing the new preconfigured request functions.
- [x] Task 4.2: Final code audit and check working tree state.

## Phase 5: Caller Environment (`caller_env`) & Error Condition Testing
- [x] Task 5.1: Update internal error and parsing helper functions (`.parse_work_item`, `.build_feature_work_items_wiql`, `.parse_pipeline`, `.parse_pipeline_run`, `.parse_repo`, `.parse_pull_request`, `.parse_test_plan`, `.parse_test_run`, `.browse_helper`, `az_pat`, `az_org`) to accept `call = rlang::caller_env()` and pass `call = call` to `cli::cli_abort()`.
- [x] Task 5.2: Update exported API functions and input check logic to pass `call = rlang::caller_env()` and use `arg = rlang::caller_arg(...)` for dynamic argument name reporting in error conditions.
- [x] Task 5.3: Add and update unit and snapshot tests in `tests/testthat/` using `expect_snapshot(error = TRUE)` and `expect_error()` to verify error messages correctly attribute the error call context to the user-facing top-level functions rather than internal helpers.
- [x] Task 5.4: Execute `testthat::test_local()` to verify zero failures across the test suite with clean caller frame propagation.

