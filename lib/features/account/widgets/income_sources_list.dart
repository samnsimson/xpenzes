import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../spend_radar/providers/spend_radar_provider.dart';
import '../../transactions/models/transaction_model.dart';

/// Renders the account screen's recurring-income section: loading state,
/// empty state, or the list of income sources with edit/delete actions.
class IncomeSourcesList extends ConsumerWidget {
  final String symbol;
  final ValueChanged<TransactionModel> onEdit;
  final ValueChanged<String> onDelete;

  const IncomeSourcesList({
    super.key,
    required this.symbol,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spendRadarAsync = ref.watch(spendRadarProvider);

    return spendRadarAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (spendRadar) {
        final incomes = spendRadar.recurringIncome.toList()
          ..sort((a, b) => a.transaction.title.compareTo(b.transaction.title));

        if (incomes.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'No income sources added yet.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: incomes.map((item) {
            final income = item.transaction;
            return _IncomeTile(
              income: income,
              symbol: symbol,
              onDelete: () => onDelete(income.id!),
              onEdit: () => onEdit(income),
            );
          }).toList(),
        );
      },
    );
  }
}

class _IncomeTile extends StatelessWidget {
  final TransactionModel income;
  final String symbol;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _IncomeTile({
    required this.income,
    required this.symbol,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onEdit,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          title: Text(
            income.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            income.recurrenceFrequency ?? '',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$symbol${NumberFormat('#,##0.00').format(income.amount)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
