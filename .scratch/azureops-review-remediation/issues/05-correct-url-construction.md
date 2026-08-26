# 05 — Correct URL construction

**What to build:** The `project` argument — accepted and documented on more than twenty exported functions — actually reaches the request path, and names containing spaces or parentheses work.

This is the central defect. Every module builds endpoints beginning `_apis/`, and the request builder explicitly refuses to insert the project segment for exactly those endpoints, so the project branch is unreachable for every real caller. The consequences split two ways. Endpoints that *require* project scope return 404. Endpoints that also exist at organisation scope return organisation-wide results with the project filter silently ignored, handing the caller a plausible-looking result set containing the wrong rows — the more dangerous of the two.

Separately, path segments are interpolated into the URL without encoding, so any project or repository name containing a space or parentheses fails to parse before a request is even attempted. Azure DevOps permits both, and they are common.

Most remaining tickets are gated on this one, because verifying them requires a correctly built URL.

**Blocked by:** 01 — Repo hygiene and a URL-asserting test harness

**Status:** completed

- [x] A project-scoped call produces a path of the form `{org}/{project}/_apis/...`
- [x] Genuinely organisation-level calls (projects, teams, hooks, graph, entitlements) remain unprefixed
- [x] A project or repository name containing a space or parentheses produces a correctly encoded URL rather than a parse error
- [x] The "project already present in path" check compares literally rather than as a regular expression
- [x] Every exported function accepting `project` has a test asserting the URL it produces
- [x] The URLs pinned in ticket 01 are updated to their corrected forms, and the diff shows every URL that changed
