import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/section_title.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/spend_radar_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/recurring_item_tile.dart';
import '../widgets/spend_radar_empty_state.dart';

class SpendRadarScreen extends ConsumerWidget {
  const SpendRadarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(currencySymbolProvider);
    final data = ref.watch(spendRadarProvider).value;

    final recurringExpenses = data?.recurringExpenses ?? [];
    final recurringIncome = data?.recurringIncome ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Spend Radar')),
      body: recurringExpenses.isEmpty && recurringIncome.isEmpty
          ? const SpendRadarEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                SummaryCard(
                  totalMonthlyExpense: data?.totalMonthlyExpense ?? 0,
                  totalMonthlyIncome: data?.totalMonthlyIncome ?? 0,
                  symbol: symbol,
                ),
                if (recurringExpenses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionTitle('Recurring Expenses'),
                  const SizedBox(height: 10),
                  ...recurringExpenses.map(
                    (item) => RecurringItemTile(item: item, symbol: symbol),
                  ),
                ],
                if (recurringIncome.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const SectionTitle('Recurring Income'),
                  const SizedBox(height: 10),
                  ...recurringIncome.map(
                    (item) => RecurringItemTile(item: item, symbol: symbol),
                  ),
                ],
              ],
            ),
    );
  }
}
