/**
 * Tests.Test_FraudScore
 *
 * Rule-by-rule tests for Analytics.FraudScore.
 */
IMPORT $.^.Common;
IMPORT $.^.Analytics;

EXPORT Test_FraudScore := MODULE

  SHARED Layouts := Common.Layouts;

  SHARED custFixture := DATASET([
    {4001, 'HIGH',  'ROLLER',  19800101, 43, 'high@example.com',
     '1 St', 'BOSTON', 'MA', '02108', 'US', 20230101, TRUE, ''},
    {4002, 'BUSY',  'SHOPPER', 19900101, 33, 'busy@example.com',
     '2 St', 'BOSTON', 'MA', '02108', 'US', 20220101, TRUE, ''},
    {4003, 'BRAND', 'NEW',     19950101, 28, 'new@example.com',
     '3 St', 'BOSTON', 'MA', '02108', 'US', 20230601, TRUE, ''}
  ], Layouts.Customer);

  //          txn  cust  date      amount    ccy    merchant      mcc   channel  valid
  SHARED txnFixture := DATASET([
    {1, 4001, 20230201, 15000.00, 'USD', 'BIG TICKET',  5734, 'WIRE', TRUE},
    {2, 4002, 20230301,    10.00, 'USD', 'CAFE',        5814, 'CARD', TRUE},
    {3, 4002, 20230301,    11.00, 'USD', 'CAFE',        5814, 'CARD', TRUE},
    {4, 4002, 20230301,    12.00, 'USD', 'CAFE',        5814, 'CARD', TRUE},
    {5, 4002, 20230301,    13.00, 'USD', 'CAFE',        5814, 'CARD', TRUE},
    {6, 4002, 20230301,    14.00, 'USD', 'CAFE',        5814, 'CARD', TRUE},
    {7, 4003, 20230610,  5000.00, 'USD', 'WIRE HOUSE',  6012, 'WIRE', TRUE},
    {8, 4003, 20230611,   500.00, 'USD', 'REPEATER',    5999, 'CARD', TRUE},
    {9, 4003, 20230612,   500.00, 'USD', 'REPEATER',    5999, 'CARD', TRUE},
   {10, 4003, 20230613,   500.00, 'USD', 'REPEATER',    5999, 'CARD', TRUE},
   {11, 4001, 20230401, 15800.00, 'JPY', 'TOKYO MOTORS',5511, 'WIRE', FALSE}
  ], Layouts.Transaction);

  SHARED signals := Analytics.FraudScore(txnFixture, custFixture);

  EXPORT Run := SEQUENTIAL(

    // HIGH_VALUE
    ASSERT(EXISTS(signals(txn_id = 1, signal = 'HIGH_VALUE')),
           'A 15000 transaction should raise HIGH_VALUE', FAIL),
    ASSERT(NOT EXISTS(signals(txn_id = 2, signal = 'HIGH_VALUE')),
           'A 10.00 transaction should not raise HIGH_VALUE', FAIL),

    // SAME_DAY_VELOCITY: five transactions on one day, limit is four.
    ASSERT(COUNT(signals(signal = 'SAME_DAY_VELOCITY')) = 5,
           'Every transaction on a busy day should be flagged', FAIL),
    ASSERT(NOT EXISTS(signals(customer_id = 4001, signal = 'SAME_DAY_VELOCITY')),
           'A single transaction per day should not trip velocity', FAIL),

    // REPEAT_AMOUNT: three identical amounts at one merchant.
    ASSERT(COUNT(signals(signal = 'REPEAT_AMOUNT')) = 3,
           'Three identical amounts should each be flagged', FAIL),

    // NEW_ACCOUNT_WIRE: signed up 2023-06-01, wired on 2023-06-10.
    ASSERT(EXISTS(signals(txn_id = 7, signal = 'NEW_ACCOUNT_WIRE')),
           'A wire nine days after signup should be flagged', FAIL),
    ASSERT(NOT EXISTS(signals(txn_id = 1, signal = 'NEW_ACCOUNT_WIRE')),
           'A wire a month after signup should not be flagged', FAIL),

    // TODO(exercise 6): transaction 11 failed validation and is priced in
    // a currency we do not support. Uncomment, watch it fail, then fix.
    // ASSERT(NOT EXISTS(signals(txn_id = 11)),
    //        'Invalid transactions should raise no signals', FAIL),

    OUTPUT('Test_FraudScore: PASS')
  );

END;
