# 16 — Browsing a pull request opens its web page

**What to build:** Calling the browse generic on a pull request opens the pull request in the Azure DevOps web interface, rather than a JSON API endpoint.

The pull request parser populates its web URL from the response's `url` field, which is the REST self-link, not the browser-facing page. The web link is available elsewhere in the same response. The repository and pipeline parsers already take their web URLs from the right places, so this parser is the outlier.

The test fixture reinforces the mistake: it invents a web-UI-shaped value for `url` that the real API never returns, and no test asserts the parsed web URL at all. The fixture needs replacing with a real-shaped one, not adjusting.

Browsing a pull request is demonstrated as a headline feature in the README, so this is user-visible on first contact.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] Browsing a pull request opens the web interface page
- [ ] The pull request parser reads its web URL from the same place the other parsers do
- [ ] The invented fixture is replaced with one matching a real response
- [ ] A test asserts the parsed web URL, for both the single-fetch and create paths
- [ ] The REST self-link remains available to callers who want it
