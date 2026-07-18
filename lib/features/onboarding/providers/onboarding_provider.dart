import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../transactions/models/transaction_model.dart';
import '../../transactions/providers/transactions_provider.dart';

class OnboardingState {
  final int step;
  final String currency;
  final String incomeSource;
  final String incomeAmount;
  final String incomeFrequency;

  const OnboardingState({
    this.step = 0,
    this.currency = 'USD',
    this.incomeSource = 'Salary',
    this.incomeAmount = '',
    this.incomeFrequency = 'Monthly',
  });

  OnboardingState copyWith({
    int? step,
    String? currency,
    String? incomeSource,
    String? incomeAmount,
    String? incomeFrequency,
  }) => OnboardingState(
    step: step ?? this.step,
    currency: currency ?? this.currency,
    incomeSource: incomeSource ?? this.incomeSource,
    incomeAmount: incomeAmount ?? this.incomeAmount,
    incomeFrequency: incomeFrequency ?? this.incomeFrequency,
  );
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: state.step - 1);
  void setCurrency(String v) => state = state.copyWith(currency: v);
  void setIncomeSource(String v) => state = state.copyWith(incomeSource: v);
  void setIncomeAmount(String v) => state = state.copyWith(incomeAmount: v);
  void setIncomeFrequency(String v) =>
      state = state.copyWith(incomeFrequency: v);
  void reset() => state = const OnboardingState();

  /// Saves the currency/income collected across the onboarding steps and
  /// marks the account onboarded. Orchestrates three separate API calls
  /// (profile currency, optional income transaction, onboarding flag) as
  /// one workflow, matching how [AuthNotifier]/[TransactionsNotifier] own
  /// their own multi-step calls rather than leaving sequencing to the UI.
  Future<void> completeOnboarding() async {
    final ob = state;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    await ref.read(authProvider.notifier).updateProfile(currency: ob.currency);

    final amount = double.tryParse(ob.incomeAmount);
    if (amount != null && amount > 0) {
      await ref
          .read(transactionsProvider.notifier)
          .addTransaction(
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

    await ref.read(authProvider.notifier).completeOnboarding();
    reset();
  }
}
