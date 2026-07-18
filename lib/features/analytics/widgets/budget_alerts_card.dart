import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../budgets/screens/budgets_screen.dart';

class BudgetAlertsCard extends StatelessWidget {
  final int budgetCount;
  final int overBudgetCount;

  const BudgetAlertsCard({
    super.key,
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
                color: color.withValues(alpha: 0.12),
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
