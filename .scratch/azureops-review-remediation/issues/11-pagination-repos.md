# 11 — Pagination: Azure Repos

**What to build:** Every listing function in the Repos module returns the complete result set instead of a silently truncated first page. A user listing repositories, branches, commits, pull requests or reviewers gets all of them.

Silent truncation is the failure mode that matters here. Nothing errors, nothing warns — the caller receives a well-formed result set that is simply missing rows, and any count, filter or aggregate computed from it is wrong in a way that looks right.

**Blocked by:** 10 — Pagination helper

**Status:** ready-for-agent

- [ ] Repository, branch, commit, pull request and reviewer listings return all results across page boundaries
- [ ] Each accepts a limit so a caller can bound the work deliberately
- [ ] The commit listing uses the parameter name the API actually honours (confirmed in ticket 07)
- [ ] Tests cover a multi-page response for at least one listing in this module
- [ ] Existing single-page behaviour is unchanged
