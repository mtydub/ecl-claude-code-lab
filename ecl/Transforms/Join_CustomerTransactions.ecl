/**
 * Transform.Join_CustomerTransactions
 *
 * Builds the serving record: customer + spend rollup + fraud score +
 * a nested child dataset of their most recent transactions.
 */
IMPORT $.^.Common;

Layouts := Common.Layouts;

EXPORT Join_CustomerTransactions(
    DATASET(Layouts.Customer)      inCustomers,
    DATASET(Layouts.Transaction)   inTxns,
    DATASET(Layouts.CustomerSpend) inSpend,
    DATASET(Layouts.FraudSignal)   inSignals,
    UNSIGNED2                      recentLimit = 5) := FUNCTION

  // Customer + spend. Customers with no transactions still get a profile.
  withSpend := JOIN(
    inCustomers,
    inSpend,
    LEFT.customer_id = RIGHT.customer_id,
    TRANSFORM(Layouts.CustomerProfile,
      SELF.fraud_score := 0,
      SELF.recent_txns := DATASET([], Layouts.Transaction),
      SELF := LEFT,      // customer first: RIGHT.customer_id is 0 when unmatched
      SELF := RIGHT
    ),
    LEFT OUTER,
    LOOKUP
  );

  // Attach the newest N transactions per customer.
  Layouts.CustomerProfile addTxns(Layouts.CustomerProfile L,
                                  DATASET(Layouts.Transaction) R) := TRANSFORM
    SELF.recent_txns := CHOOSEN(SORT(R, -txn_date, -amount), recentLimit);
    SELF := L;
  END;

  withTxns := DENORMALIZE(
    withSpend,
    inTxns(is_valid),
    LEFT.customer_id = RIGHT.customer_id,
    GROUP,
    addTxns(LEFT, ROWS(RIGHT))
  );

  // Fold the fraud signal weights into a single score.
  scores := TABLE(
    inSignals,
    {customer_id, UNSIGNED4 score := SUM(GROUP, inSignals.weight)},
    customer_id,
    FEW
  );

  withScore := JOIN(
    withTxns,
    scores,
    LEFT.customer_id = RIGHT.customer_id,
    TRANSFORM(Layouts.CustomerProfile,
      SELF.fraud_score := (UNSIGNED1)MIN(RIGHT.score, 100),
      SELF := LEFT
    ),
    LEFT OUTER,
    LOOKUP
  );

  RETURN withScore;
END;
