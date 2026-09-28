# Answer key

Spoilers for [EXERCISES.md](EXERCISES.md). Tiers 1, 3 and 4 are open-ended;
what follows is the key for the six planted defects.

---

## 4. Mixed-case country codes — `ecl/Ingest/CleanCustomers.ecl`

```ecl
countryOK := L.country IN Constants.SupportedCountries;
```

`Constants.SupportedCountries` is `['US','CA','GB','AU','SG']`, all
upper-case. `L.country` is the raw value. Two rows arrive lower-case:

- `C-1002` Grace Hopper, `us`
- `C-1025` Ken Thompson, `ca`

Both are rejected as `UNSUPPORTED_COUNTRY` even though their countries are
supported. Note that the very next block *does* upper-case the value on its
way into `SELF.country`, so the stored row looks fine and only the
`reject_reason` betrays the bug — which is why it survived review.

**Fix:** validate the normalised value, not the raw one. Hoist the
normalisation into a local definition and use it in both places:

```ecl
country   := STD.Str.ToUpperCase(STD.Str.Trim(L.country, ALL));
countryOK := country IN Constants.SupportedCountries;
...
SELF.country := country;
```

The same latent bug exists for `state`; `CleanTransactions` already gets
this right for `currency` and `channel`, which is a useful contrast to point
out in review.

---

## 5. `distinct_merchants` — `ecl/Transforms/Rollup_CustomerSpend.ecl`

```ecl
UNSIGNED4 distinct_merchants := COUNT(GROUP)
```

Copy-paste from `txn_count` two lines up. It counts transactions, not
merchants. Customer `3001` in the test fixture has 3 transactions across 2
merchants; customer `C-1006` in the sample data has 5 transactions at 2
merchants.

**Fix.** ECL has no `COUNT(DISTINCT x)` inside `TABLE`. Two options:

1. Pre-deduplicate, then join a second aggregate on:

```ecl
merchantPairs := DEDUP(SORT(valid, customer_id, merchant),
                       customer_id, merchant);

merchantCounts := TABLE(merchantPairs,
                        {customer_id,
                         UNSIGNED4 distinct_merchants := COUNT(GROUP)},
                        customer_id, MERGE);
```

then `JOIN` it to `spend` on `customer_id`. Two passes, but each is cheap
and the intent is obvious.

2. Aggregate into a child dataset and count it, with `AGGREGATE`. Denser,
   and harder to read six months later.

Option 1 is the right default here. Mention that the `DEDUP` needs the
`SORT` in front of it — same lesson as exercise 8.

---

## 6. High-value in the wrong currency — `ecl/Analytics/FraudScore.ecl`

```ecl
highValue := PROJECT(
  inTxns(amount >= Constants.HighValueThreshold), ...
```

**Mistake one:** every other rule filters `inTxns(is_valid)`; this one does
not. `BWR_BuildCustomerBase` passes the *unfiltered* `cleanTxns` into
`FraudScore`, so invalid rows reach this rule and only this rule.

**Mistake two:** `HighValueThreshold` is 10000.00 *dollars*, compared
against `amount` in whatever currency the transaction carries. `T-500043`
is ¥15,800 — about $105 — and trips the rule. Today the missing `is_valid`
filter is the only thing that lets it through, because JPY is not in
`SupportedCurrencies`. Add JPY to that set tomorrow and the currency bug
becomes live with no code change.

**Fix both:**

```ecl
usdTxns := inTxns(is_valid, currency = 'USD');
highValue := PROJECT(usdTxns(amount >= Constants.HighValueThreshold), ...
```

...or, better, convert to a base currency first and make that explicit.
A comment saying "threshold is USD" is not a fix; the type system should
carry it. A reasonable answer introduces an `amount_usd` field in
`Layouts.Transaction` and an FX reference dataset in `Common`, and notes
that this is a bigger change than the exercise strictly needs.

---

## 7. Packed-date arithmetic — `ecl/Analytics/FraudScore.ecl`

```ecl
LEFT.txn_date <= RIGHT.signup_date + 30
```

`signup_date` is `UNSIGNED4` holding `YYYYMMDD`. Adding 30 adds thirty to
the *day component of a decimal integer*, which is only coincidentally
correct. Worked examples:

| signup | `+30` | means | actual 30 days later |
|---|---|---|---|
| 20230601 | 20230631 | a bound past the end of June | 20230701 |
| 20230125 | 20230155 | a bound inside January | 20230224 |
| 20231215 | 20231245 | a bound inside December | 20240114 |

