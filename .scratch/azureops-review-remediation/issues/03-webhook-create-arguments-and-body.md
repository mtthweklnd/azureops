# 03 — Webhook creation takes correct arguments and sends a valid body

**What to build:** `az_webhook_create()` can be called the way its documentation implies — with the event type as the first argument — refuses locally when no destination URL is supplied, and sends a body Azure will accept.

Three defects compound here. The required event type sits after a defaulted publisher argument, so the first positional argument silently binds to the wrong parameter and the call then fails on a missing argument. The consumer and publisher input defaults serialise to empty JSON *arrays* where Azure expects objects. And the destination URL, which is mandatory, is never validated, so a subscription with nowhere to deliver is only rejected at the API.

This endpoint is organisation-level and unaffected by the URL work, so it can proceed in parallel.

**Blocked by:** None — can start immediately.

**Status:** completed

- [x] Required arguments precede optional ones; the first positional argument is the event type
- [x] Calling without a destination URL raises a clear, actionable error before any request is made
- [x] Consumer and publisher inputs serialise as JSON objects, never as empty arrays
- [x] A test asserts the serialised request body shape, not just the parsed response
