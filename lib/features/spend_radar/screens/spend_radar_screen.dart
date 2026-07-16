import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/utils/recurrence.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';

class SpendRadarScreen extends ConsumerWidget {
  const SpendRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final symbol = AppConstants.currencies[user?.currency ?? 'USD'] ?? '\$';
    final transactions = transactionsAsync.value ?? [];

    final recurringExpenses = dedupedRecurringGroups(
      transactions,
      TransactionType.expense,
    );
    final recurringIncome = dedupedRecurringGroups(
      transactions,
      TransactionType.income,
    );

    final totalMonthlyExpense = totalMonthlyEquivalent(recurringExpenses);
    final totalMonthlyIncome = totalMonthlyEquivalent(recurringIncome);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Spend Radar')),
      body: recurringExpenses.isEmpty && recurringIncome.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _SummaryCard(
                  totalMonthlyExpense: totalMonthlyExpense,
                  totalMonthlyIncome: totalMonthlyIncome,
                  symbol: symbol,
                ),
                if (recurringExpenses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('Recurring Expenses'),
                  const SizedBox(height: 10),
                  ...recurringExpenses.map(
                    (t) => _RecurringItemTile(transaction: t, symbol: symbol),
                  ),
                ],
                if (recurringIncome.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _SectionTitle('Recurring Income'),
                  const SizedBox(height: 10),
                  ...recurringIncome.map(
                    (t) => _RecurringItemTile(transaction: t, symbol: symbol),
                  ),
                ],
              ],
            ),
    );
  }
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

class _SummaryCard extends StatelessWidget {
  final double totalMonthlyExpense;
  final double totalMonthlyIncome;
  final String symbol;

  const _SummaryCard({
    required this.totalMonthlyExpense,
    required this.totalMonthlyIncome,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.radar_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Monthly Recurring Spend',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '$symbol${totalMonthlyExpense.toStringAsFixed(2)}/mo',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (totalMonthlyIncome > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Recurring income: $symbol${totalMonthlyIncome.toStringAsFixed(2)}/mo',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecurringItemTile extends StatelessWidget {
  final TransactionModel transaction;
  final String symbol;

  const _RecurringItemTile({required this.transaction, required this.symbol});

  bool get _isIncome => transaction.type == TransactionType.income;

  Color get _color => _isIncome
      ? AppColors.success
      : AppConstants.categoryColors[transaction.category] ??
            AppColors.textSecondary;

  IconData get _icon => _isIncome
      ? Icons.trending_up_rounded
      : AppConstants.categoryIcons[transaction.category] ?? Icons.more_horiz;

  @override
  Widget build(BuildContext context) {
    final frequency = transaction.recurrenceFrequency!;
    final monthlyEquivalent = monthlyEquivalentAmount(
      transaction.amount,
      frequency,
    );
    final isAlreadyMonthly = frequency == 'Monthly';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionDetailSheet(transaction: transaction),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          frequency,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$symbol${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isAlreadyMonthly) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈$symbol${monthlyEquivalent.toStringAsFixed(2)}/mo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radar_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No recurring transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mark a transaction as repeating to see it\nsurface here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
