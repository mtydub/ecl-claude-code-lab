/**
 * Tests.Test_Rollup_CustomerSpend
 *
 * Aggregation arithmetic for Transforms.Rollup_CustomerSpend.
 */
IMPORT $.^.Common;
IMPORT $.^.Transforms;

EXPORT Test_Rollup_CustomerSpend := MODULE

  SHARED Layouts := Common.Layouts;

  //          txn  cust  date      amount  ccy    merchant      mcc   channel  valid
  SHARED fixture := DATASET([
    {1, 3001, 20230101, 100.00, 'USD', 'MERCHANT A', 5814, 'CARD',   TRUE},
    {2, 3001, 20230115,  50.00, 'USD', 'MERCHANT A', 5814, 'CARD',   TRUE},
    {3, 3001, 20230220,  25.00, 'USD', 'MERCHANT B', 5411, 'CARD',   TRUE},
    {4, 3002, 20230305, 900.00, 'USD', 'MERCHANT C', 7372, 'WIRE',   TRUE},
    {5, 3002, 20230306, -50.00, 'USD', 'MERCHANT C', 7372, 'REFUND', TRUE},
    {6, 3003, 20230401, 777.00, 'JPY', 'MERCHANT D', 5511, 'WIRE',   FALSE}
  ], Layouts.Transaction);

  SHARED spend := Transforms.Rollup_CustomerSpend(fixture);

  SHARED byId(UNSIGNED4 id) := spend(customer_id = id);

  EXPORT Run := SEQUENTIAL(

    ASSERT(COUNT(spend) = 2,
           'Invalid transactions should not create a spend row', FAIL),

    ASSERT(byId(3001)[1].txn_count = 3,
           'txn_count should count every valid transaction', FAIL),
    ASSERT(byId(3001)[1].total_amount = 175.00,
           'total_amount should sum the valid transactions', FAIL),
    ASSERT(byId(3001)[1].avg_amount = 58.33,
           'avg_amount should be the mean, rounded to cents', FAIL),
    ASSERT(byId(3001)[1].max_amount = 100.00,
           'max_amount should be the largest transaction', FAIL),
    ASSERT(byId(3001)[1].first_txn_date = 20230101,
           'first_txn_date should be the earliest date', FAIL),
    ASSERT(byId(3001)[1].last_txn_date = 20230220,
           'last_txn_date should be the latest date', FAIL),

    // Refunds are negative and must net out rather than be dropped.
    ASSERT(byId(3002)[1].total_amount = 850.00,
           'Refunds should reduce total_amount', FAIL),

    // TODO(exercise 5): customer 3001 shopped at two merchants, not three.
    // Uncomment this assertion, watch it fail, then fix the source.
    // ASSERT(byId(3001)[1].distinct_merchants = 2,
    //        'distinct_merchants should count distinct merchants', FAIL),

    OUTPUT('Test_Rollup_CustomerSpend: PASS')
  );

END;
