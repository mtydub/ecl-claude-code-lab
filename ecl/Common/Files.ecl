/**
 * Common.Files
 *
 * Every logical file and index name in one place, plus the DATASET/INDEX
 * definitions that read them. Nothing else in the project should hard code
 * a '~scope::name' string.
 */
IMPORT $.Constants;
IMPORT $.Layouts;

EXPORT Files := MODULE

  // --- Logical file names ---------------------------------------------

  EXPORT STRING CustomersRawName  := Constants.FileScope + 'in::customers_raw';
  EXPORT STRING TxnsRawName       := Constants.FileScope + 'in::transactions_raw';
  EXPORT STRING CustomersName     := Constants.FileScope + 'base::customers';
  EXPORT STRING TxnsName          := Constants.FileScope + 'base::transactions';
  EXPORT STRING SpendName         := Constants.FileScope + 'base::customer_spend';
  EXPORT STRING SignalsName       := Constants.FileScope + 'base::fraud_signals';
  EXPORT STRING ProfileName       := Constants.FileScope + 'base::customer_profile';
  EXPORT STRING RejectsName       := Constants.FileScope + 'qa::customer_rejects';

  EXPORT STRING ProfileIdxName    := Constants.FileScope + 'key::profile_by_id';
  EXPORT STRING NameIdxName       := Constants.FileScope + 'key::profile_by_name';

  // --- Datasets --------------------------------------------------------

  EXPORT DS_CustomersRaw := DATASET(
    CustomersRawName,
    Layouts.CustomerRaw,
    CSV(HEADING(1), SEPARATOR(','), TERMINATOR(['\n', '\r\n']), QUOTE('"'))
  );

  EXPORT DS_TxnsRaw := DATASET(
    TxnsRawName,
    Layouts.TransactionRaw,
    CSV(HEADING(1), SEPARATOR(','), TERMINATOR(['\n', '\r\n']), QUOTE('"'))
  );

  EXPORT DS_Customers := DATASET(CustomersName, Layouts.Customer,      THOR, OPT);
  EXPORT DS_Txns      := DATASET(TxnsName,      Layouts.Transaction,   THOR, OPT);
  EXPORT DS_Spend     := DATASET(SpendName,     Layouts.CustomerSpend, THOR, OPT);
  EXPORT DS_Signals   := DATASET(SignalsName,   Layouts.FraudSignal,   THOR, OPT);
  EXPORT DS_Profile   := DATASET(ProfileName,   Layouts.CustomerProfile, THOR, OPT);

  // --- Indexes (payload keys, so Roxie never touches the base file) ----

  EXPORT IDX_ProfileById := INDEX(
    DS_Profile,
    {customer_id},
    {DS_Profile},
    ProfileIdxName,
    OPT
  );

  EXPORT IDX_ProfileByName := INDEX(
    DS_Profile,
    {last_name, first_name, customer_id},
    {DS_Profile},
    NameIdxName,
    OPT
  );

END;