So the window is silently *shorter* than 30 days near a month end, and
never crosses a month boundary at all. A customer who signed up on
2023-01-25 and wired money on 2023-02-10 — 16 days later — is not flagged,
because `20230210 > 20230155`.

**Fix:** use `STD.Date`, which exists for exactly this.

```ecl
IMPORT STD;

windowEnd := STD.Date.AdjustDate(RIGHT.signup_date, day_delta := 30);
...
LEFT.txn_date >= RIGHT.signup_date AND LEFT.txn_date <= windowEnd
```

`STD.Date.AdjustCalendar` and `STD.Date.DaysBetween` are the other two to
know. Grep the repo for `+ 30`, `DIV 10000` and `% 10000` afterwards:
`Utils.AgeAt` and `CohortAnalysis` do the same packed-integer trick.
`AgeAt` is correct (it compares `MMDD` rather than adding to it) and
`cohort_year := signup_date DIV 10000` is correct; a good answer says so
rather than "fixing" working code.

**Bonus:** the join condition puts a non-equality comparison in a `LOOKUP`
join. It works, but it is worth saying out loud that the equality on
`customer_id` is what makes it viable.

---

## 8. Non-deterministic dedup — `ecl/Transforms/Dedup_Customers.ecl`

```ecl
sorted  := SORT(inCustomers, last_name, first_name, dob);
deduped := DEDUP(sorted, last_name, first_name, dob);
```

`DEDUP` keeps the **first** row of each group. The sort key is exactly the
dedup key, so within a group the order is whatever the sort implementation
produced — unstable, and on a multi-node Thor, dependent on how the data
happened to be distributed. `C-1001` and `C-1017` are the same Ada
Lovelace with different ids and signup dates; either can win, and the
winner can change between runs of identical input.

This is the nastiest defect in the repo because nothing fails. It shows up
much later as a profile whose `signup_date` moved.

**Fix:** extend the sort so the tie is broken by data, and say which row
wins and why.

```ecl
/**
 * One row per person. Duplicates arise when somebody signs up again with
 * the same details, so we keep the ORIGINAL registration: earliest
 * signup_date, and the lowest customer_id if two share a date.
 */
sorted  := SORT(inCustomers, last_name, first_name, dob,
                signup_date, customer_id);
deduped := DEDUP(sorted, last_name, first_name, dob);
```

Add `, LOCAL` only if the dataset is already distributed by the dedup key;
without that it is a correctness bug on a cluster.

A regression test needs both Ada rows in the fixture, asserting the
surviving `customer_id`:

```ecl
ASSERT(byName('LOVELACE')[1].customer_id = 1001,
       'Dedup should keep the earliest signup', FAIL),
ASSERT(COUNT(byName('LOVELACE')) = 1,
       'Dedup should leave exactly one Ada', FAIL),
```

---

## 9. Unkeyed read in a Roxie query — `ecl/Roxie/SearchByName.ecl`

```ecl
matches := Files.DS_Profile(
  last_name = searchLast,
  searchFirst = '' OR first_name[1..LENGTH(searchFirst)] = searchFirst
);
```

`DS_Profile` is the base file on Thor. In Roxie this is a full scan of every
customer on every query — and `Common.Files.IDX_ProfileByName`, keyed on
`{last_name, first_name, customer_id}`, is already built for it by the BWR.

**Fix:**

```ecl
matches := Files.IDX_ProfileByName(
  KEYED(last_name = searchLast),
  KEYED(first_name[1..LENGTH(searchFirst)] = searchFirst) OR searchFirst = ''
);
```

The honest version is subtler, and that is the real lesson: only a leading
component of the key can be keyed. `last_name` is the first key component,
so `KEYED` applies cleanly. The first-name *prefix* can be keyed as a
sub-string filter on the second component, but the `OR searchFirst = ''`
makes the whole expression non-keyable — the optimiser cannot key a
disjunction. Two clean answers:

1. Branch on the input so each path is fully keyed:

```ecl
byLast  := Files.IDX_ProfileByName(KEYED(last_name = searchLast));
byBoth  := Files.IDX_ProfileByName(
             KEYED(last_name = searchLast),
             KEYED(first_name[1..LENGTH(searchFirst)] = searchFirst));
matches := IF(searchFirst = '', byLast, byBoth);
```

2. Key on `last_name` only and leave the prefix as a `WILD`/unkeyed filter
   on the much smaller result — fine, because it is applied to one surname's
   worth of rows rather than the whole file.

Ask for the generated graph, or `#OPTION('outputResourcedGraph', TRUE)`, to
see the difference between an index read and a disk read.
