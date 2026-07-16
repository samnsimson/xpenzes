import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/transaction_card.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';
import '../../transactions/utils/recurrence.dart';
import '../../spend_radar/screens/spend_radar_screen.dart';
import '../../budgets/providers/budgets_provider.dart';
import '../../budgets/screens/budgets_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final budgetsAsync = ref.watch(budgetsProvider);
    final symbol = AppConstants.currencies[user?.currency ?? 'USD'] ?? '\$';
    final transactions = transactionsAsync.value ?? [];

    final now = DateTime.now();
    final monthTransactions = transactions
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final monthExpenses = monthTransactions.where(
      (t) => t.type == TransactionType.expense,
    );
    final monthIncome = monthTransactions.where(
      (t) => t.type == TransactionType.income,
    );
    final totalExpenses = monthExpenses.fold<double>(0, (s, t) => s + t.amount);
    final totalIncome = monthIncome.fold<double>(0, (s, t) => s + t.amount);

    final categoryTotals = <String, double>{};
    for (final t in monthExpenses) {
      categoryTotals.update(
        t.category,
        (v) => v + t.amount,
        ifAbsent: () => t.amount,
      );
    }

    final trend = _monthlyTrend(transactions, now);

    final topExpenses = [...monthExpenses]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topExpenses.take(5).toList();

    final recurringExpenses = dedupedRecurringGroups(
      transactions,
      TransactionType.expense,
    );
    final totalMonthlyRecurring = totalMonthlyEquivalent(recurringExpenses);

    final budgets = budgetsAsync.value ?? [];
    final overBudgetCount = budgets
        .where((b) => (categoryTotals[b.category] ?? 0) >= b.monthlyLimit)
        .length;

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
                  child: _FinancialHealthCard(
                    income: totalIncome,
                    expenses: totalExpenses,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SpendRadarCard(
                    totalMonthlyRecurring: totalMonthlyRecurring,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _BudgetAlertsCard(
                    budgetCount: budgets.length,
                    overBudgetCount: overBudgetCount,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle('Spending by Category'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _CategoryBreakdown(
                    categoryTotals: categoryTotals,
                    totalExpenses: totalExpenses,
                    symbol: symbol,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle('Income vs Expense Trend'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _TrendChart(trend: trend, symbol: symbol),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SectionTitle('Top Expenses This Month'),
                ),
                const SizedBox(height: 8),
                if (top5.isEmpty)
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
                  ...top5.map(
                    (t) => TransactionCard(
                      transaction: t,
                      currencySymbol: symbol,
                      onTap: () => showModalBottomSheet(
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

  static List<_MonthTotal> _monthlyTrend(
    List<TransactionModel> transactions,
    DateTime now,
  ) {
    final months = List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i));
      return m;
    });

    return months.map((m) {
      final inMonth = transactions.where(
        (t) => t.date.year == m.year && t.date.month == m.month,
      );
      final income = inMonth
          .where((t) => t.type == TransactionType.income)
          .fold<double>(0, (s, t) => s + t.amount);
      final expense = inMonth
          .where((t) => t.type == TransactionType.expense)
          .fold<double>(0, (s, t) => s + t.amount);
      return _MonthTotal(month: m, income: income, expense: expense);
    }).toList();
  }
}

class _MonthTotal {
  final DateTime month;
  final double income;
  final double expense;

  const _MonthTotal({
    required this.month,
    required this.income,
    required this.expense,
  });
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SpendRadarCard extends StatelessWidget {
  final double totalMonthlyRecurring;
  final String symbol;

  const _SpendRadarCard({
    required this.totalMonthlyRecurring,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpendRadarScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spend Radar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    totalMonthlyRecurring > 0
                        ? '$symbol${totalMonthlyRecurring.toStringAsFixed(2)}/mo recurring'
                        : 'No recurring spend yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetAlertsCard extends StatelessWidget {
  final int budgetCount;
  final int overBudgetCount;

  const _BudgetAlertsCard({
    required this.budgetCount,
    required this.overBudgetCount,
  });

  @override
  Widget build(BuildContext context) {
    late final String status;
    late final Color color;
    late final IconData icon;
    if (budgetCount == 0) {
      status = 'No budgets set';
      color = AppColors.textSecondary;
      icon = Icons.pie_chart_outline_rounded;
    } else if (overBudgetCount > 0) {
      status =
          '$overBudgetCount ${overBudgetCount == 1 ? 'category' : 'categories'} over budget';
      color = AppColors.error;
      icon = Icons.warning_amber_rounded;
    } else {
      status = 'All budgets on track';
      color = AppColors.success;
      icon = Icons.check_circle_outline_rounded;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BudgetsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Alerts',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FinancialHealthCard extends StatelessWidget {
  final double income;
  final double expenses;
  final String symbol;

  const _FinancialHealthCard({
    required this.income,
    required this.expenses,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final balance = income - expenses;
    final savingsRate = income <= 0 ? 0.0 : balance / income;

    late final String label;
    late final Color color;
    late final IconData icon;
    if (income <= 0) {
      label = 'No income recorded';
      color = AppColors.textSecondary;
      icon = Icons.info_outline_rounded;
    } else if (savingsRate < 0) {
      label = 'Overspending';
      color = AppColors.error;
      icon = Icons.trending_down_rounded;
    } else if (savingsRate < 0.2) {
      label = 'Tight';
      color = AppColors.warning;
      icon = Icons.trending_flat_rounded;
    } else {
      label = 'Healthy';
      color = AppColors.success;
      icon = Icons.trending_up_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  income <= 0
                      ? 'Add income to see your savings rate.'
                      : 'Saving ${(savingsRate * 100).toStringAsFixed(0)}% of income this month.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalExpenses;
  final String symbol;

  const _CategoryBreakdown({
    required this.categoryTotals,
    required this.totalExpenses,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty || totalExpenses <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(
            'No spending recorded this month.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: entries.map((e) {
                  final color =
                      AppConstants.categoryColors[e.key] ?? AppColors.primary;
                  return PieChartSectionData(
                    value: e.value,
                    color: color,
                    radius: 20,
                    showTitle: false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.take(6).map((e) {
                final color =
                    AppConstants.categoryColors[e.key] ?? AppColors.primary;
                final pct = (e.value / totalExpenses * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.key,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChart extends StatelessWidget {
  final List<_MonthTotal> trend;
  final String symbol;

  const _TrendChart({required this.trend, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final maxY = trend
        .expand((t) => [t.income, t.expense])
        .fold<double>(1, (m, v) => v > m ? v : m);

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.15,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MMM').format(trend[i].month),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < trend.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: trend[i].income,
                    color: AppColors.success,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: trend[i].expense,
                    color: AppColors.secondary,
                    width: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
