# 19 — Withdraw the cancellation generic and close the documented-method gaps

**What to build:** The public surface contains only operations that work. The cancellation generic is removed entirely, and the remaining generics either have the methods their documentation promises or stop promising them.

The cancellation generic is exported, listed in the reference index, and described in both the README and the release notes as polymorphic cancellation. It has no methods at all — calling it on a pipeline run or a pull request fails with a dispatch error. Shipping a documented no-op is worse than shipping nothing, because a user has no way to distinguish it from a bug in their own code.

The same gap exists more narrowly elsewhere: the logs generic documents support for test runs and has no such method, and the status generic has no method for pipelines, repositories or test plans.

Removal was chosen over implementation deliberately. This ticket owns the documentation changes for the cancellation generic specifically — README, release notes, and reference index entries — so that its removal is complete in one step. Ticket 21 handles the broader documentation sweep.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] The cancellation generic is removed from the exported surface, the reference index, the README and the release notes
- [ ] The logs generic documents only the types it actually dispatches on
- [ ] The status generic either gains methods for the remaining domain types or documents which types it supports
- [ ] Calling any exported generic on a documented type succeeds rather than raising a dispatch error
- [ ] A test asserts that each generic dispatches for every type its documentation claims
