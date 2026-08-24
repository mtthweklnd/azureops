# 14 — Pagination: Azure Test Plans

**What to build:** The test plan, suite, case and run listings return the complete result set rather than a truncated first page. Test case listings in particular exceed one page routinely, so a suite's case count is currently understated whenever it is large.

**Blocked by:** 10 — Pagination helper

**Status:** ready-for-agent

- [ ] Test plan, test suite, test case and test run listings return all results across page boundaries
- [ ] Each accepts a limit so a caller can bound the work deliberately
- [ ] Tests cover a multi-page response for at least one listing in this module
- [ ] Existing single-page behaviour is unchanged
