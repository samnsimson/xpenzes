import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transactions_provider.dart';

class CategoryTotal {
  final String category;
  final double total;

  const CategoryTotal({required this.category, required this.total});

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
    category: json['category'] as String,
    total: (json['total'] as num).toDouble(),
  );
}

class AnalyticsSummary {
  final double totalIncome;
  final double totalExpense;
  final double net;
  final List<CategoryTotal> categoryBreakdown;

  const AnalyticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.net,
    required this.categoryBreakdown,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) =>
      AnalyticsSummary(
        totalIncome: (json['total_income'] as num).toDouble(),
        totalExpense: (json['total_expense'] as num).toDouble(),
        net: (json['net'] as num).toDouble(),
        categoryBreakdown: (json['category_breakdown'] as List<dynamic>)
            .map((e) => CategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static const empty = AnalyticsSummary(
    totalIncome: 0,
    totalExpense: 0,
    net: 0,
    categoryBreakdown: [],
  );
}

class MonthTotal {
  final int year;
  final int month;
  final double income;
  final double expense;

  const MonthTotal({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  DateTime get date => DateTime(year, month);

  factory MonthTotal.fromJson(Map<String, dynamic> json) => MonthTotal(
    year: json['year'] as int,
    month: json['month'] as int,
    income: (json['income'] as num).toDouble(),
    expense: (json['expense'] as num).toDouble(),
  );
}

final analyticsSummaryProvider = FutureProvider<AnalyticsSummary>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return AnalyticsSummary.empty;
  // Re-fetch whenever the transaction list changes, since this is a
  // server-computed aggregate over transactions, not derived locally.
  ref.watch(transactionsProvider);
  final json =
      await apiClient.get('/analytics/summary') as Map<String, dynamic>;
  return AnalyticsSummary.fromJson(json);
});

final analyticsTrendProvider = FutureProvider<List<MonthTotal>>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return [];
  ref.watch(transactionsProvider);
  final json = await apiClient.get('/analytics/trend') as List<dynamic>;
  return json
      .map((e) => MonthTotal.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// The top 5 expenses for the current calendar month, highest first.
final topExpensesThisMonthProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) return [];
  // Re-fetch whenever the transaction list changes, since the top expenses
  // depend on current month transactions.
  ref.watch(transactionsProvider);
  final json = await apiClient.get('/analytics/top-expenses') as List<dynamic>;
  return json
      .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
