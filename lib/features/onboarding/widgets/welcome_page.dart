import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class WelcomePage extends StatelessWidget {
  final String userName;
  const WelcomePage({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, Color(0xFFD1FAE5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            userName.isNotEmpty
                ? 'Hey, ${userName.split(' ').first}!'
                : 'Welcome!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "Let's set up your account in just\na few quick steps.",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const _FeatureRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            label: 'Track income & expenses',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.pie_chart_rounded,
            color: AppColors.warning,
            label: 'See where your money goes',
          ),
          const SizedBox(height: 12),
          const _FeatureRow(
            icon: Icons.lock_rounded,
            color: AppColors.primary,
            label: 'All data stays on your device',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _FeatureRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
