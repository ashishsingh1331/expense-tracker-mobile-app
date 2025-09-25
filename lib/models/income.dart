enum RecurrenceType {
  monthly,
  quarterly,
  annual;

  @override
  String toString() => name;

  static RecurrenceType fromString(String value) {
    return RecurrenceType.values.firstWhere(
      (type) => type.name == value.toLowerCase(),
      orElse: () => throw ArgumentError('Invalid recurrence type: $value'),
    );
  }
}

class Income {
  final int? id;
  final String title;
  final double amount;
  final RecurrenceType recurrence;
  final DateTime startDate;
  final DateTime? endDate;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Income({
    this.id,
    required this.title,
    required this.amount,
    required this.recurrence,
    required this.startDate,
    this.endDate,
    this.category,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor from Map (database row)
  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: map['amount'] as double,
      recurrence: RecurrenceType.fromString(map['recurrence'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      category: map['category'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'recurrence': recurrence.toString(),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Calculate the next occurrence date after a given date
  DateTime nextDate([DateTime? after]) {
    after ??= DateTime.now();
    
    // If we haven't started yet, return start date
    if (after.isBefore(startDate)) {
      return startDate;
    }

    // If we've ended, return null
    if (endDate != null && after.isAfter(endDate!)) {
      throw StateError('No more occurrences after end date');
    }

    DateTime nextDate;
    final afterStartOfDay = DateTime(after.year, after.month, after.day);

    switch (recurrence) {
      case RecurrenceType.monthly:
        // Go to next month, same day
        nextDate = DateTime(
          after.year,
          after.month + 1,
          startDate.day,  // Maintain original day of month
        );
        break;
        
      case RecurrenceType.quarterly:
        // Align to next quarter based on start date's month
        var startMonth = startDate.month;
        var afterMonth = after.month;
        
        // Calculate how many quarters to add based on the difference
        var monthsSinceStart = (after.year - startDate.year) * 12 + (afterMonth - startMonth);
        var quartersToAdd = (monthsSinceStart ~/ 3) + 1;
        
        // Calculate target month and year
        var targetMonth = startMonth + (quartersToAdd * 3);
        var yearIncrement = (targetMonth - 1) ~/ 12;
        targetMonth = ((targetMonth - 1) % 12) + 1;
        
        nextDate = DateTime(
          startDate.year + yearIncrement,
          targetMonth,
          startDate.day,
        );
        break;
        
      case RecurrenceType.annual:
        // Go to next year, same month and day
        nextDate = DateTime(
          after.year + 1,
          startDate.month,
          startDate.day,
        );
        break;
    }

    // Handle month overflow (e.g., Jan 31 -> Feb 28)
    while (nextDate.month > 12) {
      nextDate = DateTime(
        nextDate.year + 1,
        nextDate.month - 12,
        nextDate.day,
      );
    }

    return nextDate;
  }

  // Validation
  String? validate() {
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (title.isEmpty) {
      return 'Title is required';
    }
    if (endDate != null && endDate!.isBefore(startDate)) {
      return 'End date must be after start date';
    }
    return null;
  }

  // Create a copy with some updated fields
  Income copyWith({
    int? id,
    String? title,
    double? amount,
    RecurrenceType? recurrence,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Income(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      recurrence: recurrence ?? this.recurrence,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Income &&
        other.id == id &&
        other.title == title &&
        other.amount == amount &&
        other.recurrence == recurrence &&
        other.startDate.isAtSameMomentAs(startDate) &&
        (other.endDate?.isAtSameMomentAs(endDate ?? other.endDate ?? DateTime.now()) ?? true) &&
        other.category == category &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      amount,
      recurrence,
      startDate,
      endDate,
      category,
      notes,
    );
  }
}