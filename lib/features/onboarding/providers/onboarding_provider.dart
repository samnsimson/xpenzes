import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) =>
      OnboardingState(
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
  void setIncomeFrequency(String v) => state = state.copyWith(incomeFrequency: v);
  void reset() => state = const OnboardingState();
}
