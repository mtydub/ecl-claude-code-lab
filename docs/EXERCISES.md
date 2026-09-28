# Exercises

Graded from reading to debugging. Each one is a prompt you can paste into
Claude Code, plus what a good result looks like. The answer key is in
[SOLUTIONS.md](SOLUTIONS.md).

Exercises 4 to 9 are **real defects planted in the code on purpose.** They
are the ones worth your time.

---

## Tier 1 — read the codebase

### 1. Trace the dataflow

> Read CLAUDE.md, then trace the dataflow from `data/customers_raw.csv` all
> the way to `Roxie.GetCustomerProfile`. Name every file a row passes
> through and what each one does to it.

**Good result:** the six-hop path through `BWR_SprayLanding`,
`CleanCustomers`, `Dedup_Customers`, `Rollup_CustomerSpend` +
`FraudScore`, `Join_CustomerTransactions`, `BUILDINDEX`, and an accurate
statement of *where rows are lost* (dedup, and the `is_valid` filter in the
BWR — not in the cleaning code, which drops nothing).

### 2. Explain a single attribute

> Explain `ecl/Transforms/Join_CustomerTransactions.ecl` line by line. Why
> `LEFT OUTER` rather than `INNER`? Why `DENORMALIZE` rather than a third
> `JOIN`? What would break if `LOOKUP` were removed?

**Good result:** connects `LEFT OUTER` to "customers with no transactions
still get a profile", `DENORMALIZE ... GROUP` to building the
`recent_txns` child dataset, and `LOOKUP` to distribution strategy rather
than correctness.

### 3. Map the blast radius of a change

> I want to add a `phone` field to customers, carried all the way through
> to the Roxie output. List every file that has to change, in the order I
> should change them, and what the change is in each. Do not edit anything
> yet.

**Good result:** `data/customers_raw.csv`, `Common.Layouts` (both
`CustomerRaw` and `Customer`), the `TRANSFORM` in `Ingest.CleanCustomers`,
a new helper + test if the phone needs normalising, and the projection in
`Roxie.SearchByName`. It should *not* list `Common.Files` (no new file) and
should notice that `CustomerProfile` inherits `Customer` and so comes along
for free.

---

## Tier 2 — the planted defects

Each of these has a matching test assertion that is commented out with a
`TODO(exercise N)` marker. The workflow is the same every time: uncomment
the assertion, run the tests, watch it fail, fix the source, watch it pass.

### 4. Customers in a supported country are being rejected

> `ecl/Tests/Test_CleanCustomers.ecl` has an assertion commented out with
> `TODO(exercise 4)`. Uncomment it and explain why it fails. Then fix the
> source so it passes, without weakening any other validation rule.

Two rows in `data/customers_raw.csv` are affected. Name them.

### 5. A customer who shopped at two merchants is counted as three

> Uncomment the `TODO(exercise 5)` assertion in
> `ecl/Tests/Test_Rollup_CustomerSpend.ecl`. Explain the bug, then fix
> `distinct_merchants` so it means what its name says.

There is more than one way to count distinct values inside a `TABLE`.
Ask for the trade-offs before picking one.

### 6. A ¥15,800 car is flagged as a high-value transaction

> Uncomment the `TODO(exercise 6)` assertion in
> `ecl/Tests/Test_FraudScore.ecl`. There are two separate mistakes behind
> this one failure. Find both and fix both.

One is a missing filter. The other is a modelling error that the missing
filter happens to hide. Fixing only the first leaves a landmine for the day
somebody adds JPY to `SupportedCurrencies`.

### 7. A wire transfer two weeks after signup is not flagged

> `Analytics.FraudScore` decides whether a wire is "within 30 days of
> signup" with `LEFT.txn_date <= RIGHT.signup_date + 30`. Write a test that
> exposes why this is wrong, then fix it.

No assertion is pre-written for this one. A customer who signed up on
2023-01-25 and wired money on 2023-02-10 should be flagged. Work out what
the current code computes, and why `STD.Date` exists.

### 8. The deduplication result is not reproducible

> `Transforms.Dedup_Customers` keeps one row per person. Which of the two
> Ada Lovelace rows in `data/customers_raw.csv` survives, and can you
> guarantee it? Make the behaviour deterministic and documented, then add a
> test that would catch a regression.

Decide *which* row should win before you change the code, and say why in
the comment. "The earliest signup" and "the lowest customer id" are both
defensible; silently arbitrary is not.

### 9. `SearchByName` does not use its index

> `Roxie.SearchByName` is published to Roxie but reads
> `Common.Files.DS_Profile`. `Common.Files.IDX_ProfileByName` exists and is
> built by the BWR. Rewrite the query to use it, and explain what `KEYED`
> changes about the generated graph.

Watch the first-name prefix filter: only part of it can be keyed. Say which
part and why.

---

## Tier 3 — build something

### 10. A new fraud rule

> Add a `FOREIGN_MERCHANT` rule to `Analytics.FraudScore`: fire when a
> transaction's currency does not match the customer's country. Weight it
> 20. Put the country-to-currency mapping somewhere a non-programmer could
> edit it, add tests, and run the linter.

**Good result:** the mapping ends up as an inline `DATASET` of reference
data in `Common` rather than a `MAP` buried in the rule, and the new rule is
added to the doc comment at the top of `FraudScore.ecl`.

### 11. A new Roxie query

> Write `Roxie.TopSpendersByState`: given a two-letter state and a row
> limit, return the highest-spending valid customers in that state with
> their fraud scores. Follow the conventions in the other two queries,
> including the `curl` example in the header comment.

### 12. Profile the raw feed

> Use `Common.MAC_ProfileField` to profile every column of
> `Common.Files.DS_TxnsRaw`, then tell me which columns I should not trust
> and what cleaning rule each one needs.

**Good result:** notices the currencies outside `SupportedCurrencies`, the
`REFUND` channel with negative amounts, and customer `C-9999` with no
matching customer record.

### 13. Review the whole thing

> Review this repo as if it were a pull request from a new team member.
> Prioritise correctness over style, and skip anything `./scripts/lint.sh`
> already enforces.

A good review finds several of exercises 4–9 unprompted. If it only
comments on naming and comments, push back and ask for correctness issues.

---

## Tier 4 — use Claude Code's own machinery

### 14. Custom commands

`.claude/commands/` has two slash commands: `/ecl-review` and
`/trace-dataflow`. Read them, run them, then write a third —
`/new-attribute` — that scaffolds a new ECL attribute file with the right
header comment, `EXPORT` name and `IMPORT` block for whichever folder you
name.

### 15. Tighten CLAUDE.md

Work through exercises 4–9, noticing every time you have to explain
something about this codebase that Claude should have known. Add those
facts to `CLAUDE.md`. Then start a fresh session and check that the same
exercise goes faster.

### 16. Make the checks hooks

Wire `./scripts/lint.sh` into a `PostToolUse` hook so it runs automatically
after every edit to a `.ecl` file, and fails loudly enough that it gets
fixed immediately rather than at commit time.
