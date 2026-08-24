# 02 — Basic auth header survives long PATs

**What to build:** A user whose Personal Access Token is longer than about 55 characters can authenticate. Azure DevOps has issued 84-character full-scope tokens since 2023, and every one of them currently fails.

The header is assembled by hand from a base64 encoder that wraps its output at 76 characters. The trim applied afterwards removes only leading and trailing whitespace, leaving a line break embedded in the middle of the header value, and the request dies at the transport layer with an opaque "Server returned nothing" error. httr2's Basic auth support is already imported and unused.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] An 84-character PAT produces an `Authorization` header containing no line breaks
- [ ] A request built with an 84-character PAT reaches the server instead of failing at transport
- [ ] The header is produced by httr2's Basic auth support rather than hand-assembled
- [ ] Regression tests cover both a 52-character and an 84-character token
- [ ] The now-unused base64 dependency is removed from the request path
