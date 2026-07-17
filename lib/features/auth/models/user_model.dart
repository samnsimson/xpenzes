class UserModel {
  final String id;
  final String name;
  final String email;
  final String currency;
  final bool isOnboarded;
  final String subscriptionPlan;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.isOnboarded,
    required this.subscriptionPlan,
    required this.createdAt,
  });

  bool get isPro => subscriptionPlan == 'pro';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    currency: json['currency'] as String,
    isOnboarded: json['is_onboarded'] as bool,
    subscriptionPlan: json['subscription_plan'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  UserModel copyWith({
    String? name,
    String? currency,
    bool? isOnboarded,
    String? subscriptionPlan,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    currency: currency ?? this.currency,
    isOnboarded: isOnboarded ?? this.isOnboarded,
    subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    createdAt: createdAt,
  );
}
