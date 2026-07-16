import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/providers/transactions_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/transaction_card.dart';
import '../../transactions/widgets/add_transaction_sheet.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';
import '../../transactions/widgets/meter_gauge.dart';
import '../../subscription/widgets/pro_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _collapsedThreshold = 150.0;

  final _scrollController = ScrollController();
  bool _showCollapsedTitle = false;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _scrollController.addListener(_onScroll);
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
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > _collapsedThreshold;
    if (show != _showCollapsedTitle) {
      setState(() => _showCollapsedTitle = show);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final transactionsAsync = ref.watch(transactionsProvider);
    final hideRecurringIncome = ref.watch(hideRecurringIncomeProvider);
    final symbol = AppConstants.currencies[user?.currency ?? 'USD'] ?? '\$';

    final transactions = transactionsAsync.value ?? [];
    final monthTransactions = transactions.where(
      (t) =>
          t.date.year == _selectedMonth.year &&
          t.date.month == _selectedMonth.month,
    );

    final totalExpenses = monthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (s, t) => s + t.amount);
    final monthlyIncome = monthTransactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (s, t) => s + t.amount);
    final balance = monthlyIncome - totalExpenses;
    final gaugeMax = [
      monthlyIncome,
      totalExpenses,
      balance.abs(),
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    bool isFutureRecurringIncome(TransactionModel t) =>
        t.type == TransactionType.income && t.isRecurring && t.isFuture;

    // Only show transactions belonging to the selected month, grouped by
    // date label, most recent/soonest first — like a calendar month view.
    final listTransactions = hideRecurringIncome
        ? monthTransactions.where((t) => !isFutureRecurringIncome(t)).toList()
        : monthTransactions.toList();
    final sorted = [...listTransactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    final grouped = _groupByDate(sorted);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Gradient app bar
          SliverAppBar(
            expandedHeight: 210,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: AnimatedOpacity(
              opacity: _showCollapsedTitle ? 1 : 0,
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
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF818CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting(),
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  user?.name.split(' ').first ?? 'there',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Meter gauges
                        Row(
                          children: [
                            MeterGauge(
                              label: 'Income',
                              valueText: '$symbol${_compact(monthlyIncome)}',
                              value: monthlyIncome,
                              max: gaugeMax,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            MeterGauge(
                              label: 'Spent',
                              valueText: '$symbol${_compact(totalExpenses)}',
                              value: totalExpenses,
                              max: gaugeMax,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 10),
                            MeterGauge(
                              label: 'Balance',
                              valueText: '$symbol${_compact(balance)}',
                              value: balance < 0 ? 0 : balance,
                              max: gaugeMax,
                              color: balance >= 0
                                  ? Colors.white
                                  : AppColors.secondary,
                              highlight: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                    '${monthTransactions.length} transactions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
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
                return SliverFillRemaining(child: _EmptyState());
              }
              if (grouped.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No transactions in '
                      '${DateFormat('MMMM yyyy').format(_selectedMonth)}.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final item = grouped[i];
                  if (item is ProBannerMarker) {
                    return const ProBanner();
                  }
                  if (item is String) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }
                  final transaction = item as TransactionModel;
                  return TransactionCard(
                    transaction: transaction,
                    currencySymbol: symbol,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          TransactionDetailSheet(transaction: transaction),
                    ),
                    onDelete: () => ref
                        .read(transactionsProvider.notifier)
                        .deleteTransaction(transaction.id!),
                  );
                }, childCount: grouped.length),
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

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  String _compact(double v) {
    if (v.abs() >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}M';
    }
    if (v.abs() >= 1000) {
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    return NumberFormat('#,##0.00').format(v);
  }

  static const _bannerInterval = 5;

  List<Object> _groupByDate(List<TransactionModel> transactions) {
    final result = <Object>[];
    String? lastLabel;
    var transactionCount = 0;
    for (final t in transactions) {
      final label = _dateLabel(t.date);
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(t);
      transactionCount++;
      if (transactionCount % _bannerInterval == 0) {
        result.add(const ProBannerMarker());
      }
    }
    return result;
  }

  String _dateLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff < 0) {
      return 'UPCOMING · ${DateFormat('EEEE, MMM d').format(d).toUpperCase()}';
    }
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return DateFormat('EEEE, MMM d').format(d).toUpperCase();
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap the button below to add your\nfirst transaction.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
