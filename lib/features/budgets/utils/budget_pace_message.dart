import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/budget_model.dart';

/// Composes the human-readable pace coaching line and its color purely
/// from [BudgetModel] fields already computed by xpenzes-svc — no
/// projection/threshold math happens here, only display formatting.
class BudgetPaceMessage {
  static String forBudget(BudgetModel budget, String symbol) {
    switch (budget.pace.paceStatus) {
      case 'over_pace':
        return BudgetPaceMessage._overPace(budget, symbol);
      case 'on_pace':
        return BudgetPaceMessage._onPace(budget);
      case 'under_pace':
        return BudgetPaceMessage._underPace(budget);
      default:
        return '';
    }
  }

  static Color colorFor(String paceStatus) {
    switch (paceStatus) {
      case 'over_pace':
        return AppColors.error;
      case 'on_pace':
        return AppColors.warning;
      case 'under_pace':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  static String _overPace(BudgetModel budget, String symbol) {
    final pct = BudgetPaceMessage._spentPercent(budget);
    final overage = budget.pace.projectedOverage.toStringAsFixed(2);
    return "You've spent $pct% of your ${budget.category} budget with "
        '${BudgetPaceMessage._daysLeft(budget)} — at this pace '
        "you'll exceed by $symbol$overage.";
  }

  static String _onPace(BudgetModel budget) {
    return "You're right on pace with your ${budget.category} budget, "
        '${BudgetPaceMessage._daysLeft(budget)} in the month.';
  }

  static String _underPace(BudgetModel budget) {
    return "You're comfortably under budget on ${budget.category}, "
        '${BudgetPaceMessage._daysLeft(budget)}.';
  }

  static int _spentPercent(BudgetModel budget) {
    if (budget.monthlyLimit <= 0) return 0;
    return ((budget.spent / budget.monthlyLimit) * 100).round();
  }

  static String _daysLeft(BudgetModel budget) {
    final days = budget.pace.daysRemaining;
    return '$days ${days == 1 ? 'day' : 'days'} left';
  }
}
