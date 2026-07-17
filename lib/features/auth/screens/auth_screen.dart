import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/email_step.dart';
import '../widgets/name_step.dart';
import '../widgets/code_step.dart';

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
    if (email.isEmpty || !isValidEmail(email)) {
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
    final error = await ref.read(authProvider.notifier).sendOtp(_emailCtrl.text.trim(), name: name);
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
    final error = await ref.read(authProvider.notifier).verifyOtp(_emailCtrl.text.trim(), code);
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
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
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
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 40),
                      if (_step == _Step.email)
                        EmailStep(emailCtrl: _emailCtrl, onSubmit: _submitEmail, isLoading: _isLoading)
                      else if (_step == _Step.name)
                        NameStep(
                          nameCtrl: _nameCtrl,
                          onSubmit: _submitName,
                          onChangeEmail: () => setState(() {
                            _step = _Step.email;
                            _errorMsg = null;
                          }),
                          isLoading: _isLoading,
                        )
                      else
                        CodeStep(
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMsg!, style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
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
