import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../models/budget_model.dart';

class BudgetRow extends StatelessWidget {
  final String category;
  final double spent;
  final BudgetModel? budget;
  final String symbol;
  final VoidCallback onTap;

  const BudgetRow({
    super.key,
    required this.category,
    required this.spent,
    required this.budget,
    required this.symbol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppConstants.categoryColors[category] ?? AppColors.primary;
    final icon = AppConstants.categoryIcons[category] ?? Icons.more_horiz;
    final hasBudget = budget != null;
    final progress = hasBudget
        ? (spent / budget!.monthlyLimit).clamp(0.0, 1.0)
        : 0.0;
    final progressColor = !hasBudget
        ? AppColors.textSecondary
        : progress >= 1.0
        ? AppColors.error
        : progress >= 0.8
        ? AppColors.warning
        : AppColors.success;

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasBudget) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: AppColors.border,
                            color: progressColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$symbol${spent.toStringAsFixed(2)} of '
                          '$symbol${budget!.monthlyLimit.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ] else
                        Text(
                          'No budget set · Tap to add',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
