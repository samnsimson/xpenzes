import 'package:intl/intl.dart';

/// Pure, context-free formatting helpers shared across screens. Kept
/// separate from any widget so they can be unit tested without a
/// [WidgetTester].

/// Time-of-day greeting shown on the home screen header.
String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning,';
  if (h < 17) return 'Good afternoon,';
  return 'Good evening,';
}

/// Compact "1.2k" / "3.4M" style formatting for large amounts, falling
/// back to the full decimal amount below 1000.
String compactAmount(double v) {
  if (v.abs() >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M';
  }
  if (v.abs() >= 1000) {
    return '${(v / 1000).toStringAsFixed(1)}k';
  }
  return NumberFormat('#,##0.00').format(v);
}

/// Relative day label for grouping a transaction list: `TODAY`,
/// `YESTERDAY`, `UPCOMING · <weekday, month day>`, or the plain
/// weekday/date for anything older.
String dateLabel(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final todayDay = DateTime(today.year, today.month, today.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = todayDay.difference(day).inDays;
  if (diff < 0) {
    return 'UPCOMING · ${DateFormat('EEEE, MMM d').format(d).toUpperCase()}';
  }
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'YESTERDAY';
  return DateFormat('EEEE, MMM d').format(d).toUpperCase();
}
