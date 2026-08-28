# `{cli}` Package Implementation Plan

This document outlines the step-by-step implementation plan for integrating and standardizing the `{cli}` package across the **AzureOps** codebase.

---

## Overview

The goal of this feature is to replace raw text output functions (such as `cat()`) with modern `{cli}` formatting, implement rich terminal printing for all S7 domain objects, add progress indicators for batch API operations, and refine diagnostic error/status messaging.

---

## Numbered Phases of Implementation

### Phase 1: Audit & S7 Object CLI Print Methods
**Objective:** Replace base R `cat()` output in class print methods and define rich `{cli}` custom print methods for all S7 domain classes.

- **Tasks:**
  1. Audit existing `format` and `print` implementations in `R/generics.R` and `R/classes.R`.
  2. Implement `{cli}` formatted printing (`cli::cli_h3`, `cli::cli_dl`, `cli::cli_alert_info`, `cli::cli_format_method`) for:
     - `az_client`
     - `az_work_item`
     - `az_repo`
     - `az_pull_request`
     - `az_pipeline`
     - `az_pipeline_run`
     - `az_test_plan`
     - `az_test_run`
  3. Export or register S7 `print` / `format` methods in `R/generics.R` / `R/classes.R` and `NAMESPACE`.
  4. Write unit tests in `tests/testthat/` verifying `{cli}` print and format output for all classes.
- **Verification:** Run `devtools::test()` to ensure all tests pass.

---

### Phase 2: Enhanced Status Indicators & Progress Bars
**Objective:** Upgrade `az_status()` generic methods with `{cli}` symbols and themes, and add progress indicators for multi-item requests.

- **Tasks:**
  1. Refine `az_status()` S7 methods (`az_pipeline_run`, `az_pull_request`, `az_work_item`, `az_test_run`) using `{cli}` inline formatting (`{.strong}`, `{.val}`, `{.emph}`) and status bullet icons.
  2. Add progress bar handling (`cli::cli_progress_bar()`, `cli::cli_progress_update()`, `cli::cli_progress_done()`) in `az_work_items_get()` and `az_wiql_query()` when resolving multiple work items.
  3. Ensure progress bars display cleanly during interactive/batch calls without disrupting returned objects.
  4. Update unit tests in `tests/testthat/test-generics.R` and `tests/testthat/test-boards.R` to test enhanced status reporting and progress bars.
- **Verification:** Run `devtools::test()` to ensure all tests pass.

---

### Phase 3: CLI Refactoring of Demo Script (`scripts/demo.R`)
**Objective:** Replace all `cat()` statements in `scripts/demo.R` with `{cli}` structured formatting tools.

- **Tasks:**
  1. Audit `scripts/demo.R` for `cat()` calls.
  2. Refactor section titles to `cli::cli_h1()` and `cli::cli_h2()`.
  3. Refactor key-value outputs and URLs to `cli::cli_dl()` or `cli::cli_inform()`.
  4. Refactor status/validation outputs to `cli::cli_alert_info()`, `cli::cli_alert_success()`, and `cli::cli_rule()`.
  5. Run `Rscript scripts/demo.R` to verify visual layout and CLI formatting in the terminal.
- **Verification:** Run `devtools::test()` and execute `Rscript scripts/demo.R`.

---

### Phase 4: Standardization of Error & Informational Messages & Package Check
**Objective:** Audit all error/warning/info messages across package modules and configure `.Rbuildignore`.

- **Tasks:**
  1. Audit `R/auth.R`, `R/client.R`, `R/admin.R`, `R/boards.R`, `R/pipelines.R`, `R/repos.R`, and `R/test_plans.R` for consistent `{cli}` message styling (`{.arg}`, `{.envvar}`, `{.file}`, `{.val}`, `{.code}`).
  2. Add `_dev` to `.Rbuildignore` so development artifacts are excluded from R package builds.
  3. Run complete test suite and package check to ensure clean execution.
- **Verification:** Run `devtools::test()` and ensure zero test failures.
