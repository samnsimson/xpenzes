enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => this == TransactionType.income ? 'income' : 'expense';

  static TransactionType fromValue(String value) =>
      value == 'income' ? TransactionType.income : TransactionType.expense;
}

class TransactionModel {
  final String? id;
  final TransactionType type;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isRecurring;
  final String? recurrenceFrequency;
  final String? recurringGroupId;
  final DateTime? createdAt;

  const TransactionModel({
    this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurringGroupId,
    this.createdAt,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        type: TransactionTypeX.fromValue(json['type'] as String),
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
        isRecurring: json['is_recurring'] as bool? ?? false,
        recurrenceFrequency: json['recurrence_frequency'] as String?,
        recurringGroupId: json['recurring_group_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  /// Body for `POST /transactions` — server assigns id/createdAt/group id.
  Map<String, dynamic> toCreateJson() => {
        'type': type.value,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'notes': notes,
        'is_recurring': isRecurring,
        'recurrence_frequency': recurrenceFrequency,
      };

  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    bool? isRecurring,
    String? recurrenceFrequency,
    String? recurringGroupId,
    DateTime? createdAt,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        type: type ?? this.type,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        notes: notes ?? this.notes,
        isRecurring: isRecurring ?? this.isRecurring,
        recurrenceFrequency: recurrenceFrequency ?? this.recurrenceFrequency,
        recurringGroupId: recurringGroupId ?? this.recurringGroupId,
        createdAt: createdAt ?? this.createdAt,
      );
}
