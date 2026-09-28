/**
 * Transform.Dedup_Customers
 *
 * The source system re-issues a customer id when somebody signs up again
 * with the same details, so (first_name, last_name, dob) can appear more
 * than once. We keep one row per person.
 */
IMPORT $.^.Common;

Layouts := Common.Layouts;

EXPORT Dedup_Customers(DATASET(Layouts.Customer) inCustomers) := FUNCTION

  sorted := SORT(inCustomers, last_name, first_name, dob);

  deduped := DEDUP(sorted, last_name, first_name, dob);

  RETURN deduped;
END;
