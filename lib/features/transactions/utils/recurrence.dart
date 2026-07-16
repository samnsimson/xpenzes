import '../models/transaction_model.dart';

/// Number of future occurrences generated when a recurring transaction is saved.
const int kRecurringOccurrenceCount = 12;

DateTime nextRecurrenceDate(DateTime date, String frequency) {
  switch (frequency) {
    case 'Weekly':
      return date.add(const Duration(days: 7));
    case 'Bi-weekly':
      return date.add(const Duration(days: 14));
    case 'Quarterly':
      return DateTime(date.year, date.month + 3, date.day);
    case 'Yearly':
      return DateTime(date.year + 1, date.month, date.day);
    default: // Monthly
      return DateTime(date.year, date.month + 1, date.day);
  }
}

/// Normalizes a per-charge [amount] at the given recurrence [frequency] to
/// a comparable monthly-equivalent figure (e.g. a $120 yearly charge -> $10).
double monthlyEquivalentAmount(double amount, String frequency) {
  switch (frequency) {
    case 'Weekly':
      return amount * 4.33;
    case 'Bi-weekly':
      return amount * 2.17;
    case 'Quarterly':
      return amount / 3;
    case 'Yearly':
      return amount / 12;
    default: // Monthly
      return amount;
  }
}

/// One representative row per recurring group (earliest date) for the given
/// [type], sorted by monthly-equivalent amount descending (largest first).
List<TransactionModel> dedupedRecurringGroups(
  List<TransactionModel> transactions,
  TransactionType type,
) {
  final byGroup = <String, TransactionModel>{};
  for (final t in transactions) {
    if (t.type != type || !t.isRecurring || t.recurrenceFrequency == null) {
      continue;
    }
    final key = t.recurringGroupId ?? '${t.type.value}-${t.id}';
    final current = byGroup[key];
    if (current == null || t.date.isBefore(current.date)) {
      byGroup[key] = t;
    }
  }
  final list = byGroup.values.toList();
  list.sort(
    (a, b) => monthlyEquivalentAmount(
      b.amount,
      b.recurrenceFrequency!,
    ).compareTo(monthlyEquivalentAmount(a.amount, a.recurrenceFrequency!)),
  );
  return list;
}

/// Sum of monthly-equivalent amounts across [groups].
double totalMonthlyEquivalent(List<TransactionModel> groups) =>
    groups.fold<double>(
      0,
      (s, t) => s + monthlyEquivalentAmount(t.amount, t.recurrenceFrequency!),
    );
