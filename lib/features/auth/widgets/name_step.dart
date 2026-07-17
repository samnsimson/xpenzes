import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class NameStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;
  final bool isLoading;

  const NameStep({
    super.key,
    required this.nameCtrl,
    required this.onSubmit,
    required this.onChangeEmail,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "We don't have an account for that email yet — what's your name?",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Full name',
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Continue'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: isLoading ? null : onChangeEmail,
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
