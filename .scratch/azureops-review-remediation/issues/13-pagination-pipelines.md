# 13 — Pagination: Azure Pipelines

**What to build:** The pipeline, run and run-log listings return the complete result set rather than a truncated first page. An organisation with more pipelines than fit in one page currently sees only some of them.

**Blocked by:** 10 — Pagination helper

**Status:** ready-for-agent

- [ ] Pipeline, pipeline run and run log listings return all results across page boundaries
- [ ] Each accepts a limit so a caller can bound the work deliberately
- [ ] The cross-pipeline run listing either paginates correctly or is removed if ticket 07 confirms the endpoint does not exist
- [ ] Tests cover a multi-page response for at least one listing in this module
- [ ] Existing single-page behaviour is unchanged
