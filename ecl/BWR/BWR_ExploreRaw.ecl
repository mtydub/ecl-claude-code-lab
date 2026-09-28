/**
 * BWR.BWR_ExploreRaw
 *
 * Scratchpad for looking at the landed files before trusting them.
 * Nothing here writes to disk, so it is safe to run repeatedly.
 */
IMPORT $.^.Common;

Files := Common.Files;

OUTPUT(CHOOSEN(Files.DS_CustomersRaw, 20), NAMED('SampleCustomers'));
OUTPUT(CHOOSEN(Files.DS_TxnsRaw, 20),      NAMED('SampleTxns'));

Common.MAC_ProfileField(Files.DS_CustomersRaw, country);
Common.MAC_ProfileField(Files.DS_CustomersRaw, state);
Common.MAC_ProfileField(Files.DS_TxnsRaw, channel);
Common.MAC_ProfileField(Files.DS_TxnsRaw, currency);
