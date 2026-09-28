# Working in this repo

A small but complete HPCC Systems ECL project: two messy CSV feeds are
sprayed, cleaned, deduplicated, rolled up, scored for fraud, joined into a
serving record, indexed, and served from two Roxie queries.

The point of the repo is practice, so it is deliberately ordinary code with
a handful of deliberate defects. See `docs/EXERCISES.md`.

## Layout

```
ecl/Common/      layouts, constants, logical file names, pure helpers, macros
ecl/Ingest/      raw-to-typed cleaning and validation
ecl/Transforms/  dedup, rollups, joins, orphan detection
ecl/Analytics/   fraud signals, cohort reporting
ecl/Roxie/       published queries (STORED inputs, index reads)
ecl/BWR/         runnable scripts: spray, the batch pipeline, a scratchpad
ecl/Tests/       ASSERT-based tests over inline fixtures
data/            the two source CSVs
scripts/         lint, syntax check, test runner
```

`ecl/` is the ECL repository root. Every compile needs `-I ecl`, and imports
are written relative to it: `IMPORT $.^.Common;` from inside a subfolder,
`IMPORT $.Constants;` within one.

## Checks to run

```bash
./scripts/lint.sh            # style only, no HPCC install needed
./scripts/syntax_check.sh    # needs eclcc on PATH
./scripts/run_tests.sh       # needs a cluster; hthor is enough
```

`lint.sh` is the one that always works, so run it after any edit. It enforces
three rules: an attribute file EXPORTs a definition named after the file
(files named `BWR_*` are exempt), every file opens with a `/**` comment, and
no tabs / trailing whitespace / lines over 100 characters.

Most changes here cannot be verified without a cluster. Say so rather than
implying a change was tested — "lint and syntax check pass, not run on a
cluster" is the honest report.

## Conventions

- One `EXPORT` per attribute file, named after the file. Helpers inside a
  file are plain (non-exported) definitions or `SHARED` inside a `MODULE`.
- Record definitions live in `Common.Layouts` and nowhere else. A `*Raw`
  record is all `STRING`, matching the file on disk; its cleaned twin is
  typed.
- Logical file names live in `Common.Files`. No `'~scope::name'` literal
  belongs anywhere else.
- Business thresholds live in `Common.Constants`, not inline in a filter.
- Cleaning marks rows with `is_valid` and a `reject_reason` instead of
  filtering them out. Downstream code filters. That way every dropped row
  can be explained.
- `TRANSFORM`, `LIMIT`, `ROWS` and friends are ECL keywords: never use one
  as a folder, attribute, or field name. (The transforms folder is called
  `Transforms` for exactly this reason.)
- Prefer `TABLE` with `FEW`/`MERGE` over `ROLLUP` for aggregation, and say
  which join strategy you mean (`LOOKUP`, `SMART`, `ALL`) rather than
  leaving the optimiser to guess on a file this small.
- Two-space indent. Align `:=` within a block when it helps readability.

## When adding a field

It touches four places, in this order: `Common.Layouts`, the cleaning
`TRANSFORM` in `Ingest`, `Common.Files` if a new file or index is involved,
and a test in `ecl/Tests`. A field that reaches `CustomerProfile` also
needs the `Roxie` output projections checked.
