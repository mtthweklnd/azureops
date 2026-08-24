# 18 — Pipeline logs retrieve complete content

**What to build:** Fetching logs for a pipeline run returns the run's log output — all of it, as text.

Today the logs generic picks the highest-numbered log chunk and returns only that, undocumented, while the documentation promises the run's execution logs and the README demonstrates printing the result as though it were the full output. Which chunk happens to have the highest identifier is not meaningful to a caller.

Separately, the log-fetching function returns the raw response body from an endpoint that appears to serve log *metadata* rather than log text, and its documentation claims a character vector of log lines while it returns a single string. Ticket 07 establishes which endpoint actually serves content; this ticket acts on that answer.

**Blocked by:** 05 — Correct URL construction; 07 — Live-tenant verification suite

**Status:** ready-for-agent

- [ ] Fetching logs for a run returns the complete log output across all chunks
- [ ] A caller can request a specific chunk when they want one
- [ ] The returned value matches its documented type
- [ ] Log content is retrieved from whichever endpoint ticket 07 confirmed serves it
- [ ] A run with several log chunks is covered by a test
- [ ] A run with no logs returns cleanly rather than erroring
