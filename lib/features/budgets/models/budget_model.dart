class BudgetPace {
  // "no_budget" | "under_pace" | "on_pace" | "over_pace"
  final String paceStatus;
  final int daysElapsed;
  final int daysRemaining;
  final double projectedSpend;
  final double projectedOverage;

  const BudgetPace({
    required this.paceStatus,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.projectedSpend,
    required this.projectedOverage,
  });

  factory BudgetPace.fromJson(Map<String, dynamic> json) => BudgetPace(
    paceStatus: json['pace_status'] as String,
    daysElapsed: json['days_elapsed'] as int,
    daysRemaining: json['days_remaining'] as int,
    projectedSpend: (json['projected_spend'] as num).toDouble(),
    projectedOverage: (json['projected_overage'] as num).toDouble(),
  );
}

class BudgetModel {
  final String id;
  final String category;
  final double monthlyLimit;
  final double spent;
  final String status; // "ok" | "warning" | "exceeded"
  final BudgetPace pace;

  const BudgetModel({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.status,
    required this.pace,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
    id: json['id'] as String,
    category: json['category'] as String,
    monthlyLimit: (json['monthly_limit'] as num).toDouble(),
    spent: (json['spent'] as num).toDouble(),
    status: json['status'] as String,
    pace: BudgetPace.fromJson(json['pace'] as Map<String, dynamic>),
  );
}
