# 08 — Team scoping for iterations and capacity

**What to build:** A user querying a named team's iterations or sprint capacity gets that team's data.

The `team` argument is documented and accepted by both functions, and then discarded. In the iterations function the discard is visible in the source: both branches of the conditional produce an identical string, and the branch that appears to build a team-scoped path is a format call with no arguments. In the capacity function the argument is simply never referenced again.

Because both endpoints require the team in the path, Azure falls back to the project's default team. Callers asking for a specific team receive another team's sprint data with nothing to indicate anything went wrong — wrong numbers, confidently reported.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] The team segment reaches the request path for both iterations and capacity
- [ ] Omitting the team preserves the existing default-team behaviour
- [ ] Team names containing spaces are encoded correctly
- [ ] Tests assert the URL for both the team-specified and team-omitted cases
- [ ] The dead conditional is removed rather than left in place
