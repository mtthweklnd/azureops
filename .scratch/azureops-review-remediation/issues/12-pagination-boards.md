# 12 — Pagination: Azure Boards

**What to build:** The iteration and sprint capacity listings return the complete result set rather than a truncated first page.

Work item batch retrieval is deliberately out of scope here — it is a request-chunking problem rather than a response-continuation one, and is handled in ticket 09.

**Blocked by:** 10 — Pagination helper

**Status:** ready-for-agent

- [ ] Iteration and sprint capacity listings return all results across page boundaries
- [ ] Each accepts a limit so a caller can bound the work deliberately
- [ ] Tests cover a multi-page response for at least one listing in this module
- [ ] Existing single-page behaviour is unchanged
