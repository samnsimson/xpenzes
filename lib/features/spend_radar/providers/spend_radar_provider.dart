import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transactions_provider.dart';

class RecurringItem {
  final TransactionModel transaction;
  final double monthlyEquivalent;

  const RecurringItem({required this.transaction, required this.monthlyEquivalent});

  factory RecurringItem.fromJson(Map<String, dynamic> json) => RecurringItem(
        transaction:
            TransactionModel.fromJson(json['transaction'] as Map<String, dynamic>),
        monthlyEquivalent: (json['monthly_equivalent'] as num).toDouble(),
      );
}

class SpendRadarData {
  final List<RecurringItem> recurringExpenses;
  final List<RecurringItem> recurringIncome;
  final double totalMonthlyExpense;
  final double totalMonthlyIncome;

  const SpendRadarData({
    required this.recurringExpenses,
    required this.recurringIncome,
    required this.totalMonthlyExpense,
    required this.totalMonthlyIncome,
  });

  factory SpendRadarData.fromJson(Map<String, dynamic> json) => SpendRadarData(
        recurringExpenses: (json['recurring_expenses'] as List<dynamic>)
            .map((e) => RecurringItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        recurringIncome: (json['recurring_income'] as List<dynamic>)
            .map((e) => RecurringItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalMonthlyExpense: (json['total_monthly_expense'] as num).toDouble(),
        totalMonthlyIncome: (json['total_monthly_income'] as num).toDouble(),
      );
}

final spendRadarProvider = FutureProvider<SpendRadarData>((ref) async {
  final user = await ref.watch(authProvider.future);
  if (user == null) {
    return const SpendRadarData(
      recurringExpenses: [],
      recurringIncome: [],
      totalMonthlyExpense: 0,
      totalMonthlyIncome: 0,
    );
  }
  ref.watch(transactionsProvider);
  final json = await apiClient.get('/spend-radar') as Map<String, dynamic>;
  return SpendRadarData.fromJson(json);
});
