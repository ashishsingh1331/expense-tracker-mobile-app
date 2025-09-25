import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/user_settings.dart';

void main() {
  group('UserSettings Model Tests', () {
    test('create valid settings', () {
      final settings = UserSettings(
        key: UserSettings.backupFileIdKey,
        value: 'file_123',
      );

      expect(settings.key, UserSettings.backupFileIdKey);
      expect(settings.value, 'file_123');
    });

    test('fromMap creates valid settings', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'key': UserSettings.lastSyncAtKey,
        'value': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final settings = UserSettings.fromMap(map);

      expect(settings.id, 1);
      expect(settings.key, UserSettings.lastSyncAtKey);
      expect(settings.value, now.toIso8601String());
      expect(settings.createdAt.isAtSameMomentAs(now), isTrue);
      expect(settings.updatedAt.isAtSameMomentAs(now), isTrue);
    });

    test('toMap creates valid map', () {
      final now = DateTime.now();
      final settings = UserSettings(
        id: 1,
        key: UserSettings.parsingRulesKey,
        value: '{"rule": "test"}',
        createdAt: now,
        updatedAt: now,
      );

      final map = settings.toMap();

      expect(map['id'], 1);
      expect(map['key'], UserSettings.parsingRulesKey);
      expect(map['value'], '{"rule": "test"}');
      expect(map['created_at'], now.toIso8601String());
      expect(map['updated_at'], now.toIso8601String());
    });

    test('getDateValue parses date correctly', () {
      final now = DateTime.now();
      final settings = UserSettings(
        key: UserSettings.lastSyncAtKey,
        value: now.toIso8601String(),
      );

      final date = settings.getDateValue();
      expect(date?.isAtSameMomentAs(now), isTrue);
    });

    test('getDateValue returns null for invalid date', () {
      final settings = UserSettings(
        key: UserSettings.lastSyncAtKey,
        value: 'not a date',
      );

      final date = settings.getDateValue();
      expect(date, isNull);
    });

    test('getDateValue returns null for null value', () {
      final settings = UserSettings(
        key: UserSettings.lastSyncAtKey,
      );

      final date = settings.getDateValue();
      expect(date, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = UserSettings(
        id: 1,
        key: 'old_key',
        value: 'old_value',
      );

      final updated = original.copyWith(
        key: 'new_key',
        value: 'new_value',
      );

      expect(updated.id, original.id);
      expect(updated.key, 'new_key');
      expect(updated.value, 'new_value');
      expect(updated != original, isTrue);
    });
  });
}