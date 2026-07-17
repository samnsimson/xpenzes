import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../transactions/widgets/meter_gauge.dart';

/// The gradient header on the home screen: greeting, avatar, and the
/// income/spent/balance meter gauges for the selected month.
class HomeHeader extends StatelessWidget {
  final String userName;
  final String symbol;
  final double monthlyIncome;
  final double totalExpenses;
  final double balance;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.symbol,
    required this.monthlyIncome,
    required this.totalExpenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final gaugeMax = [monthlyIncome, totalExpenses, balance.abs(), 1.0].reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.success],
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
                        greeting(),
                        style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                      ),
                      Text(
                        userName.isNotEmpty ? userName : 'there',
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
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
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
              Row(
                children: [
                  MeterGauge(
                    label: 'Income',
                    valueText: '$symbol${compactAmount(monthlyIncome)}',
                    value: monthlyIncome,
                    max: gaugeMax,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  MeterGauge(
                    label: 'Spent',
                    valueText: '$symbol${compactAmount(totalExpenses)}',
                    value: totalExpenses,
                    max: gaugeMax,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  MeterGauge(
                    label: 'Balance',
                    valueText: '$symbol${compactAmount(balance)}',
                    value: balance < 0 ? 0 : balance,
                    max: gaugeMax,
                    color: balance >= 0 ? Colors.white : AppColors.secondary,
                    highlight: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
