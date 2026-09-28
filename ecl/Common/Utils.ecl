/**
 * Common.Utils
 *
 * Small, side-effect free helpers. Everything here is unit tested in
 * Tests.Test_Utils, so keep it pure and keep the tests green.
 */
IMPORT STD;
IMPORT $.Constants;

EXPORT Utils := MODULE

  /**
   * Upper-case, trim, and strip anything that is not a plausible name
   * character. Returns '' for input that is entirely punctuation.
   */
  EXPORT STRING CleanName(STRING inName) := FUNCTION
    trimmed := STD.Str.Trim(inName, LEFT, RIGHT);
    uppered := STD.Str.ToUpperCase(trimmed);
    RETURN STD.Str.Filter(uppered, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ -\'');
  END;

  /**
   * Keep only digits. Handy for ids that arrive as 'C-1001'.
   */
  EXPORT STRING DigitsOnly(STRING inStr) := STD.Str.Filter(inStr, '0123456789');

  /**
   * Parse the date formats the upstream feed actually emits into YYYYMMDD.
   * Returns 0 when the value cannot be understood.
   *
   *   2019-03-14  (ISO)
   *   2019/03/14  (ISO with slashes)
   *   19750826    (already packed)
   */
  EXPORT UNSIGNED4 NormalizeDate(STRING inDate) := FUNCTION
    s   := STD.Str.Trim(inDate, ALL);
    len := LENGTH(s);
    iso := (UNSIGNED4)(s[1..4] + s[6..7] + s[9..10]);
    RETURN MAP(
      len = 10 AND (s[5] = '-' OR s[5] = '/') => iso,
      len = 8                                 => (UNSIGNED4)s,
      0
    );
  END;

  /**
   * Deliberately simple email check: one '@' with something either side
   * and a dot after the '@'.
   */
  EXPORT BOOLEAN IsValidEmail(STRING inEmail) := FUNCTION
    e      := STD.Str.ToLowerCase(STD.Str.Trim(inEmail, ALL));
    atPos  := STD.Str.Find(e, '@', 1);
    dotPos := STD.Str.Find(e, '.', 1);
    RETURN atPos > 1
       AND dotPos > atPos + 1
       AND dotPos < LENGTH(e)
       AND STD.Str.Find(e, '@', 2) = 0;
  END;

  /**
   * Whole years between two YYYYMMDD dates. 0 if either side is unknown.
   */
  EXPORT UNSIGNED2 AgeAt(UNSIGNED4 dob, UNSIGNED4 asOf = Constants.AsOfDate) := FUNCTION
    years := (asOf DIV 10000) - (dob DIV 10000);
    hadBirthday := (asOf % 10000) >= (dob % 10000);
    RETURN IF(dob = 0 OR asOf = 0, 0, (UNSIGNED2)(years - IF(hadBirthday, 0, 1)));
  END;

  /**
   * Format YYYYMMDD back to a human readable ISO string for OUTPUTs.
   */
  EXPORT STRING10 DateToISO(UNSIGNED4 packed) := FUNCTION
    s := (STRING8)packed;
    RETURN IF(packed = 0, '', s[1..4] + '-' + s[5..6] + '-' + s[7..8]);
  END;

END;
