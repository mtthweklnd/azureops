# Preconfigured Requests Refinement One-Pager

## Problem Statement
How might we empower Azure DevOps users in R to instantly query their active work items and inspect all work items associated with specific Features via ergonomic dedicated functions, removing the friction of writing manual WIQL strings?

## Recommended Direction
Implement two high-level dedicated functions in `R/boards.R`:

- `az_my_work_items()`: Queries work items assigned to the current user (using `@me` or a specific email). Includes defaults for filtering active states (`state = "active"`) and an optional `sprint_only = TRUE` flag.
- `az_feature_work_items()`: Queries child work items linked to a Feature by `feature_id` or searching by `feature_title`.

## Key Assumptions
- WIQL `@me` macro is natively supported by Azure DevOps REST API for PAT authentication.
- `[System.Parent]` field is available across standard Azure DevOps processes for parent-child links.
- Dedicated functions provide superior autocompletion and roxygen documentation compared to a generic dispatcher.

## MVP Scope
- WIQL helper functions: `.build_my_work_items_wiql()` and `.build_feature_work_items_wiql()`.
- Exported API functions in `R/boards.R`: `az_my_work_items()` and `az_feature_work_items()`.
- Mocked unit tests in `tests/testthat/test-preconfigured-requests.R`.
- Documentation in `NAMESPACE`, `man/*.Rd`, and `NEWS.md`.

## Not Doing (and Why)
- **Generic preset dispatcher (`az_preset_query`)**: Omitted to keep the API clean, type-safe, and discoverable.
- **Deep multi-level tree recursion**: Limited to direct parent-child relationships (`[System.Parent] = Feature ID`) to prevent high network latency.
- **Auto-fetching PAT user email**: Defaulting to `@me` in WIQL lets Azure DevOps handle identity server-side.
