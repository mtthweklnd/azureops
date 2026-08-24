# 10 — Pagination helper

**What to build:** A shared way to follow Azure DevOps continuation tokens, ready for the list functions to adopt. On its own this changes no public behaviour — it is the expand step that lets the five module tickets that follow land independently and stay green.

No function in the package reads a response header today, so continuation tokens are invisible to it. Azure returns paged list responses and signals more results via a continuation-token header; the helper is what turns that into a complete result set.

Note that the organisation-level services do not all paginate identically — the graph and entitlement endpoints differ from the core API. The helper should accommodate that rather than assume one scheme, and ticket 15 is where those differences get exercised.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] The helper follows the continuation-token header until the result set is exhausted
- [ ] A caller can cap the number of pages or items retrieved
- [ ] A single-page response with no token is handled without an extra request
- [ ] The differing pagination scheme used by the graph and entitlement services is supported
- [ ] Unit tested against multi-page and single-page responses
- [ ] No exported function changes behaviour in this ticket
