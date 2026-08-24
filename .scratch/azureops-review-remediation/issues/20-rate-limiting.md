# 20 — Rate limiting is handled

**What to build:** A request that Azure DevOps throttles waits and retries rather than failing the call.

The package has no retry or throttle handling anywhere, and reads no response headers at all, so a 429 with a `Retry-After` header is treated as a hard failure. Azure DevOps throttles on consumed throughput units, and the operations most likely to trip it are exactly the ones this package exists to do: resolving a large WIQL result set, walking paginated listings, seeding or auditing at scale. Transient 5xx responses fail the same way.

Expect to hit this while provisioning the sandbox in ticket 07 — whatever that reveals about real throttling behaviour is the specification for this ticket.

**Blocked by:** 05 — Correct URL construction; 07 — Live-tenant verification suite

**Status:** ready-for-agent

- [ ] A 429 response is retried after the interval the server specifies
- [ ] Transient server errors are retried with backoff; client errors are not
- [ ] Retries are bounded, and exhausting them reports why
- [ ] A caller can disable or tune the retry policy
- [ ] Paginated listings and batch retrieval respect throttling across their whole sequence, not just the first request
- [ ] Tests cover a throttled response with and without a `Retry-After` header
