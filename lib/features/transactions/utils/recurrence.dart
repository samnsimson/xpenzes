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
