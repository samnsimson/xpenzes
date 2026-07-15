class UserModel {
  final int? id;
  final String name;
  final String email;
  final String currency;
  final bool isOnboarded;
  final DateTime createdAt;

  const UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.isOnboarded,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'email': email,
        'currency': currency,
        'is_onboarded': isOnboarded ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        email: map['email'] as String,
        currency: (map['currency'] as String?) ?? 'USD',
        isOnboarded: ((map['is_onboarded'] as int?) ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? currency,
    bool? isOnboarded,
    DateTime? createdAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        currency: currency ?? this.currency,
        isOnboarded: isOnboarded ?? this.isOnboarded,
        createdAt: createdAt ?? this.createdAt,
      );
}
