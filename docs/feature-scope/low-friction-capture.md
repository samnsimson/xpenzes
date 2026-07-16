# Low-Friction Capture

**Priority:** 3

## Summary

Reduce the friction of logging a transaction below the current
title/amount/category/date form — either via receipt photo capture with
OCR auto-parse, or a one-line natural-language quick-add (e.g. "20 on
coffee" → parsed into title/amount/category).

## Why it matters

Manual entry friction is the most common reason people abandon expense
trackers. This is the highest-effort item in the list (needs either an
OCR pipeline or an LLM call), but it's also the one most likely to
change daily usage habits rather than just add a view.

## What it'd take

- **NL quick-add path (cheaper to build first):** a single text field on
  the FAB flow that parses free text into a draft `TransactionModel`
  (amount, likely category via keyword matching or an LLM call), shown
  for confirmation before saving via the existing
  `transactionsProvider.addTransaction`.
- **Receipt OCR path (bigger lift):** camera/photo picker, OCR (on-device
  via ML Kit, or a cloud OCR/LLM vision call), parsing merchant/amount/
  date, same confirm-before-save flow.
- Both paths reuse the existing `AddTransactionSheet` as the
  confirmation step — this feature is really "a smarter way to
  pre-fill" that sheet, not a new save path.
- If using any cloud/LLM call, needs a backend proxy (API keys can't
  live in the Flutter app) — same constraint already noted for Stripe
  in the Payment page.

## Open questions

- Start with NL text quick-add only, defer receipt OCR to a later pass?
- If using an LLM for parsing, which provider/endpoint, and does that
  imply building the backend sooner than planned?
