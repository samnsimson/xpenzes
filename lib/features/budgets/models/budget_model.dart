class BudgetModel {
  final String id;
  final String category;
  final double monthlyLimit;
  final double spent;
  final String status; // "ok" | "warning" | "exceeded"

  const BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.status,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        category: json['category'] as String,
        monthlyLimit: (json['monthly_limit'] as num).toDouble(),
        spent: (json['spent'] as num).toDouble(),
        status: json['status'] as String,
      );
}
