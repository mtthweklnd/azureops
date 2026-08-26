# 06 — Unexpected and empty responses fail loudly

**What to build:** A call that does not get back what it asked for raises an error, instead of handing the caller a well-formed object built entirely out of defaults.

Every parse helper converts missing fields into benign defaults, so a response of the wrong shape yields a valid-looking object rather than a failure. A failed work item creation returns an item with id 0 and an empty title. A failed pipeline trigger returns a run reporting status "inProgress" — so the caller believes a deploy started, and then polls a run that never existed. That is the worst failure mode in the package: it is silent, and it looks like success.

There is also a guard for empty response bodies that can never execute, because the string extraction it protects aborts first. Only the 204 case is handled; a 200 or 202 with an empty body, which Azure returns for some asynchronous operations, surfaces as an opaque internal error from the HTTP library.

**Blocked by:** 01 — Repo hygiene and a URL-asserting test harness

**Status:** completed

- [x] Parsing a response with no identity field raises an error naming the operation that failed
- [x] No parse helper defaults an identity field to zero or to an empty string
- [x] A 200 or 202 with an empty body returns nothing, cleanly, rather than an internal HTTP-library error
- [x] The empty-body path is reachable and covered by a test
- [x] Error messages distinguish "the API returned an error" from "the API returned something unexpected"
