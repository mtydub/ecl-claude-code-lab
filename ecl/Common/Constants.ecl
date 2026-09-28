/**
 * Common.Constants
 *
 * Project-wide tunables. Anything that a reviewer might want to change
 * without reading the dataflow code belongs here.
 */
EXPORT Constants := MODULE

  // Every logical file this project writes lives under this scope.
  EXPORT STRING FileScope := '~ecl_playground::';

  // Business rules -----------------------------------------------------
  EXPORT UNSIGNED2  MinAdultAge         := 18;
  EXPORT UNSIGNED2  MaxPlausibleAge     := 110;
  EXPORT DECIMAL12_2 HighValueThreshold := 10000.00;
  EXPORT UNSIGNED1  FraudScoreCutoff    := 70;
  EXPORT UNSIGNED2  VelocityWindowDays  := 1;
  EXPORT UNSIGNED2  VelocityTxnLimit    := 4;

  // Reference data -----------------------------------------------------
  EXPORT SET OF STRING2 SupportedCountries := ['US', 'CA', 'GB', 'AU', 'SG'];
  EXPORT SET OF STRING3 SupportedCurrencies := ['USD', 'CAD', 'GBP', 'AUD', 'SGD'];
  EXPORT SET OF STRING10 ValidChannels := ['CARD', 'ONLINE', 'WIRE', 'REFUND'];

  // Date used as "now" so that results are reproducible in tests.
  EXPORT UNSIGNED4 AsOfDate := 20231231;

END;
