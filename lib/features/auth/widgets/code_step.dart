import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class CodeStep extends StatelessWidget {
  final String email;
  final TextEditingController codeCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;
  final bool isLoading;

  const CodeStep({
    super.key,
    required this.email,
    required this.codeCtrl,
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
          'We sent a code to $email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '6-digit code'),
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
                : const Text('Verify & Continue'),
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
