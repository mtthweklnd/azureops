# 15 — Pagination: Administration

**What to build:** The project, team, member, security group, entitlement and webhook listings return the complete result set rather than a truncated first page.

This is the module where pagination schemes diverge. The core API, the graph service and the entitlement service do not all page identically, and the graph and entitlement endpoints are the ones an administrator is most likely to run against a large organisation — a licence audit that silently sees only the first hundred users is worse than no audit at all.

**Blocked by:** 10 — Pagination helper

**Status:** ready-for-agent

- [ ] Project, team, team member, security group, user entitlement and webhook listings return all results across page boundaries
- [ ] The graph and entitlement services paginate correctly under their own scheme, not the core API's
- [ ] Each accepts a limit so a caller can bound the work deliberately
- [ ] Tests cover a multi-page response for both a core-API listing and a graph or entitlement listing
- [ ] Existing single-page behaviour is unchanged
