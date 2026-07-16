# Budgets with Proactive Alerts

**Priority:** 2
**Status:** Shipped

## Summary

Per-category monthly budgets with proactive alerts as spend approaches or
exceeds the limit, instead of only retrospective charts. Turns the app
from a mirror ("here's what happened") into a coach ("here's what's
about to happen").

## Why it matters

Analytics already computes category breakdowns for the current month
(`_CategoryBreakdown` in `analytics_screen.dart`). Budgets are a natural
extension of that existing aggregation, not a new subsystem.

## What it'd take

- New `budgets` table: category, monthly limit amount, user id.
- A budget-setting UI (likely a new screen or a section in Account/
  Analytics) to set/edit limits per `AppConstants.expenseCategories`.
- Progress indicators (reuse the `MeterGauge` pattern) showing spend vs.
  budget per category, probably surfaced in Analytics alongside the
  existing category donut.
- Alerting: since there's no push notification infrastructure yet, a
  first pass would be in-app only (banner/badge when a category crosses
  e.g. 80%/100% of budget on app open), with real push notifications as
  a later iteration once a backend exists.

## Open questions (resolved)

- Budgets reset automatically every month — a budget is just a flat
  monthly limit; current-month spend is always computed fresh from
  `transactionsProvider`, so there's no explicit "reset" step or rollover
  logic needed.
- Alerts are in-app only for this pass (a status card in Analytics), no
  push notifications — deferred until a backend exists.

## Implementation

- `lib/features/budgets/models/budget_model.dart`, `providers/
  budgets_provider.dart`, `screens/budgets_screen.dart` — one budget per
  category (`UNIQUE(user_id, category)` in the `budgets` table), progress
  bar colored by 80%/100% thresholds.
- Entry points: a "Budget Alerts" summary card in `AnalyticsScreen`
  (below the Spend Radar card), and a "Manage Budgets" row in
  `AccountScreen`'s new Settings section.
- As part of this feature, `AccountScreen` was reorganized: a "Settings"
  section (Currency, Hide Future Recurring Income, Manage Budgets) now
  holds app/finance preferences, separate from the "Account" section
  (Sign Out) and "Income Sources".
