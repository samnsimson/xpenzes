import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../transactions/models/transaction_model.dart';

class TopExpensesChart extends StatelessWidget {
  final List<TransactionModel> expenses;
  final String symbol;
  final ValueChanged<TransactionModel> onTapExpense;

  const TopExpensesChart({
    super.key,
    required this.expenses,
    required this.symbol,
    required this.onTapExpense,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = expenses.fold<double>(0, (m, t) => t.amount > m ? t.amount : m);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < expenses.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _ExpenseBarRow(
              transaction: expenses[i],
              maxAmount: maxAmount,
              symbol: symbol,
              onTap: () => onTapExpense(expenses[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExpenseBarRow extends StatelessWidget {
  final TransactionModel transaction;
  final double maxAmount;
  final String symbol;
  final VoidCallback onTap;

  const _ExpenseBarRow({
    required this.transaction,
    required this.maxAmount,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppConstants.categoryColors[transaction.category] ?? AppColors.primary;
    final fraction =
        maxAmount <= 0 ? 0.0 : (transaction.amount / maxAmount).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transaction.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$symbol${transaction.amount.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            transaction.category,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
