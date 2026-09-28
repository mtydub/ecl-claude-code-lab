/**
 * Tests.BWR_RunAllTests
 *
 * Runs every test module. Needs no sprayed data, so hthor is enough:
 *
 *   ecl run hthor ecl/Tests/BWR_RunAllTests.ecl -I ecl
 *
 * A failing ASSERT aborts the workunit, so a green run means every
 * module printed its PASS line.
 */
IMPORT $ AS Tests;

SEQUENTIAL(
  Tests.Test_Utils.Run,
  Tests.Test_CleanCustomers.Run,
  Tests.Test_Rollup_CustomerSpend.Run,
  Tests.Test_FraudScore.Run,
  OUTPUT('All test modules passed')
);
