import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

/// Passwordless sign-in, three steps: email -> (name, new accounts
/// only) -> code. Supabase creates the account on first use, so
/// there's no separate sign-up path to maintain — [AuthNotifier.probeEmail]
/// is what tells us whether to show the name step at all.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

enum _Step { email, name, code }

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  _Step _step = _Step.email;
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _errorMsg = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final result = await ref.read(authProvider.notifier).probeEmail(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isExistingUser) {
        _step = _Step.code;
      } else if (result.isNewUser) {
        _step = _Step.name;
      } else {
        _errorMsg = result.errorMessage;
      }
    });
  }

  Future<void> _submitName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMsg = 'Please enter your name.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final error = await ref
        .read(authProvider.notifier)
        .sendOtp(_emailCtrl.text.trim(), name: name);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error == null) {
        _step = _Step.code;
      } else {
        _errorMsg = error;
      }
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMsg = 'Enter the code we sent you.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    final error = await ref
        .read(authProvider.notifier)
        .verifyOtp(_emailCtrl.text.trim(), code);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (error != null) _errorMsg = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Xpenzes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track smarter. Spend wiser.',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_step == _Step.email)
                        _EmailStep(
                          emailCtrl: _emailCtrl,
                          onSubmit: _submitEmail,
                          isLoading: _isLoading,
                        )
                      else if (_step == _Step.name)
                        _NameStep(
                          nameCtrl: _nameCtrl,
                          onSubmit: _submitName,
                          onChangeEmail: () => setState(() {
                            _step = _Step.email;
                            _errorMsg = null;
                          }),
                          isLoading: _isLoading,
                        )
                      else
                        _CodeStep(
                          email: _emailCtrl.text.trim(),
                          codeCtrl: _codeCtrl,
                          onSubmit: _verifyCode,
                          onChangeEmail: () => setState(() {
                            _step = _Step.email;
                            _errorMsg = null;
                          }),
                          isLoading: _isLoading,
                        ),
                      if (_errorMsg != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: GoogleFonts.inter(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  final TextEditingController emailCtrl;
  final VoidCallback onSubmit;
  final bool isLoading;

  const _EmailStep({
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

class _NameStep extends StatelessWidget {
  final TextEditingController nameCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;
  final bool isLoading;

  const _NameStep({
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

class _CodeStep extends StatelessWidget {
  final String email;
  final TextEditingController codeCtrl;
  final VoidCallback onSubmit;
  final VoidCallback onChangeEmail;
  final bool isLoading;

  const _CodeStep({
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
