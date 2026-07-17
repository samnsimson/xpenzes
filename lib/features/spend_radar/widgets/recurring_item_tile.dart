import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';
import '../providers/spend_radar_provider.dart';

class RecurringItemTile extends StatelessWidget {
  final RecurringItem item;
  final String symbol;

  const RecurringItemTile({super.key, required this.item, required this.symbol});

  TransactionModel get transaction => item.transaction;

  bool get _isIncome => transaction.type == TransactionType.income;

  Color get _color => _isIncome
      ? AppColors.success
      : AppConstants.categoryColors[transaction.category] ??
            AppColors.textSecondary;

  IconData get _icon => _isIncome
      ? Icons.trending_up_rounded
      : AppConstants.categoryIcons[transaction.category] ?? Icons.more_horiz;

  @override
  Widget build(BuildContext context) {
    final frequency = transaction.recurrenceFrequency!;
    final monthlyEquivalent = item.monthlyEquivalent;
    final isAlreadyMonthly = frequency == 'Monthly';

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
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionDetailSheet(transaction: transaction),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_icon, color: _color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          frequency,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$symbol${transaction.amount.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (!isAlreadyMonthly) ...[
                      const SizedBox(height: 2),
                      Text(
                        '≈$symbol${monthlyEquivalent.toStringAsFixed(2)}/mo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
