class BudgetModel {
  final int? id;
  final int userId;
  final String category;
  final double monthlyLimit;
  final DateTime createdAt;

  const BudgetModel({
    this.id,
    required this.userId,
    required this.category,
    required this.monthlyLimit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId,
    'category': category,
    'monthly_limit': monthlyLimit,
    'created_at': createdAt.toIso8601String(),
  };

  factory BudgetModel.fromMap(Map<String, dynamic> map) => BudgetModel(
    id: map['id'] as int?,
    userId: map['user_id'] as int,
    category: map['category'] as String,
    monthlyLimit: (map['monthly_limit'] as num).toDouble(),
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  BudgetModel copyWith({
    int? id,
    int? userId,
    String? category,
    double? monthlyLimit,
    DateTime? createdAt,
  }) => BudgetModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    createdAt: createdAt ?? this.createdAt,
  );
}
