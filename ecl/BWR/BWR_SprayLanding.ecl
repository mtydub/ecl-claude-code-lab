/**
 * BWR.BWR_SprayLanding
 *
 * Sprays the two CSVs in /data onto Thor. Run this once against your own
 * cluster before anything else; it is the only code here that talks to the
 * DFU rather than to data.
 *
 * Copy data/*.csv into your dropzone first, then:
 *
 *   ecl run thor ecl/BWR/BWR_SprayLanding.ecl -I ecl \
 *       -XSourceIP=127.0.0.1 \
 *       -XSourceDir=/var/lib/HPCCSystems/mydropzone/ \
 *       -XCluster=mythor
 */
IMPORT STD;
IMPORT $.^.Common;

Files := Common.Files;

STRING SourceIP  := '127.0.0.1' : STORED('SourceIP');
STRING SourceDir := '/var/lib/HPCCSystems/mydropzone/' : STORED('SourceDir');
STRING Cluster   := 'mythor' : STORED('Cluster');

sprayCustomers := STD.File.SprayVariable(
  SourceIP,
  SourceDir + 'customers_raw.csv',
  ,                             // maxRecordSize: default
  ',',                          // separator
  '\n',                         // terminator
  '"',                          // quote
  Cluster,
  Files.CustomersRawName,
  ,                             // timeout
  ,                             // espServerIPPort
  ,                             // maxConnections
  TRUE,                         // allowOverwrite
  TRUE                          // replicate
);

sprayTxns := STD.File.SprayVariable(
  SourceIP,
  SourceDir + 'transactions_raw.csv',
  ,
  ',',
  '\n',
  '"',
  Cluster,
  Files.TxnsRawName,
  ,
  ,
  ,
  TRUE,
  TRUE
);

SEQUENTIAL(
  sprayCustomers,
  sprayTxns,
  OUTPUT(COUNT(Files.DS_CustomersRaw), NAMED('SprayedCustomerRows')),
  OUTPUT(COUNT(Files.DS_TxnsRaw),      NAMED('SprayedTxnRows'))
);
