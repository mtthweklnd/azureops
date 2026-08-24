# 17 — Code coverage returns correct, complete numbers

**What to build:** Retrieving code coverage for a build returns every coverage module the build reported, with a percentage column whose values match its name.

Three defects compound. Only the first coverage-data entry is read, so every subsequent one is silently discarded — a build reporting coverage for several flavours or targets loses all but one. The column named as a percentage holds a proportion, so a build at 80% coverage reports 0.8. And the same list is traversed three separate times to compute that one column, which is both wasteful and easy to get out of step during future edits.

A coverage figure that is quietly wrong by a factor of a hundred, over a quietly incomplete set of modules, is the kind of number that ends up in a report before anyone checks it.

**Blocked by:** 05 — Correct URL construction

**Status:** ready-for-agent

- [ ] All coverage modules are returned, not only those under the first coverage-data entry
- [ ] The percentage column's units match its name, or the column is renamed to match its units
- [ ] The column is computed in a single pass over the data
- [ ] A module reporting zero total lines yields a defined value rather than a division artefact
- [ ] Tests cover a response containing more than one coverage-data entry
