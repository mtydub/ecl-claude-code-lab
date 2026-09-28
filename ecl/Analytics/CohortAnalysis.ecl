/**
 * Analytics.CohortAnalysis
 *
 * Signup-year cohorts crossed with spend bands. The kind of table you
 * hand to somebody who asks "are the customers we acquired in 2020 worth
 * more than the ones we acquired in 2019?".
 */
IMPORT $.^.Common;

Layouts := Common.Layouts;

EXPORT CohortAnalysis(DATASET(Layouts.CustomerProfile) inProfiles) := MODULE

  SHARED banded := PROJECT(
    inProfiles(is_valid),
    TRANSFORM(
      {
        UNSIGNED2   cohort_year;
        STRING12    spend_band;
        DECIMAL12_2 total_amount;
        UNSIGNED1   fraud_score;
      },
      SELF.cohort_year := LEFT.signup_date DIV 10000,
      SELF.spend_band  := MAP(
        LEFT.total_amount =      0 => '0_NONE',
        LEFT.total_amount <    100 => '1_UNDER_100',
        LEFT.total_amount <   1000 => '2_UNDER_1K',
        LEFT.total_amount <  10000 => '3_UNDER_10K',
                                      '4_10K_PLUS'
      ),
      SELF.total_amount := LEFT.total_amount,
      SELF.fraud_score  := LEFT.fraud_score
    )
  );

  EXPORT ByCohort := TABLE(
    banded,
    {
      cohort_year,
      UNSIGNED4   customers    := COUNT(GROUP),
      DECIMAL12_2 total_spend  := SUM(GROUP, banded.total_amount),
      DECIMAL12_2 avg_spend    := AVE(GROUP, banded.total_amount),
      REAL8       avg_fraud    := AVE(GROUP, banded.fraud_score)
    },
    cohort_year,
    FEW
  );

  EXPORT ByCohortAndBand := TABLE(
    banded,
    {
      cohort_year,
      spend_band,
      UNSIGNED4   customers   := COUNT(GROUP),
      DECIMAL12_2 total_spend := SUM(GROUP, banded.total_amount)
    },
    cohort_year, spend_band,
    FEW
  );

END;
