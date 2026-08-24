# 09 — Work item retrieval: batching and a stable return schema

**What to build:** A WIQL query resolving thousands of work item IDs succeeds, and the shape of what comes back does not change with the number of results or the combination of arguments used.

Two problems sit in the same call path. Batch retrieval sends every ID in a single request, but the API caps that batch — a query resolving more than the limit fails outright, and WIQL routinely returns far more.

The return type is also unstable. The unresolved path returns a single-column frame, the resolved path an eight-column one, and the empty case a frame with no columns at all. Any downstream pipeline breaks depending on how many results happened to come back. IDs that fail to parse are silently discarded rather than reported.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] Resolving more IDs than the API batch limit issues multiple requests and concatenates the results
- [ ] Result ordering is deterministic and documented
- [ ] The data frame form returns identical columns for zero, one and many results
- [ ] The resolved and unresolved paths return the same schema
- [ ] IDs that fail to parse raise an error rather than being dropped
- [ ] A test covers a result set larger than the batch limit
