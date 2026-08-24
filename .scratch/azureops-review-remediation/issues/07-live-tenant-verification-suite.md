# 07 — Live-tenant verification suite

**What to build:** A read-only test tier that runs against a real Azure DevOps organisation when credentials are present and skips cleanly when they are not, plus fixtures recorded from real responses to replace the hand-invented ones.

The current fixtures were written by hand, and at least one encodes a wrong assumption as expected behaviour: a pull request's `url` is given a web-UI-shaped value that the real API never returns. No amount of testing at that tier can catch that class of bug, because the fixture and the code share the same mistaken belief. Recorded responses cannot.

This ticket also answers the questions the offline review could not close.

**Blocked by:** 05 — Correct URL construction (recording fixtures through a broken URL builder would capture the wrong requests)

**Status:** ready-for-agent

- [ ] Live tests skip cleanly when no credentials are present, and on CRAN
- [ ] Credentials are read from the environment or an encrypted secret; none are committed
- [ ] Recorded fixtures are sanitised — no tokens, no user email addresses, no real organisation identifiers
- [ ] Recordings replay offline in CI with no network access
- [ ] Sandbox provisioning is documented: a project name containing a space, a non-default team with its own iterations, more than 200 work items matched by a single query, and a pipeline run with several log chunks
- [ ] These open questions are confirmed or refuted and the answers recorded: which endpoint serves pipeline log *content* rather than metadata; whether cross-pipeline run listing exists at the path currently used; the correct parameter name for limiting commit results
- [ ] Operations that mutate tenant state are excluded from this tier
