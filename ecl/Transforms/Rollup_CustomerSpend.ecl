/**
 * Transform.Rollup_CustomerSpend
 *
 * One row per customer summarising their transaction history.
 */
IMPORT $.^.Common;

Layouts := Common.Layouts;

EXPORT Rollup_CustomerSpend(DATASET(Layouts.Transaction) inTxns) := FUNCTION

  valid := inTxns(is_valid);

  spend := TABLE(
    valid,
    {
      customer_id,
      UNSIGNED4   txn_count          := COUNT(GROUP),
      DECIMAL12_2 total_amount       := SUM(GROUP, valid.amount),
      DECIMAL12_2 avg_amount         := AVE(GROUP, valid.amount),
      DECIMAL12_2 max_amount         := MAX(GROUP, valid.amount),
      UNSIGNED4   first_txn_date     := MIN(GROUP, valid.txn_date),
      UNSIGNED4   last_txn_date      := MAX(GROUP, valid.txn_date),
      UNSIGNED4   distinct_merchants := COUNT(GROUP)
    },
    customer_id,
    MERGE
  );

  RETURN PROJECT(spend, TRANSFORM(Layouts.CustomerSpend, SELF := LEFT));
END;
