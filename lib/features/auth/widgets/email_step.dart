import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class EmailStep extends StatelessWidget {
  final TextEditingController emailCtrl;
  final VoidCallback onSubmit;
  final bool isLoading;

  const EmailStep({
    super.key,
    required this.emailCtrl,
    required this.onSubmit,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'Email address',
            prefixIcon: Icon(
              Icons.email_outlined,
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
      ],
    );
  }
}
