enum TransactionType { income, expense }

extension TransactionTypeX on TransactionType {
  String get value => this == TransactionType.income ? 'income' : 'expense';

  static TransactionType fromValue(String value) =>
      value == 'income' ? TransactionType.income : TransactionType.expense;
}

class TransactionModel {
  final int? id;
  final int userId;
  final TransactionType type;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isRecurring;
  final String? recurrenceFrequency;
  final String? recurringGroupId;
  final DateTime createdAt;

  const TransactionModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    this.isRecurring = false,
    this.recurrenceFrequency,
    this.recurringGroupId,
    required this.createdAt,
  });

  bool get isFuture => date.isAfter(DateTime.now());

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'type': type.value,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'notes': notes,
        'is_recurring': isRecurring ? 1 : 0,
        'recurrence_frequency': recurrenceFrequency,
        'recurring_group_id': recurringGroupId,
        'created_at': createdAt.toIso8601String(),
      };

  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: TransactionTypeX.fromValue(map['type'] as String),
        title: map['title'] as String,
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] as String,
        date: DateTime.parse(map['date'] as String),
        notes: map['notes'] as String?,
        isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
        recurrenceFrequency: map['recurrence_frequency'] as String?,
        recurringGroupId: map['recurring_group_id'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  TransactionModel copyWith({
    int? id,
    int? userId,
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
        userId: userId ?? this.userId,
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
