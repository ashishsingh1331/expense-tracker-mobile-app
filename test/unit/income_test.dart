import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/income.dart';

void main() {
  group('Income Model Tests', () {
    test('create valid income', () {
      final income = Income(
        title: 'Salary',
        amount: 5000.0,
        recurrence: RecurrenceType.monthly,
        startDate: DateTime(2024, 3, 1),
      );

      expect(income.validate(), isNull);
      expect(income.amount, 5000.0);
      expect(income.recurrence, RecurrenceType.monthly);
    });

    test('validate rejects zero amount', () {
      final income = Income(
        title: 'Salary',
        amount: 0,
        recurrence: RecurrenceType.monthly,
        startDate: DateTime(2024, 3, 1),
      );

      expect(income.validate(), contains('Amount must be greater than 0'));
    });

    test('validate rejects empty title', () {
      final income = Income(
        title: '',
        amount: 5000.0,
        recurrence: RecurrenceType.monthly,
        startDate: DateTime(2024, 3, 1),
      );

      expect(income.validate(), contains('Title is required'));
    });

    test('validate rejects end date before start date', () {
      final income = Income(
        title: 'Contract',
        amount: 5000.0,
        recurrence: RecurrenceType.monthly,
        startDate: DateTime(2024, 3, 1),
        endDate: DateTime(2024, 2, 1),
      );

      expect(income.validate(), contains('End date must be after start date'));
    });

    group('nextDate calculations', () {
      test('monthly recurrence', () {
        final income = Income(
          title: 'Salary',
          amount: 5000.0,
          recurrence: RecurrenceType.monthly,
          startDate: DateTime(2024, 3, 15),
        );

        // Test next date after start
        final nextDate = income.nextDate(DateTime(2024, 3, 20));
        expect(nextDate, DateTime(2024, 4, 15));

        // Test multiple months ahead
        final futureDate = income.nextDate(DateTime(2024, 5, 20));
        expect(futureDate, DateTime(2024, 6, 15));
      });

      test('quarterly recurrence', () {
        final income = Income(
          title: 'Bonus',
          amount: 2000.0,
          recurrence: RecurrenceType.quarterly,
          startDate: DateTime(2024, 3, 15),
        );

        final nextDate = income.nextDate(DateTime(2024, 3, 20));
        expect(nextDate, DateTime(2024, 6, 15));

        final futureDate = income.nextDate(DateTime(2024, 7, 1));
        expect(futureDate, DateTime(2024, 9, 15));
      });

      test('annual recurrence', () {
        final income = Income(
          title: 'Bonus',
          amount: 10000.0,
          recurrence: RecurrenceType.annual,
          startDate: DateTime(2024, 3, 15),
        );

        final nextDate = income.nextDate(DateTime(2024, 3, 20));
        expect(nextDate, DateTime(2025, 3, 15));
      });

      test('handles end date correctly', () {
        final income = Income(
          title: 'Contract',
          amount: 5000.0,
          recurrence: RecurrenceType.monthly,
          startDate: DateTime(2024, 3, 15),
          endDate: DateTime(2024, 6, 30),
        );

        // Should work before end date
        final validDate = income.nextDate(DateTime(2024, 5, 20));
        expect(validDate, DateTime(2024, 6, 15));

        // Should throw after end date
        expect(
          () => income.nextDate(DateTime(2024, 7, 1)),
          throwsA(isA<StateError>()),
        );
      });

      test('returns start date if current date is before start', () {
        final income = Income(
          title: 'Future Income',
          amount: 5000.0,
          recurrence: RecurrenceType.monthly,
          startDate: DateTime(2024, 6, 15),
        );

        final nextDate = income.nextDate(DateTime(2024, 3, 1));
        expect(nextDate, DateTime(2024, 6, 15));
      });
    });

    test('fromMap creates valid income', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'title': 'Test Income',
        'amount': 5000.0,
        'recurrence': 'monthly',
        'start_date': now.toIso8601String(),
        'end_date': null,
        'category': 'Salary',
        'notes': 'Test note',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final income = Income.fromMap(map);

      expect(income.id, 1);
      expect(income.title, 'Test Income');
      expect(income.amount, 5000.0);
      expect(income.recurrence, RecurrenceType.monthly);
      expect(income.startDate.isAtSameMomentAs(now), isTrue);
      expect(income.endDate, isNull);
      expect(income.category, 'Salary');
      expect(income.notes, 'Test note');
    });

    test('toMap creates valid map', () {
      final now = DateTime.now();
      final income = Income(
        id: 1,
        title: 'Test Income',
        amount: 5000.0,
        recurrence: RecurrenceType.monthly,
        startDate: now,
        category: 'Salary',
        notes: 'Test note',
        createdAt: now,
        updatedAt: now,
      );

      final map = income.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Test Income');
      expect(map['amount'], 5000.0);
      expect(map['recurrence'], 'monthly');
      expect(map['start_date'], now.toIso8601String());
      expect(map['category'], 'Salary');
      expect(map['notes'], 'Test note');
    });
  });
}