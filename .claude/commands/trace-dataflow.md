---
description: Trace a field or dataset from source CSV through to the Roxie output
argument-hint: [field or dataset name]
---

Trace `$ARGUMENTS` through this pipeline, end to end.

If no argument was given, trace a customer row from
`data/customers_raw.csv` to `Roxie.GetCustomerProfile`.

Report, in order:

1. **Path.** Every attribute file the value passes through, in execution
   order, with the transformation applied at each hop. Use
   `file.ecl:line` references.
2. **Type changes.** Where it is retyped or reshaped, and what is lost —
   truncation into a fixed-width field, precision into `DECIMAL`, a cast
   that silently yields 0.
3. **Row loss.** Every point where a row carrying this value can be
   dropped: a filter, a `DEDUP`, an `INNER` join. Say whether the drop is
   accounted for anywhere (a `reject_reason`, an orphan output) or silent.
4. **Where it lands.** Which logical files and indexes in `Common.Files`
   end up holding it, and which Roxie queries expose it.
5. **Test coverage.** Which assertions in `ecl/Tests` would fail if this
   value were computed wrongly. If none would, say so.

Read the code; do not infer the pipeline from the README diagram.
