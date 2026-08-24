# 21 — Documentation matches shipped behaviour

**What to build:** A user reading the README, the release notes or the reference index finds only claims the package actually satisfies. This is the closing ticket — it runs after the behavioural work so that it documents what shipped rather than what was intended.

The review found the documentation describing project scoping, team scoping, polymorphic cancellation and log streaming as working features while none of them were. Once tickets 05, 08, 18 and 19 land, the remaining task is to reconcile the prose with the result and sweep up the small correctness items that do not deserve tickets of their own.

The cancellation generic's own removal from the documentation belongs to ticket 19; this ticket covers everything else.

**Blocked by:** 05 — Correct URL construction; 08 — Team scoping; 16 — Pull request web URL; 18 — Pipeline logs; 19 — Withdraw the cancellation generic

**Status:** ready-for-agent

- [ ] Every feature claimed in the README works as shown, verified by running the examples
- [ ] Release notes describe what the release actually contains
- [ ] The reference index lists no withdrawn functions
- [ ] The unused HTTP auth import is removed, and `utils` is declared as a dependency
- [ ] Argument naming is consistent with the rest of the package
- [ ] Hardcoded API versions no longer silently override a client's configured version, or the reason they must is documented
- [ ] Credential masking does not reveal a leading fragment of the token or its exact length
- [ ] Error body extraction uses exact rather than partial field matching
- [ ] `R CMD check` passes with no errors, warnings or notes
