/**
 * Transform.Orphan_Transactions
 *
 * Transactions whose customer_id does not exist in the customer base.
 * These are a data quality signal, not an error: report them, do not drop
 * them silently.
 */
IMPORT $.^.Common;

Layouts := Common.Layouts;

EXPORT Orphan_Transactions(DATASET(Layouts.Transaction) inTxns,
                           DATASET(Layouts.Customer)    inCustomers) := FUNCTION

  RETURN JOIN(
    inTxns,
    inCustomers,
    LEFT.customer_id = RIGHT.customer_id,
    TRANSFORM(LEFT),
    LEFT ONLY,
    LOOKUP
  );
END;
