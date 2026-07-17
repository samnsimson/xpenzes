import 'transaction_model.dart';

enum TransactionSortField { date, amount, title, category }

enum SortOrder { asc, desc }

/// User-facing filter/sort applied to an already-fetched transaction list
/// (see transactionsProvider — the full list is fetched once and shared
/// with analytics/budgets/spend_radar, so filtering happens client-side
/// on that cached list rather than re-querying the server).
class TransactionFilter {
  final TransactionType? type;
  final String? category;
  final double? minAmount;
  final double? maxAmount;
  final bool? isRecurring;
  final TransactionSortField sortBy;
  final SortOrder sortOrder;

  const TransactionFilter({
    this.type,
    this.category,
    this.minAmount,
    this.maxAmount,
    this.isRecurring,
    this.sortBy = TransactionSortField.date,
    this.sortOrder = SortOrder.desc,
  });

  /// Whether any filter (not sort) is set — drives the filter icon's
  /// active state and the "Clear" affordance.
  bool get isActive =>
      type != null ||
      category != null ||
      minAmount != null ||
      maxAmount != null ||
      isRecurring != null;

  TransactionFilter copyWith({
    TransactionType? type,
    bool clearType = false,
    String? category,
    bool clearCategory = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    bool? isRecurring,
    bool clearIsRecurring = false,
    TransactionSortField? sortBy,
    SortOrder? sortOrder,
  }) {
    return TransactionFilter(
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      isRecurring: clearIsRecurring ? null : (isRecurring ?? this.isRecurring),
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Filters, then sorts, [transactions]. The only place sort order is
  /// decided — callers shouldn't sort separately.
  List<TransactionModel> apply(List<TransactionModel> transactions) {
    final filtered = transactions.where((t) {
      if (type != null && t.type != type) return false;
      if (category != null && t.category != category) return false;
      if (minAmount != null && t.amount < minAmount!) return false;
      if (maxAmount != null && t.amount > maxAmount!) return false;
      if (isRecurring != null && t.isRecurring != isRecurring) return false;
      return true;
    }).toList();

    int compare(TransactionModel a, TransactionModel b) {
      final cmp = switch (sortBy) {
        TransactionSortField.date => a.date.compareTo(b.date),
        TransactionSortField.amount => a.amount.compareTo(b.amount),
        TransactionSortField.title => a.title.compareTo(b.title),
        TransactionSortField.category => a.category.compareTo(b.category),
      };
      return sortOrder == SortOrder.desc ? -cmp : cmp;
    }

    filtered.sort(compare);
    return filtered;
  }
}
