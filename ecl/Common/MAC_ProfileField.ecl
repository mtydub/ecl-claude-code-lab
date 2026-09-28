/**
 * Common.MAC_ProfileField
 *
 * Frequency profile of a single field: the distinct values, how often each
 * occurs, and what share of the file that is. Useful when you first meet a
 * new feed and want to know whether a column is worth trusting.
 *
 *   IMPORT Common;
 *   Common.MAC_ProfileField(Common.Files.DS_CustomersRaw, country);
 */
EXPORT MAC_ProfileField(inFile, fieldName, topN = 25) := FUNCTIONMACRO
  #UNIQUENAME(total)
  #UNIQUENAME(counts)

  LOCAL %total% := COUNT(inFile);

  LOCAL %counts% := TABLE(
    inFile,
    {
      inFile.fieldName,
      UNSIGNED4 value_count := COUNT(GROUP),
      REAL8     pct_of_file := 100.0 * COUNT(GROUP) / %total%
    },
    fieldName,
    FEW
  );

  RETURN TOPN(%counts%, topN, -value_count);
ENDMACRO;
