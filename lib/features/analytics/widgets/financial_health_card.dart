import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class FinancialHealthCard extends StatelessWidget {
  final double income;
  final double expenses;
  final String symbol;

  const FinancialHealthCard({
    super.key,
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
