import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_title.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../../spend_radar/providers/spend_radar_provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/financial_health_card.dart';
import '../widgets/spend_radar_card.dart';
import '../widgets/budget_alerts_card.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/trend_chart.dart';
import '../widgets/top_expenses_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final summary = ref.watch(analyticsSummaryProvider).value ?? AnalyticsSummary.empty;
    final trend = ref.watch(analyticsTrendProvider).value ?? [];
    final spendRadar = ref.watch(spendRadarProvider).value;
    final symbol = ref.watch(currencySymbolProvider);
    final topExpenses = ref.watch(topExpensesThisMonthProvider);

    final totalMonthlyRecurring = spendRadar?.totalMonthlyExpense ?? 0;

    final budgets = budgetsAsync.value ?? [];
    final overBudgetCount = budgets.where((b) => b.status == 'exceeded').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Analytics')),
      body: transactionsAsync.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FinancialHealthCard(
                    income: summary.totalIncome,
                    expenses: summary.totalExpense,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SpendRadarCard(
                    totalMonthlyRecurring: totalMonthlyRecurring,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: BudgetAlertsCard(
                    budgetCount: budgets.length,
                    overBudgetCount: overBudgetCount,
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle('Spending by Category'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CategoryBreakdownCard(
                    categoryBreakdown: summary.categoryBreakdown,
                    totalExpenses: summary.totalExpense,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle('Income vs Expense Trend'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TrendChart(trend: trend, symbol: symbol),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: SectionTitle('Top Expenses This Month'),
                ),
                const SizedBox(height: 8),
                if (topExpenses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      'No expenses recorded this month.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TopExpensesChart(
                      expenses: topExpenses,
                      symbol: symbol,
                      onTapExpense: (t) => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => TransactionDetailSheet(transaction: t),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
