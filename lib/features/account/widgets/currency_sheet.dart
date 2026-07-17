import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class CurrencySheet extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;

  const CurrencySheet({super.key, required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select Currency',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...AppConstants.currencies.entries.map((e) {
            final isSelected = e.key == user.currency;
            return ListTile(
              onTap: () async {
                await ref
                    .read(authProvider.notifier)
                    .updateProfile(currency: e.key);
                if (context.mounted) Navigator.pop(context);
              },
              contentPadding: EdgeInsets.zero,
              leading: Text(
                e.value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              title: Text(e.key, style: GoogleFonts.inter(fontSize: 15)),
              trailing: isSelected
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}
