import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/screens/add_transaction_screen.dart';
import '../../budgets/screens/budgets_screen.dart';
import '../widgets/profile_header.dart';
import '../widgets/settings_tiles.dart';
import '../widgets/income_sources_list.dart';
import '../widgets/currency_sheet.dart';
import '../widgets/account_dialogs.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final hideRecurringIncome = ref.watch(hideRecurringIncomeProvider);
    final symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => showEditProfileDialog(context, ref, user),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        children: [
          ProfileHeader(user: user),

          // App & finance settings
          const SectionHeader(title: 'Settings'),
          SettingTile(
            icon: Icons.currency_exchange_rounded,
            iconColor: AppColors.warning,
            title: 'Currency',
            subtitle: '${user?.currency ?? 'USD'} ($symbol)',
            onTap: () => _editCurrency(context, ref, user),
          ),
          SettingSwitchTile(
            icon: Icons.visibility_off_rounded,
            iconColor: AppColors.primary,
            title: 'Hide Future Recurring Income',
            value: hideRecurringIncome,
            onChanged: (v) =>
                ref.read(hideRecurringIncomeProvider.notifier).state = v,
          ),
          SettingTile(
            icon: Icons.pie_chart_rounded,
            iconColor: AppColors.success,
            title: 'Manage Budgets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetsScreen()),
            ),
          ),

          const SizedBox(height: 8),

          // Income sources
          SectionHeader(
            title: 'Income Sources',
            trailing: TextButton.icon(
              onPressed: user == null ? null : () => _addIncomeSheet(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add'),
            ),
          ),
          IncomeSourcesList(
            symbol: symbol,
            onEdit: (income) => _editIncomeSheet(context, income),
            onDelete: (id) =>
                ref.read(transactionsProvider.notifier).deleteTransaction(id),
          ),

          const SizedBox(height: 8),

          // Sign out
          const SectionHeader(title: 'Account'),
          SettingTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Sign Out',
            onTap: () => showSignOutDialog(context, ref),
            titleColor: AppColors.error,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _editCurrency(BuildContext context, WidgetRef ref, UserModel? user) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CurrencySheet(user: user, ref: ref),
    );
  }

  void _addIncomeSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddTransactionScreen(
          initialType: TransactionType.income,
        ),
      ),
    );
  }

  void _editIncomeSheet(BuildContext context, TransactionModel income) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(existing: income),
      ),
    );
  }
}
