import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/collapsing_sliver_app_bar_mixin.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/providers/transaction_filter_provider.dart';
import '../../transactions/models/transaction_filter.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../widgets/filter_sort_sheet.dart';
import '../widgets/home_empty_state.dart';
import '../widgets/home_meter_row.dart';
import '../widgets/home_transaction_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with CollapsingSliverAppBarMixin<HomeScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final hideRecurringIncome = ref.watch(hideRecurringIncomeProvider);
    final symbol = ref.watch(currencySymbolProvider);
    final filter = ref.watch(transactionFilterProvider);

    final transactions = transactionsAsync.value ?? [];
    final monthTransactions = transactions.where(
      (t) =>
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month,
    );

    // Header totals always reflect the true month totals, independent of
    // the list filter below.
    final totalExpenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final monthlyIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final balance = monthlyIncome - totalExpenses;

    bool isFutureRecurringIncome(TransactionModel t) =>
        t.type == TransactionType.income && t.isRecurring && t.isFuture;

    // Only show transactions belonging to the selected month, then apply
    // the user's filter/sort — like a calendar month view, narrowed down.
    final listTransactions = hideRecurringIncome
        ? monthTransactions.where((t) => !isFutureRecurringIncome(t)).toList()
        : monthTransactions.toList();
    final filteredTransactions = filter.apply(listTransactions);
    final grouped = groupTransactionsByDate(
      filteredTransactions,
      groupByDate: filter.sortBy == TransactionSortField.date,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: AnimatedOpacity(
              opacity: showCollapsedTitle ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                'Xpenzes',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: HomeHeader(
                userName: user?.name.split(' ').first ?? '',
                symbol: symbol,
                monthlyIncome: monthlyIncome,
                totalExpenses: totalExpenses,
                balance: balance,
              ),
            ),
            actions: const [SizedBox(width: 4)],
          ),

          // Month label + navigation
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goToPreviousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.textPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: _goToNextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.textPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  Text(
                    '${filteredTransactions.length} transactions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (filter.isActive)
                    TextButton(
                      onPressed: () =>
                          ref.read(transactionFilterProvider.notifier).state =
                              const TransactionFilter(),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const FilterSortSheet(),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    color: filter.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),

          // Transaction list
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Error loading transactions',
                  style: GoogleFonts.inter(),
                ),
              ),
            ),
            data: (allTransactions) {
              if (allTransactions.isEmpty) {
                return const SliverFillRemaining(child: HomeEmptyState());
              }
              if (grouped.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      listTransactions.isEmpty
                          ? 'No transactions in '
                                '${DateFormat('MMMM yyyy').format(_selectedMonth)}.'
                          : 'No transactions match your filter.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              return HomeTransactionSliverList(
                grouped: grouped,
                currencySymbol: symbol,
                onDeleteTransaction: (t) => ref
                    .read(transactionsProvider.notifier)
                    .deleteTransaction(t.id!),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
