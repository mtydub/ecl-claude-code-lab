/**
 * Roxie.GetCustomerProfile
 *
 * Published query: one customer profile by id.
 *
 *   ecl publish roxie ecl/Roxie/GetCustomerProfile.ecl -I ecl \
 *       --name=getcustomerprofile --activate
 *
 *   curl 'http://localhost:8002/WsEcl/submit/query/roxie/getcustomerprofile/json' \
 *        -d '{"getcustomerprofile":{"CustomerId":1001,"MaxTxns":3}}'
 */
IMPORT $.^.Common;

Files   := Common.Files;
Layouts := Common.Layouts;

UNSIGNED4 CustomerId := 0 : STORED('CustomerId');
UNSIGNED2 MaxTxns    := 5 : STORED('MaxTxns');

hit := Files.IDX_ProfileById(KEYED(customer_id = CustomerId));

trimmed := PROJECT(
  hit,
  TRANSFORM(Layouts.CustomerProfile,
    SELF.recent_txns := CHOOSEN(LEFT.recent_txns, MaxTxns),
    SELF := LEFT
  )
);

EXPORT GetCustomerProfile := OUTPUT(trimmed, NAMED('Profile'));
