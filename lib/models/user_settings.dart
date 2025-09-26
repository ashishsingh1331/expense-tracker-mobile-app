class UserSettings {
  final int? id;
  final String key;
  final String? value;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSettings({
    this.id,
    required this.key,
    this.value,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Constants for settings keys
  static const String backupFileIdKey = 'backup_file_id';
  static const String lastSyncAtKey = 'last_sync_at';
  static const String parsingRulesKey = 'parsing_rules';
  static const String customCategoriesKey = 'custom_categories';

  // Factory constructor from Map (database row)
  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      id: map['id'] as int?,
      key: map['key'] as String,
      value: map['value'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to parse ISO8601 date string from value
  DateTime? getDateValue() {
    if (value == null) return null;
    try {
      return DateTime.parse(value!);
    } catch (e) {
      return null;
    }
  }

  // Helper method to parse JSON string from value
  Map<String, dynamic>? getJsonValue() {
    if (value == null) return null;
    try {
      return Map<String, dynamic>.from(
        DateTime.parse(value!) as Map,
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to parse list from JSON string
  List<String>? getListValue() {
    if (value == null) return null;
    try {
      return List<String>.from(
        DateTime.parse(value!) as List,
      );
    } catch (e) {
      return null;
    }
  }

  // Create a copy with some updated fields
  UserSettings copyWith({
    int? id,
    String? key,
    String? value,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSettings &&
        other.id == id &&
        other.key == key &&
        other.value == value;
  }

  @override
  int get hashCode => Object.hash(id, key, value);
}
