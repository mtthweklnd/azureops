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
- [ ] Task 3.1: Create `tests/testthat/test-preconfigured-requests.R` with comprehensive tests for `az_my_work_items()`.
- [ ] Task 3.2: Add unit tests in `tests/testthat/test-preconfigured-requests.R` for `az_feature_work_items()`.
- [ ] Task 3.3: Execute full test suite `testthat::test_local()` to ensure zero failures or warnings across all tests.

## Phase 4: Documentation & Final Cleanup
- [ ] Task 4.1: Update `NEWS.md` describing the new preconfigured request functions.
- [ ] Task 4.2: Final code audit and check working tree state.
