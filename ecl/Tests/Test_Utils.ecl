/**
 * Tests.Test_Utils
 *
 * Pure-function tests for Common.Utils. No cluster data required, so this
 * runs happily on hthor.
 */
IMPORT $.^.Common;

EXPORT Test_Utils := MODULE

  SHARED Utils := Common.Utils;

  EXPORT Run := SEQUENTIAL(

    // --- CleanName ----------------------------------------------------
    ASSERT(Utils.CleanName('  ada  ') = 'ADA',
           'CleanName should trim and upper-case', FAIL),
    ASSERT(Utils.CleanName('O\'Neil-Smith') = 'O\'NEIL-SMITH',
           'CleanName should keep apostrophes and hyphens', FAIL),
    ASSERT(Utils.CleanName('J0hn99') = 'JHN',
           'CleanName should strip digits', FAIL),
    ASSERT(Utils.CleanName('!!!') = '',
           'CleanName of punctuation only should be empty', FAIL),

    // --- DigitsOnly ---------------------------------------------------
    ASSERT(Utils.DigitsOnly('C-1001') = '1001',
           'DigitsOnly should strip the prefix', FAIL),
    ASSERT(Utils.DigitsOnly('no digits here') = '',
           'DigitsOnly of a digit-free string should be empty', FAIL),

    // --- NormalizeDate ------------------------------------------------
    ASSERT(Utils.NormalizeDate('1985-12-10') = 19851210,
           'NormalizeDate should parse ISO dashes', FAIL),
    ASSERT(Utils.NormalizeDate('1980/06/09') = 19800609,
           'NormalizeDate should parse ISO slashes', FAIL),
    ASSERT(Utils.NormalizeDate('19750826') = 19750826,
           'NormalizeDate should pass through packed dates', FAIL),
    ASSERT(Utils.NormalizeDate('  1985-12-10 ') = 19851210,
           'NormalizeDate should ignore surrounding spaces', FAIL),
    ASSERT(Utils.NormalizeDate('') = 0,
           'NormalizeDate of empty should be 0', FAIL),
    ASSERT(Utils.NormalizeDate('not-a-date') = 0,
           'NormalizeDate of junk should be 0', FAIL),

    // --- IsValidEmail -------------------------------------------------
    ASSERT(Utils.IsValidEmail('a@b.com'),
           'IsValidEmail should accept a minimal address', FAIL),
    ASSERT(NOT Utils.IsValidEmail('jean.bartik@example'),
           'IsValidEmail should reject a missing TLD dot', FAIL),
    ASSERT(NOT Utils.IsValidEmail(''),
           'IsValidEmail should reject empty', FAIL),
    ASSERT(NOT Utils.IsValidEmail('@example.com'),
           'IsValidEmail should reject a missing local part', FAIL),
    ASSERT(NOT Utils.IsValidEmail('a@@b.com'),
           'IsValidEmail should reject two at-signs', FAIL),

    // --- AgeAt --------------------------------------------------------
    ASSERT(Utils.AgeAt(19851210, 20231231) = 38,
           'AgeAt after the birthday', FAIL),
    ASSERT(Utils.AgeAt(19851210, 20230101) = 37,
           'AgeAt before the birthday', FAIL),
    ASSERT(Utils.AgeAt(0, 20231231) = 0,
           'AgeAt with unknown dob should be 0', FAIL),

    // --- DateToISO ----------------------------------------------------
    ASSERT(Utils.DateToISO(19851210) = '1985-12-10',
           'DateToISO should format with dashes', FAIL),
    ASSERT(TRIM(Utils.DateToISO(0)) = '',
           'DateToISO of 0 should be blank', FAIL),

    OUTPUT('Test_Utils: PASS')
  );

END;
