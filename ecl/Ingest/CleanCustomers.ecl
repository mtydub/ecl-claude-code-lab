/**
 * Ingest.CleanCustomers
 *
 * Raw customer rows -> typed, validated Layouts.Customer.
 *
 * Nothing is thrown away here. Rows that fail validation are kept with
 * is_valid = FALSE and a human readable reject_reason, so that the QA
 * output in BWR_BuildCustomerBase can explain every drop downstream.
 */
IMPORT STD;
IMPORT $.^.Common;

Layouts   := Common.Layouts;
Utils     := Common.Utils;
Constants := Common.Constants;

EXPORT CleanCustomers(DATASET(Layouts.CustomerRaw) inRaw) := FUNCTION

  Layouts.Customer doClean(Layouts.CustomerRaw L) := TRANSFORM

    cid        := (UNSIGNED4)Utils.DigitsOnly(L.customer_id);
    firstName  := Utils.CleanName(L.first_name);
    lastName   := Utils.CleanName(L.last_name);
    dob        := Utils.NormalizeDate(L.dob);
    signup     := Utils.NormalizeDate(L.signup_date);
    age        := Utils.AgeAt(dob, Constants.AsOfDate);
    emailOK    := Utils.IsValidEmail(L.email);
    countryOK  := L.country IN Constants.SupportedCountries;

    reason := MAP(
      cid = 0                          => 'MISSING_CUSTOMER_ID',
      lastName = ''                    => 'MISSING_LAST_NAME',
      firstName = ''                   => 'MISSING_FIRST_NAME',
      dob = 0                          => 'UNPARSEABLE_DOB',
      age < Constants.MinAdultAge      => 'UNDER_AGE',
      age > Constants.MaxPlausibleAge  => 'IMPLAUSIBLE_AGE',
      NOT emailOK                      => 'BAD_EMAIL',
      NOT countryOK                    => 'UNSUPPORTED_COUNTRY',
      ''
    );

    SELF.customer_id   := cid;
    SELF.first_name    := firstName;
    SELF.last_name     := lastName;
    SELF.dob           := dob;
    SELF.age           := age;
    SELF.email         := STD.Str.ToLowerCase(STD.Str.Trim(L.email, ALL));
    SELF.street        := STD.Str.Trim(L.street, LEFT, RIGHT);
    SELF.city          := STD.Str.ToUpperCase(STD.Str.Trim(L.city, LEFT, RIGHT));
    SELF.state         := STD.Str.ToUpperCase(STD.Str.Trim(L.state, ALL));
    SELF.zip           := STD.Str.Trim(L.zip, ALL);
    SELF.country       := STD.Str.ToUpperCase(STD.Str.Trim(L.country, ALL));
    SELF.signup_date   := signup;
    SELF.is_valid      := reason = '';
    SELF.reject_reason := reason;
  END;

  RETURN PROJECT(inRaw, doClean(LEFT));
END;
