/**
 * Tests.Test_CleanCustomers
 *
 * Validation and rejection behaviour of Ingest.CleanCustomers, driven by
 * an inline fixture so it never touches the cluster's files.
 */
IMPORT $.^.Common;
IMPORT $.^.Ingest;

EXPORT Test_CleanCustomers := MODULE

  SHARED Layouts := Common.Layouts;

  SHARED fixture := DATASET([
    {'C-2001', 'Ada',   'Lovelace', '1985-12-10', 'ada@example.com',
     '1 St', 'Boston',     'MA', '02108', 'US', '2019-03-14'},
    {'C-2002', 'Grace', 'Hopper',   '1980/06/09', 'grace@example.com',
     '2 St', 'Arlington',  'VA', '22201', 'us', '2019-04-02'},
    {'C-2003', 'Jean',  'Bartik',   '1990-12-27', 'jean@example',
     '3 St', 'Philadelphia', 'PA', '19103', 'US', '2019-06-01'},
    {'C-2004', '',      'Wirth',    '1963-02-15', 'wirth@example.com',
     '4 St', 'Zurich',     '',   '8001',  'US', '2021-03-23'},
    {'C-2005', 'Alan',  'Turing',   'not-a-date', 'alan@example.com',
     '5 St', 'Cambridge',  'MA', '02139', 'US', '2019-04-02'},
    {'XXXX',   'Ken',   'Thompson', '1966-02-04', 'ken@example.com',
     '6 St', 'Palo Alto',  'CA', '94301', 'US', '2021-01-04'}
  ], Layouts.CustomerRaw);

  SHARED cleaned := Ingest.CleanCustomers(fixture);

  SHARED byId(UNSIGNED4 id) := cleaned(customer_id = id);

  EXPORT Run := SEQUENTIAL(

    ASSERT(COUNT(cleaned) = COUNT(fixture),
           'CleanCustomers must not drop rows', FAIL),

    // A clean row survives with typed, normalised values.
    ASSERT(byId(2001)[1].is_valid,
           'A well formed row should be valid', FAIL),
    ASSERT(byId(2001)[1].first_name = 'ADA',
           'Names should be upper-cased', FAIL),
    ASSERT(byId(2001)[1].dob = 19851210,
           'DOB should be packed to YYYYMMDD', FAIL),
    ASSERT(byId(2001)[1].age = 38,
           'Age should be derived from DOB and AsOfDate', FAIL),
    ASSERT(TRIM(byId(2001)[1].reject_reason) = '',
           'A valid row should carry no reject reason', FAIL),

    // Each failure mode reports itself.
    ASSERT(byId(2003)[1].reject_reason = 'BAD_EMAIL',
           'A malformed email should be rejected as BAD_EMAIL', FAIL),
    ASSERT(byId(2004)[1].reject_reason = 'MISSING_FIRST_NAME',
           'A blank first name should be rejected', FAIL),
    ASSERT(byId(2005)[1].reject_reason = 'UNPARSEABLE_DOB',
           'An unparseable DOB should be rejected', FAIL),
    ASSERT(byId(0)[1].reject_reason = 'MISSING_CUSTOMER_ID',
           'A non-numeric customer id should be rejected', FAIL),

    // TODO(exercise 4): country codes arrive in mixed case from the feed.
    // Uncomment this assertion, watch it fail, then fix the source.
    // ASSERT(byId(2002)[1].is_valid,
    //        'A lower-case supported country should be accepted', FAIL),

    OUTPUT('Test_CleanCustomers: PASS')
  );

END;
