import 'package:flutter_test/flutter_test.dart';
import 'package:xpenzes/core/theme/app_theme.dart';
import 'package:xpenzes/features/budgets/models/budget_model.dart';
import 'package:xpenzes/features/budgets/utils/budget_pace_message.dart';

void main() {
  BudgetModel buildBudget({
    required String paceStatus,
    String category = 'Groceries',
    double monthlyLimit = 1000,
    double spent = 600,
    int daysElapsed = 15,
    int daysRemaining = 16,
    double projectedSpend = 1200,
    double projectedOverage = 200,
  }) {
    return BudgetModel(
      id: 'budget-1',
      category: category,
      monthlyLimit: monthlyLimit,
      spent: spent,
      status: 'ok',
      pace: BudgetPace(
        paceStatus: paceStatus,
        daysElapsed: daysElapsed,
        daysRemaining: daysRemaining,
        projectedSpend: projectedSpend,
        projectedOverage: projectedOverage,
      ),
    );
  }

  group('BudgetPaceMessage.forBudget - over_pace', () {
    test('includes category, days remaining, symbol, overage and wording', () {
      final budget = buildBudget(
        paceStatus: 'over_pace',
        category: 'Dining',
        daysRemaining: 16,
        projectedOverage: 45.5,
      );

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, isNotEmpty);
      expect(message, contains('Dining'));
      expect(message, contains('16'));
      expect(message, contains(r'$'));
      expect(message, contains('45.50'));
      expect(message, contains("at this pace you'll exceed by"));
    });

    test('colorFor over_pace maps to error', () {
      expect(BudgetPaceMessage.colorFor('over_pace'), AppColors.error);
    });
  });

  group('BudgetPaceMessage.forBudget - on_pace', () {
    test('returns non-empty on-track variant containing category', () {
      final budget = buildBudget(paceStatus: 'on_pace', category: 'Utilities');

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, isNotEmpty);
      expect(message, contains('Utilities'));
      expect(message, contains('right on pace'));
    });

    test('colorFor on_pace maps to warning', () {
      expect(BudgetPaceMessage.colorFor('on_pace'), AppColors.warning);
    });
  });

  group('BudgetPaceMessage.forBudget - under_pace', () {
    test(
      'returns non-empty under-budget variant without duplicated "left"',
      () {
        final budget = buildBudget(
          paceStatus: 'under_pace',
          category: 'Travel',
          daysRemaining: 16,
        );

        final message = BudgetPaceMessage.forBudget(budget, r'$');

        expect(message, isNotEmpty);
        expect(message, contains('Travel'));
        expect(message, contains('comfortably under budget'));
        expect(message, contains('16 days left.'));
        expect(message, isNot(contains('left left')));
      },
    );

    test('colorFor under_pace maps to success', () {
      expect(BudgetPaceMessage.colorFor('under_pace'), AppColors.success);
    });
  });

  group('BudgetPaceMessage.forBudget - no_budget', () {
    test('returns empty string', () {
      final budget = buildBudget(paceStatus: 'no_budget');

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, isEmpty);
    });

    test('colorFor no_budget maps to textSecondary', () {
      expect(BudgetPaceMessage.colorFor('no_budget'), AppColors.textSecondary);
    });
  });

  group('BudgetPaceMessage.forBudget - spent percentage', () {
    test('renders 60% when spent=600 and monthlyLimit=1000', () {
      final budget = buildBudget(
        paceStatus: 'over_pace',
        spent: 600,
        monthlyLimit: 1000,
      );

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, contains('60%'));
    });
  });

  group('BudgetPaceMessage.forBudget - days-left pluralization', () {
    test('renders singular "1 day left" when daysRemaining is 1', () {
      final budget = buildBudget(paceStatus: 'on_pace', daysRemaining: 1);

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, contains('1 day left'));
    });

    test('renders plural "16 days left" when daysRemaining is 16', () {
      final budget = buildBudget(paceStatus: 'under_pace', daysRemaining: 16);

      final message = BudgetPaceMessage.forBudget(budget, r'$');

      expect(message, contains('16 days left'));
    });
  });

  group('BudgetPaceMessage - unknown paceStatus', () {
    test('colorFor falls back to textSecondary for unknown status', () {
      expect(BudgetPaceMessage.colorFor(''), AppColors.textSecondary);
      expect(BudgetPaceMessage.colorFor('bogus'), AppColors.textSecondary);
    });

    test('forBudget does not throw and returns empty for unknown status', () {
      final budget = buildBudget(paceStatus: '');

      expect(() => BudgetPaceMessage.forBudget(budget, r'$'), returnsNormally);
      expect(BudgetPaceMessage.forBudget(budget, r'$'), isEmpty);
    });
  });
}
