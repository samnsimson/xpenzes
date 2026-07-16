# Bill Splitting / Shared Expenses

**Priority:** 4

## Summary

Real multi-person expense splitting (roommates, partner, trip group):
who paid, who owes what, and settle-up tracking — not just a note field
on a transaction.

## Why it matters

There's already a real signal for this: an existing transaction note
reads "This is groceries expenses, will be split in equal between room
mates," logged as a manual reminder rather than a tracked split. This is
the single biggest scope jump of the four candidates (needs a
multi-user/shared-ledger data model, which the app doesn't have at all
today — everything is scoped to a single local `user_id`), but it's also
the feature most likely to make someone else start using the app too.

## What it'd take

- A shared-ledger data model: participants (may not be app users —
  could be simple named contacts), per-transaction split shares, and
  settle-up/balance calculation between participants.
- This conflicts with the current fully-local, single-user sqflite
  model — shared data implies either a backend/sync layer, or an
  export/import or share-link mechanism between devices with no server.
- UI: mark a transaction as shared + split method (equal/custom/
  percentage), a "balances" view per person, and a settle-up action.
- Likely the feature that most concretely motivates finally building a
  backend, since local-only SQLite can't represent state shared between
  two people's devices.

## Open questions

- Is this scoped to "track who owes what" (bookkeeping only), or does
  it need to integrate real settlement (e.g. a payment link between
  users)?
- Given the local-only architecture, is a v1 "export a settle-up summary
  to share via text/email" an acceptable stand-in for real sync?
