# Subscription / Recurring-Spend Radar

**Priority:** 1
**Status:** Shipped

## Summary

Surface every recurring transaction (subscriptions, memberships, recurring
bills) in one dedicated view, with the total monthly/yearly drain they
represent. Most expense trackers only show you what you spent in the
past; almost none proactively tell you what you're committed to spending
going forward.

## Why it matters

Xpenzes already models recurring transactions natively (`isRecurring`,
`recurrenceFrequency`, `recurringGroupId` on `TransactionModel`) — the
data is already there, just not surfaced as its own view. This is a
high-leverage, low-modeling-risk feature: no new data model needed, just
new aggregation/UI on existing data.

## What it'd take

- A dedicated "Subscriptions" view (new tab or a section reachable from
  Analytics/Account) listing each distinct recurring group
  (`recurringGroupId`), deduplicated the same way `account_screen.dart`
  already dedupes recurring income sources.
- Normalize each recurring item to a monthly-equivalent cost (reuse the
  frequency-normalization logic already in `home_screen.dart` for
  income) so weekly/yearly/etc. subscriptions are comparable.
- A total "monthly recurring spend" figure, and ideally income vs.
  expense split (recurring income sources already exist too).
- Sort/highlight the largest recurring drains first.
- Tap-through to edit/cancel (delete the recurring group) from this view.

## Open questions (resolved)

- Cancelling a recurring group: shipped with single-row edit/delete only
  (via the existing `TransactionDetailSheet`), consistent with the rest of
  the app's recurring-transaction semantics. Bulk "cancel all future
  occurrences" deferred to a later pass if needed.
- Scope: shipped with both recurring expenses (primary/headline total) and
  recurring income (secondary total), for a complete picture.

## Implementation

- `lib/features/transactions/utils/recurrence.dart`: `monthlyEquivalentAmount`,
  `dedupedRecurringGroups`, `totalMonthlyEquivalent`.
- `lib/features/spend_radar/screens/spend_radar_screen.dart`: the full view.
- Entry point: a tappable card in `AnalyticsScreen`, below the financial
  health card.
