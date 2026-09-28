/**
 * BWR.BWR_BuildCustomerBase
 *
 * The whole batch pipeline, end to end. This is the file to run after
 * BWR_SprayLanding:
 *
 *   ecl run thor ecl/BWR/BWR_BuildCustomerBase.ecl -I ecl
 *
 * It is a "builder window run": a sequence of actions, not a definition
 * other code imports.
 */
IMPORT $.^.Common;
IMPORT $.^.Ingest;
IMPORT $.^.Transforms;
IMPORT $.^.Analytics;

Files := Common.Files;

// --- 1. clean ---------------------------------------------------------

cleanCust := Ingest.CleanCustomers(Files.DS_CustomersRaw);
cleanTxns := Ingest.CleanTransactions(Files.DS_TxnsRaw);

// --- 2. dedup and split out the rejects -------------------------------

goodCust    := Transforms.Dedup_Customers(cleanCust(is_valid));
rejectCust  := cleanCust(NOT is_valid);
goodTxns    := cleanTxns(is_valid);

// --- 3. aggregate and score -------------------------------------------

spend   := Transforms.Rollup_CustomerSpend(goodTxns);
signals := Analytics.FraudScore(cleanTxns, goodCust);
orphans := Transforms.Orphan_Transactions(goodTxns, goodCust);

// --- 4. build the serving record --------------------------------------

profiles := Transforms.Join_CustomerTransactions(goodCust, goodTxns, spend, signals);

// --- 5. write ---------------------------------------------------------

writeCust     := OUTPUT(goodCust,   , Files.CustomersName, OVERWRITE, COMPRESSED);
writeTxns     := OUTPUT(goodTxns,   , Files.TxnsName,      OVERWRITE, COMPRESSED);
writeSpend    := OUTPUT(spend,      , Files.SpendName,     OVERWRITE, COMPRESSED);
writeSignals  := OUTPUT(signals,    , Files.SignalsName,   OVERWRITE, COMPRESSED);
writeProfiles := OUTPUT(profiles,   , Files.ProfileName,   OVERWRITE, COMPRESSED);
writeRejects  := OUTPUT(rejectCust, , Files.RejectsName,   OVERWRITE, COMPRESSED);

buildIdxById   := BUILDINDEX(Files.IDX_ProfileById,   OVERWRITE);
buildIdxByName := BUILDINDEX(Files.IDX_ProfileByName, OVERWRITE);

// --- 6. QA summary ----------------------------------------------------

rejectSummary := TABLE(
  rejectCust,
  {reject_reason, UNSIGNED4 row_count := COUNT(GROUP)},
  reject_reason,
  FEW
);

qa := PARALLEL(
  OUTPUT(COUNT(Files.DS_CustomersRaw), NAMED('RawCustomerRows')),
  OUTPUT(COUNT(cleanCust(is_valid)),   NAMED('ValidCustomerRows')),
  OUTPUT(COUNT(goodCust),              NAMED('DedupedCustomerRows')),
  OUTPUT(COUNT(Files.DS_TxnsRaw),      NAMED('RawTxnRows')),
  OUTPUT(COUNT(goodTxns),              NAMED('ValidTxnRows')),
  OUTPUT(SORT(rejectSummary, -row_count),   NAMED('RejectReasons')),
  OUTPUT(CHOOSEN(orphans, 100),        NAMED('OrphanTransactions'))
);

SEQUENTIAL(
  PARALLEL(writeCust, writeTxns, writeSpend, writeSignals, writeRejects),
  writeProfiles,
  PARALLEL(buildIdxById, buildIdxByName),
  qa
);
