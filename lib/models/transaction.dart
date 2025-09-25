class Transaction {
  final int? id;
  final String? transactionId;
  final DateTime date;
  final double amount;
  final String merchant;
  final String? category;
  final String? notes;
  final bool isExpense;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    this.transactionId,
    required this.date,
    required this.amount,
    required this.merchant,
    this.category,
    this.notes,
    this.isExpense = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Create from Map (database row)
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String?,
      date: DateTime.parse(map['date'] as String),
      amount: map['amount'] as double,
      merchant: map['merchant'] as String,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      isExpense: (map['is_expense'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'date': date.toIso8601String(),
      'amount': amount,
      'merchant': merchant,
      'category': category,
      'notes': notes,
      'is_expense': isExpense ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation
  String? validate() {
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (merchant.isEmpty) {
      return 'Merchant name is required';
    }
    if (date.isAfter(DateTime.now())) {
      return 'Transaction date cannot be in the future';
    }
    return null;
  }

  // Create a copy of this transaction with some field updates
  Transaction copyWith({
    int? id,
    String? transactionId,
    DateTime? date,
    double? amount,
    String? merchant,
    String? category,
    String? notes,
    bool? isExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isExpense: isExpense ?? this.isExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction &&
        other.id == id &&
        other.transactionId == transactionId &&
        other.date.isAtSameMomentAs(date) &&
        other.amount == amount &&
        other.merchant == merchant &&
        other.category == category &&
        other.notes == notes &&
        other.isExpense == isExpense;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      transactionId,
      date,
      amount,
      merchant,
      category,
      notes,
      isExpense,
    );
  }
}
