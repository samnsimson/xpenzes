import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

void showEditProfileDialog(
  BuildContext context,
  WidgetRef ref,
  UserModel? user,
) {
  if (user == null) return;
  final nameCtrl = TextEditingController(text: user.name);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit Profile',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: nameCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Full name',
          prefixIcon: Icon(Icons.person_outline_rounded),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isNotEmpty) {
              await ref.read(authProvider.notifier).updateProfile(name: name);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void showSignOutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Sign Out',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Are you sure you want to sign out?',
        style: GoogleFonts.inter(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            ref.read(authProvider.notifier).signOut();
          },
          child: Text(
            'Sign Out',
            style: GoogleFonts.inter(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}
