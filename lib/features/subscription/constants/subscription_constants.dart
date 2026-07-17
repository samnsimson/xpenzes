enum SubscriptionPlan { monthly, yearly }

class SubscriptionConstants {
  static const String monthlyPrice = '\$4.99';
  static const String yearlyPrice = '\$39.99';
  static const String yearlySavingsLabel = 'Save 33%';

  static const List<String> features = [
    'Cloud backup & sync across devices',
    'Unlimited transaction history',
    'Advanced analytics & insights',
    'Priority customer support',
    'Export data anytime',
  ];

  static String priceFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.monthly ? monthlyPrice : yearlyPrice;

  static String periodLabelFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.monthly ? '/month' : '/year';

  static String planNameFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.monthly ? 'Pro Monthly' : 'Pro Yearly';
}
