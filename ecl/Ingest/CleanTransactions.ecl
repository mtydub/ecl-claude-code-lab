/**
 * Ingest.CleanTransactions
 *
 * Raw transaction rows -> typed Layouts.Transaction.
 *
 * Refunds arrive as negative amounts on channel REFUND; they are valid and
 * are deliberately left negative so that spend rollups net out correctly.
 */
IMPORT STD;
IMPORT $.^.Common;

Layouts   := Common.Layouts;
Utils     := Common.Utils;
Constants := Common.Constants;

EXPORT CleanTransactions(DATASET(Layouts.TransactionRaw) inRaw) := FUNCTION

  Layouts.Transaction doClean(Layouts.TransactionRaw L) := TRANSFORM

    txnDate  := Utils.NormalizeDate(L.txn_date);
    amount   := (DECIMAL12_2)STD.Str.Trim(L.amount, ALL);
    currency := STD.Str.ToUpperCase(STD.Str.Trim(L.currency, ALL));
    channel  := STD.Str.ToUpperCase(STD.Str.Trim(L.channel, ALL));

    SELF.txn_id      := (UNSIGNED4)Utils.DigitsOnly(L.txn_id);
    SELF.customer_id := (UNSIGNED4)Utils.DigitsOnly(L.customer_id);
    SELF.txn_date    := txnDate;
    SELF.amount      := amount;
    SELF.currency    := currency;
    SELF.merchant    := STD.Str.ToUpperCase(STD.Str.Trim(L.merchant, LEFT, RIGHT));
    SELF.mcc         := (UNSIGNED2)Utils.DigitsOnly(L.mcc);
    SELF.channel     := channel;
    SELF.is_valid    := txnDate != 0
                    AND amount != 0
                    AND currency IN Constants.SupportedCurrencies
                    AND channel IN Constants.ValidChannels;
  END;

  RETURN PROJECT(inRaw, doClean(LEFT));
END;
