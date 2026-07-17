import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/widgets/transaction_card.dart';
import '../../transactions/widgets/transaction_detail_sheet.dart';
import '../../subscription/widgets/pro_banner.dart';

const _bannerInterval = 5;

/// Groups [transactions] (already filtered/sorted by the caller) into a
/// flat list of date-label headers, [ProBannerMarker]s, and the
/// transactions themselves — the shape [HomeTransactionSliverList] renders.
List<Object> groupTransactionsByDate(List<TransactionModel> transactions) {
  final result = <Object>[];
  String? lastLabel;
  var transactionCount = 0;
  for (final t in transactions) {
    final label = dateLabel(t.date);
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

/// Renders the grouped transaction feed (date headers, pro banners, and
/// transaction cards) as sliver children.
class HomeTransactionSliverList extends StatelessWidget {
  final List<Object> grouped;
  final String currencySymbol;
  final ValueChanged<TransactionModel> onDeleteTransaction;

  const HomeTransactionSliverList({
    super.key,
    required this.grouped,
    required this.currencySymbol,
    required this.onDeleteTransaction,
  });

  @override
  Widget build(BuildContext context) {
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
          currencySymbol: currencySymbol,
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => TransactionDetailSheet(transaction: transaction),
          ),
          onDelete: () => onDeleteTransaction(transaction),
        );
      }, childCount: grouped.length),
    );
  }
}
