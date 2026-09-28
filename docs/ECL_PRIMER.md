# ECL in ten minutes

Enough ECL to read this repo. Not a reference — the
[language reference](https://hpccsystems.com/training/documentation/) is.

## It is declarative, and that changes everything

ECL is a dataflow language. You do not write "loop over the rows"; you write
"this dataset is that dataset, filtered". Every line is a **definition**, not
a statement:

```ecl
adults := customers(age >= 18);
```

Nothing has happened yet. `adults` is a name for a computation. The compiler
builds a graph of every definition an action depends on, optimises the whole
graph, and only then runs it. Consequences worth internalising:

- **Order does not matter.** You can define `b` before `a` even if `b` uses
  `a`. The compiler sorts it out.
- **Unused definitions cost nothing.** They are pruned.
- **There is no mutation.** `x := x + 1` is a circular definition, not an
  increment.
- **Only actions execute.** `OUTPUT`, `BUILDINDEX`, `ASSERT` and the spray
  functions are actions. A file of pure definitions runs nothing.

## Records and datasets

A `RECORD` is a layout; a `DATASET` is rows in that layout.

```ecl
PersonRec := RECORD
  UNSIGNED4 id;
  STRING25  name;
  UNSIGNED2 age;
END;

people := DATASET([{1, 'ADA', 38}, {2, 'GRACE', 43}], PersonRec);
onDisk := DATASET('~my::file', PersonRec, THOR);
```

Fixed-width types (`STRING25`, `UNSIGNED4`, `DECIMAL12_2`) are the norm on
disk because they make files seekable. `STRING` on its own is
variable-length. `DECIMAL12_2` means 12 digits, 2 after the point — use it
for money, never `REAL`.

Filtering uses parentheses, not a keyword:

```ecl
people(age >= 18, name[1] = 'A')     // commas are AND
```

## The five verbs you need here

| Verb | Rows in → out | Used for |
|---|---|---|
| `PROJECT` | 1 → 1 | reshape or retype a row |
| `JOIN` | 2 sets → 1 | match rows across datasets |
| `DENORMALIZE` | 1 + N → 1 | fold children into a parent's child dataset |
| `TABLE` | N → 1 per group | aggregate |
| `DEDUP` / `SORT` | N → ≤N | order and remove duplicates |

Each of the row-producing ones takes a `TRANSFORM`, which is the one place in
ECL that looks imperative:

```ecl
CleanRec doClean(RawRec L) := TRANSFORM
  trimmed        := STD.Str.Trim(L.name, LEFT, RIGHT);   // a local definition
  SELF.name      := STD.Str.ToUpperCase(trimmed);
  SELF.id        := (UNSIGNED4)L.id;                     // cast
  SELF.is_valid  := trimmed != '';
END;

cleaned := PROJECT(raw, doClean(LEFT));
```

`LEFT` is the input row, `SELF` the output row. **Every field of `SELF` must
be assigned** or the compiler errors — `SELF := LEFT;` assigns everything
with a matching name, and is usually the last line.

In a `JOIN` transform, `LEFT` and `RIGHT` are the two matched rows:

```ecl
JOIN(customers, spend,
     LEFT.customer_id = RIGHT.customer_id,
     TRANSFORM(ProfileRec, SELF := RIGHT, SELF := LEFT),
     LEFT OUTER, LOOKUP);
```

`LEFT OUTER` keeps unmatched left rows; `LEFT ONLY` keeps *only* unmatched
left rows (that is how `Transforms.Orphan_Transactions` finds orphans).
`LOOKUP` says "the right side is small enough to copy to every node" — on a
real cluster this choice is the difference between seconds and hours.

Aggregation is `TABLE` with `COUNT(GROUP)` and friends:

```ecl
TABLE(txns,
      {customer_id,
       UNSIGNED4   txn_count := COUNT(GROUP),
       DECIMAL12_2 total     := SUM(GROUP, txns.amount)},
      customer_id,        // group by
      FEW);               // "few distinct groups", so hash in memory
```

## MODULE, EXPORT, IMPORT

A folder is a module; a file inside it is an attribute. The file must export
a definition with the file's own name:

```ecl
// ecl/Common/Constants.ecl
EXPORT Constants := MODULE
  EXPORT UNSIGNED2 MinAdultAge := 18;
  SHARED STRING secret := 'visible inside this MODULE only';
END;
```

Imports are relative to the repository root you pass with `-I`:

```ecl
IMPORT $.Constants;      // a sibling file in the same folder
IMPORT $.^.Common;       // up one level, then into Common
IMPORT STD;              // the standard library
IMPORT $ AS Tests;       // the current folder, under an alias
```

`$` is "this module", `^` is "parent". `-I ecl` is what makes `Common`,
`Ingest`, `Transforms` and the rest visible as top-level module names.

## FUNCTION, FUNCTIONMACRO, STORED

A `FUNCTION` groups definitions and returns one of them:

```ecl
EXPORT CleanCustomers(DATASET(CustomerRaw) inRaw) := FUNCTION
  cleaned := PROJECT(inRaw, doClean(LEFT));
  RETURN cleaned;
END;
```

A `FUNCTIONMACRO` is textual: it takes a *field name* or a dataset
expression, which a `FUNCTION` cannot. That is why
`Common.MAC_ProfileField` is a macro — `fieldName` is pasted into a `TABLE`
at compile time.

`STORED` turns a definition into an input the caller supplies. It is how a
Roxie query declares its parameters:

```ecl
UNSIGNED4 CustomerId := 0 : STORED('CustomerId');
```

## Indexes

Roxie reads indexes, not base files. A *payload* index carries the whole
record alongside the key, so one keyed read answers the query:

```ecl
IDX := INDEX(profiles, {customer_id}, {profiles}, '~key::profile_by_id');
hit := IDX(KEYED(customer_id = CustomerId));
```

`KEYED` is the load-bearing word. Without it the filter is applied after
reading, and you have written a full scan with extra steps. That distinction
is exercise 9.

## Gotchas that will bite you

- **Keywords are not reserved gently.** `TRANSFORM`, `LIMIT`, `ROWS`,
  `GROUP`, `RECORD` cannot be attribute, folder or field names. This repo's
  transforms folder is `Transforms` because of it.
- **Trailing spaces are real.** `STRING10` holding `'ADA'` is `'ADA       '`.
  Compare with `TRIM(...)` or you will chase a phantom.
- **Dates here are packed `UNSIGNED4` (`YYYYMMDD`)**, which is sortable and
  comparable but *not* arithmetic: `20230125 + 30` is `20230155`, which is
  not a date. Use `STD.Date` when you mean day arithmetic. (Exercise 7.)
- **`DEDUP` keeps the first row it meets**, so the result depends on the
  preceding `SORT`. An incomplete sort key means a non-deterministic answer.
  (Exercise 8.)
- **`AVE(GROUP, x)` into a `DECIMAL12_2` truncates.** Fine for reporting,
  wrong for accounting.
- **`OPT` on a `DATASET` or `INDEX`** makes a missing file read as empty
  instead of failing. Every base file here uses it so that a partial build
  still compiles.
