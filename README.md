# ecl-claude-code-lab

A realistic, self-contained [HPCC Systems ECL](https://hpccsystems.com/)
project to practise on — built to be read, refactored, broken and fixed
with [Claude Code](https://claude.com/claude-code).

It is a customer analytics pipeline. Two messy CSV feeds go in; a
deduplicated customer base, a spend rollup, fraud signals, an indexed
serving record and two Roxie queries come out. About 800 lines of ECL, a
test suite, a linter, and a set of graded exercises — six of which are real
defects planted in the code on purpose.

You do **not** need an HPCC cluster to get value from this repo. Most of the
exercises are reading, tracing, reviewing and editing; the linter runs
anywhere. A cluster only matters if you want to execute the pipeline.

## The pipeline

```
data/customers_raw.csv ──┐
                         ├─> BWR_SprayLanding ──> in::customers_raw
data/transactions_raw.csv┘                           in::transactions_raw
                                                            │
                        Ingest.CleanCustomers / CleanTransactions
                                                            │
                          ┌─────────────────────────────────┴──────┐
                          │                                        │
          Transforms.Dedup_Customers                  (is_valid = FALSE)
                          │                                qa::customer_rejects
        ┌─────────────────┼──────────────────┐
        │                 │                  │
Transforms.Rollup   Analytics.FraudScore   Transforms.Orphan_Transactions
  _CustomerSpend            │
        └─────────┬─────────┘
                  │
     Transforms.Join_CustomerTransactions
                  │
          base::customer_profile
                  │
      ┌───────────┴───────────┐
key::profile_by_id    key::profile_by_name
      │                       │
Roxie.GetCustomerProfile  Roxie.SearchByName
```

`ecl/BWR/BWR_BuildCustomerBase.ecl` is that whole diagram as one workunit.

## Start here

```bash
git clone <your-fork-url> ecl-claude-code-lab
cd ecl-claude-code-lab
claude
```

Then, in Claude Code:

```
Read CLAUDE.md, then trace the dataflow from data/customers_raw.csv all the
way to Roxie.GetCustomerProfile. Name every file a row passes through and
what each one does to it.
```

That is exercise 1. The rest are in [docs/EXERCISES.md](docs/EXERCISES.md),
graded from "read the code" to "find the bug nobody documented". The answer
key is in [docs/SOLUTIONS.md](docs/SOLUTIONS.md) — try not to peek.

New to ECL? [docs/ECL_PRIMER.md](docs/ECL_PRIMER.md) is a 10-minute tour of
the language as it is actually used here.

## Checks

```bash
./scripts/lint.sh
```

Style checks in pure bash — no HPCC install needed, so this is the loop to
use while editing. With the
[client tools](https://hpccsystems.com/download/) installed:

```bash
./scripts/syntax_check.sh    # compile every attribute (eclcc -syntax)
./scripts/run_tests.sh       # run ecl/Tests on hthor
```

## Running it for real

Against a local [HPCC container or VM](https://hpccsystems.com/download/):

```bash
# 1. copy the CSVs to your dropzone, then spray them
ecl run thor ecl/BWR/BWR_SprayLanding.ecl -I ecl \
    -XSourceIP=127.0.0.1 -XSourceDir=/var/lib/HPCCSystems/mydropzone/

# 2. build every base file and index
ecl run thor ecl/BWR/BWR_BuildCustomerBase.ecl -I ecl

# 3. publish the queries
ecl publish roxie ecl/Roxie/GetCustomerProfile.ecl -I ecl \
    --name=getcustomerprofile --activate
ecl publish roxie ecl/Roxie/SearchByName.ecl -I ecl \
    --name=searchbyname --activate
```

The sample data is 30 customers and 60 transactions of synthetic nonsense,
named after people who wrote compilers. It contains mixed date formats,
mixed-case country codes, a missing name, a broken email, exact-duplicate
signups, refunds, foreign currencies and one orphan transaction — because a
clean fixture teaches you nothing about cleaning data.

## Licence

MIT. See [LICENSE](LICENSE).
