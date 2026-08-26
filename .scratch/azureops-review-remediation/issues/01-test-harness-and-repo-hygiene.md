# 01 — Repo hygiene and a URL-asserting test harness

**What to build:** Contributors can write a test that asserts exactly what request the package *sent* — URL, method, headers, body — rather than only what it parsed back. Every existing module test is converted to use it, pinning today's behaviour so that later corrections show up as deliberate diffs instead of invisible changes. Alongside it, the ignore files so that credentials and recorded fixtures can never be committed or shipped in the tarball.

This is the prefactor for the whole remediation. The current suite passes 163 assertions while the request layer is broken, because the mock handlers answer any URL and no test inspects the request. Until that is fixed, no downstream fix is provable.

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] `.gitignore` and `.Rbuildignore` exist and cover `.Renviron`, key material, and the future fixture/recording directory
- [x] A test helper captures the outgoing request and makes URL, method, headers and body assertable from any mocked response
- [x] Every existing module test asserts the URL it expects, not only the parsed result
- [x] The asserted URLs describe *current* behaviour, including the URLs known to be wrong — those are corrected in ticket 05
- [x] The suite still passes
- [x] Deliberately altering a URL in the source causes at least one test to fail (proves the harness detects what it claims to)
