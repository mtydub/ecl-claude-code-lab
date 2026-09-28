/**
 * Roxie.SearchByName
 *
 * Published query: profiles matching a last name, optionally narrowed by
 * a first-name prefix.
 *
 *   ecl publish roxie ecl/Roxie/SearchByName.ecl -I ecl \
 *       --name=searchbyname --activate
 */
IMPORT STD;
IMPORT $.^.Common;

Files := Common.Files;

STRING25  LastName    := ''  : STORED('LastName');
STRING25  FirstPrefix := ''  : STORED('FirstPrefix');
UNSIGNED2 MaxRows     := 20  : STORED('MaxRows');

searchLast  := STD.Str.ToUpperCase(STD.Str.Trim(LastName, LEFT, RIGHT));
searchFirst := STD.Str.ToUpperCase(STD.Str.Trim(FirstPrefix, LEFT, RIGHT));

matches := Files.DS_Profile(
  last_name = searchLast,
  searchFirst = '' OR first_name[1..LENGTH(searchFirst)] = searchFirst
);

result := CHOOSEN(SORT(matches, last_name, first_name, customer_id), MaxRows);

EXPORT SearchByName := OUTPUT(
  PROJECT(result, TRANSFORM({UNSIGNED4 customer_id, STRING25 first_name,
                             STRING25 last_name, UNSIGNED1 fraud_score,
                             DECIMAL12_2 total_amount},
                            SELF := LEFT)),
  NAMED('Matches')
);
