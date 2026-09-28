/**
 * Analytics.FraudScore
 *
 * Emits one Layouts.FraudSignal row per (transaction, rule) that fires.
 * Scores are additive and are clamped to 100 by the consumer, so weights
 * are "how suspicious is this on its own", not "share of a 100 point pie".
 *
 * Rules
 *   HIGH_VALUE        single transaction at or above the high value limit
 *   SAME_DAY_VELOCITY more than VelocityTxnLimit transactions in one day
 *   REPEAT_AMOUNT     identical amount at the same merchant, 3+ times
 *   NEW_ACCOUNT_WIRE  wire transfer within 30 days of signup
 */
IMPORT $.^.Common;

Layouts   := Common.Layouts;
Constants := Common.Constants;

EXPORT FraudScore(DATASET(Layouts.Transaction) inTxns,
                  DATASET(Layouts.Customer)    inCustomers) := FUNCTION

  // --- HIGH_VALUE -------------------------------------------------------

  highValue := PROJECT(
    inTxns(amount >= Constants.HighValueThreshold),
    TRANSFORM(Layouts.FraudSignal,
      SELF.customer_id := LEFT.customer_id,
      SELF.txn_id      := LEFT.txn_id,
      SELF.signal      := 'HIGH_VALUE',
      SELF.weight      := 40
    )
  );

  // --- SAME_DAY_VELOCITY ------------------------------------------------

  perDay := TABLE(
    inTxns(is_valid),
    {customer_id, txn_date, UNSIGNED4 day_count := COUNT(GROUP)},
    customer_id, txn_date,
    FEW
  );

  busyDays := perDay(day_count > Constants.VelocityTxnLimit);

  velocity := JOIN(
    inTxns(is_valid),
    busyDays,
    LEFT.customer_id = RIGHT.customer_id AND LEFT.txn_date = RIGHT.txn_date,
    TRANSFORM(Layouts.FraudSignal,
      SELF.customer_id := LEFT.customer_id,
      SELF.txn_id      := LEFT.txn_id,
      SELF.signal      := 'SAME_DAY_VELOCITY',
      SELF.weight      := 30
    ),
    LOOKUP
  );

  // --- REPEAT_AMOUNT ----------------------------------------------------

  repeats := TABLE(
    inTxns(is_valid),
    {customer_id, merchant, amount, UNSIGNED4 hits := COUNT(GROUP)},
    customer_id, merchant, amount,
    MERGE
  );

  repeatAmount := JOIN(
    inTxns(is_valid),
    repeats(hits >= 3),
    LEFT.customer_id = RIGHT.customer_id
      AND LEFT.merchant = RIGHT.merchant
      AND LEFT.amount = RIGHT.amount,
    TRANSFORM(Layouts.FraudSignal,
      SELF.customer_id := LEFT.customer_id,
      SELF.txn_id      := LEFT.txn_id,
      SELF.signal      := 'REPEAT_AMOUNT',
      SELF.weight      := 35
    ),
    LOOKUP
  );

  // --- NEW_ACCOUNT_WIRE -------------------------------------------------

  newAccountWire := JOIN(
    inTxns(is_valid AND channel = 'WIRE'),
    inCustomers,
    LEFT.customer_id = RIGHT.customer_id
      AND LEFT.txn_date >= RIGHT.signup_date
      AND LEFT.txn_date <= RIGHT.signup_date + 30,
    TRANSFORM(Layouts.FraudSignal,
      SELF.customer_id := LEFT.customer_id,
      SELF.txn_id      := LEFT.txn_id,
      SELF.signal      := 'NEW_ACCOUNT_WIRE',
      SELF.weight      := 25
    ),
    LOOKUP
  );

  allSignals := highValue + velocity + repeatAmount + newAccountWire;

  RETURN SORT(allSignals, customer_id, txn_id, signal);
END;
