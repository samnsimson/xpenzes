import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/onboarding_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transactions_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageCtrl;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _goNext() {
    final state = ref.read(onboardingProvider);
    if (state.step < 3) {
      ref.read(onboardingProvider.notifier).nextStep();
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    }
  }

  void _goBack() {
    final state = ref.read(onboardingProvider);
    if (state.step > 0) {
      ref.read(onboardingProvider.notifier).prevStep();
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
    }
  }

  Future<void> _complete() async {
    final ob = ref.read(onboardingProvider);
    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isCompleting = true);

    // Update currency
    await ref.read(authProvider.notifier).updateProfile(currency: ob.currency);

    // Save income if provided
    final amount = double.tryParse(ob.incomeAmount);
    if (amount != null && amount > 0) {
      await ref.read(transactionsProvider.notifier).addTransaction(
            TransactionModel(
              type: TransactionType.income,
              title: ob.incomeSource,
              amount: amount,
              category: ob.incomeSource,
              date: DateTime.now(),
              isRecurring: true,
              recurrenceFrequency: ob.incomeFrequency,
            ),
          );
    }

    // Mark onboarded
    await ref.read(authProvider.notifier).completeOnboarding();
    ref.read(onboardingProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingProvider).step;
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (step > 0)
                    GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: AppColors.textPrimary),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                  const Spacer(),
                  // Step dots
                  Row(
                    children: List.generate(4, (i) {
                      final active = i == step;
                      final done = i < step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: done || active
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(userName: user?.name ?? ''),
                  const _CurrencyPage(),
                  const _IncomePage(),
                  const _CompletePage(),
                ],
              ),
            ),
            // CTA Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isCompleting
                      ? null
                      : step == 3
                          ? _complete
                          : _goNext,
                  child: _isCompleting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          step == 0
                              ? 'Get Started'
                              : step == 3
                                  ? 'Start Tracking'
                                  : 'Continue',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final String userName;
  const _WelcomePage({required this.userName});

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
                colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
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
            userName.isNotEmpty ? 'Hey, ${userName.split(' ').first}!' : 'Welcome!',
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
          _FeatureRow(
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
            label: 'Track income & expenses',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
            icon: Icons.pie_chart_rounded,
            color: AppColors.warning,
            label: 'See where your money goes',
          ),
          const SizedBox(height: 12),
          _FeatureRow(
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

  const _FeatureRow(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
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
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

// ── Page 2: Currency ─────────────────────────────────────────────────────────

class _CurrencyPage extends ConsumerWidget {
  const _CurrencyPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(onboardingProvider).currency;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.currency_exchange_rounded,
                size: 32, color: AppColors.warning),
          ),
          const SizedBox(height: 24),
          Text(
            'Choose your currency',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will be used throughout the app.',
            style: GoogleFonts.inter(
                fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          Expanded(
            child: GridView.builder(
              itemCount: AppConstants.currencies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (ctx, i) {
                final entry =
                    AppConstants.currencies.entries.elementAt(i);
                final isSelected = entry.key == selected;
                return GestureDetector(
                  onTap: () => ref
                      .read(onboardingProvider.notifier)
                      .setCurrency(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.value,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white.withOpacity(0.85)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Income ───────────────────────────────────────────────────────────

class _IncomePage extends ConsumerStatefulWidget {
  const _IncomePage();

  @override
  ConsumerState<_IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends ConsumerState<_IncomePage> {
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: ref.read(onboardingProvider).incomeAmount,
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ob = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final currency = AppConstants.currencies[ob.currency] ?? '\$';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.savings_rounded,
                size: 32, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          Text(
            'Your income',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always update this later from your account.',
            style: GoogleFonts.inter(
                fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          // Income source
          Text('Income source',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.incomeSources.map((s) {
              final isSelected = s == ob.incomeSource;
              return GestureDetector(
                onTap: () => notifier.setIncomeSource(s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Amount
          Text('Monthly amount',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          TextField(
            controller: _amountCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: notifier.setIncomeAmount,
            decoration: InputDecoration(
              hintText: '0.00',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  currency,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
            ),
          ),
          const SizedBox(height: 20),
          // Frequency
          Text('Pay frequency',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.recurrenceFrequencies.map((f) {
              final isSelected = f == ob.incomeFrequency;
              return GestureDetector(
                onTap: () => notifier.setIncomeFrequency(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Page 4: Done ─────────────────────────────────────────────────────────────

class _CompletePage extends StatelessWidget {
  const _CompletePage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 72,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            "You're all set!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your account is ready.\nStart tracking your expenses today.",
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
