import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/budget_model.dart';
import '../providers/budgets_provider.dart';
import '../widgets/budget_row.dart';
import '../widgets/budget_edit_sheet.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final symbol = ref.watch(currencySymbolProvider);

    final budgets = budgetsAsync.value ?? [];
    final budgetByCategory = {for (final b in budgets) b.category: b};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budgets')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Set a monthly limit per category to get an early warning '
            'before you overspend.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ...AppConstants.expenseCategories.map((category) {
            final budget = budgetByCategory[category];
            return BudgetRow(
              category: category,
              spent: budget?.spent ?? 0,
              budget: budget,
              symbol: symbol,
              onTap: () => _showEditSheet(context, category, budget, symbol),
            );
          }),
        ],
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    String category,
    BudgetModel? existing,
    String symbol,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetEditSheet(
        category: category,
        existing: existing,
        symbol: symbol,
      ),
    );
  }
}
