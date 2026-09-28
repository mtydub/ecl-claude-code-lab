---
description: Review changed ECL for correctness, cluster behaviour and repo conventions
---

Review the ECL changes in this repo. Run `git diff` first; if the working
tree is clean, review `git diff HEAD~1` instead.

Skip anything `./scripts/lint.sh` already enforces — no comments on tabs,
trailing whitespace, line length, header comments or EXPORT naming. Run it
and report the result instead.

Look for, in priority order:

1. **Correctness.** Wrong aggregation, a `TRANSFORM` field assigned from the
   wrong side, a filter on a raw value where a normalised one was intended,
   packed-`YYYYMMDD` dates used in arithmetic, `DEDUP` whose preceding
   `SORT` does not fully determine the surviving row, comparisons against a
   threshold whose units do not match the field.
2. **Silent row loss.** Any `JOIN` that drops rows without a `LEFT ONLY`
   output accounting for them, and any filter that removes rows without a
   `reject_reason` explaining them.
3. **Cluster behaviour.** Missing or wrong join strategy (`LOOKUP` on a
   large right side, `ALL` on anything big), `LOCAL` used without a
   guaranteed `DISTRIBUTE`, unkeyed filters in a Roxie query, `SORT` where a
   `TABLE ... FEW` would do.
4. **Repo conventions**, as stated in CLAUDE.md: layouts only in
   `Common.Layouts`, file names only in `Common.Files`, thresholds only in
   `Common.Constants`, keyword collisions.
5. **Test coverage.** Every new rule or field should have an assertion in
   `ecl/Tests`.

For each finding give the file and line, what breaks, and a concrete input
that triggers it. Say plainly when you cannot verify something without a
cluster.
