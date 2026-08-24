# 04 — Class properties are documented

**What to build:** A user running `?az_work_item`, or asking for help on any other domain class, sees what each property means and what type it holds. Today all seven domain classes ship with zero documented properties — roughly 45 undocumented arguments — so the package's primary data structures are opaque to anyone who did not write them.

`R CMD check` currently reports this as a WARNING, which also blocks CRAN.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] All seven domain classes document every property, including its type and meaning
- [ ] `R CMD check` reports no WARNING about undocumented arguments
- [ ] Documentation is generated from source rather than hand-edited into the generated files
- [ ] Each class's help page states which API resource it corresponds to
