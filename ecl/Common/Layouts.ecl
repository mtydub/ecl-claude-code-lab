/**
 * Common.Layouts
 *
 * Record definitions for every stage of the pipeline.
 *
 *   *Raw    -> exactly what lands on disk from the source system (all STRING)
 *   (clean) -> typed, validated, ready to join
 */
EXPORT Layouts := MODULE

  // --- Raw (as sprayed) ------------------------------------------------

  EXPORT CustomerRaw := RECORD
    STRING customer_id;
    STRING first_name;
    STRING last_name;
    STRING dob;
    STRING email;
    STRING street;
    STRING city;
    STRING state;
    STRING zip;
    STRING country;
    STRING signup_date;
  END;

  EXPORT TransactionRaw := RECORD
    STRING txn_id;
    STRING customer_id;
    STRING txn_date;
    STRING amount;
    STRING currency;
    STRING merchant;
    STRING mcc;
    STRING channel;
  END;

  // --- Cleaned ---------------------------------------------------------

  EXPORT Customer := RECORD
    UNSIGNED4   customer_id;
    STRING25    first_name;
    STRING25    last_name;
    UNSIGNED4   dob;           // YYYYMMDD, 0 when unparseable
    UNSIGNED2   age;
    STRING60    email;
    STRING50    street;
    STRING30    city;
    STRING2     state;
    STRING10    zip;
    STRING2     country;
    UNSIGNED4   signup_date;   // YYYYMMDD
    BOOLEAN     is_valid;
    STRING      reject_reason {MAXLENGTH(120)};
  END;

  EXPORT Transaction := RECORD
    UNSIGNED4   txn_id;
    UNSIGNED4   customer_id;
    UNSIGNED4   txn_date;      // YYYYMMDD
    DECIMAL12_2 amount;
    STRING3     currency;
    STRING40    merchant;
    UNSIGNED2   mcc;
    STRING10    channel;
    BOOLEAN     is_valid;
  END;

  // --- Aggregates ------------------------------------------------------

  EXPORT CustomerSpend := RECORD
    UNSIGNED4   customer_id;
    UNSIGNED4   txn_count;
    DECIMAL12_2 total_amount;
    DECIMAL12_2 avg_amount;
    DECIMAL12_2 max_amount;
    UNSIGNED4   first_txn_date;
    UNSIGNED4   last_txn_date;
    UNSIGNED4   distinct_merchants;
  END;

  EXPORT FraudSignal := RECORD
    UNSIGNED4   customer_id;
    UNSIGNED4   txn_id;
    STRING30    signal;
    UNSIGNED1   weight;
  END;

  // --- Serving ---------------------------------------------------------

  EXPORT CustomerProfile := RECORD
    Customer;
    UNSIGNED4   txn_count;
    DECIMAL12_2 total_amount;
    DECIMAL12_2 avg_amount;
    DECIMAL12_2 max_amount;
    UNSIGNED4   first_txn_date;
    UNSIGNED4   last_txn_date;
    UNSIGNED4   distinct_merchants;
    UNSIGNED1   fraud_score;
    DATASET(Transaction) recent_txns;
  END;

END;
