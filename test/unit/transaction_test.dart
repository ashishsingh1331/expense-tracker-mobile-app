import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/transaction.dart';

void main() {
  group('Transaction Model Tests', () {
    test('create valid transaction', () {
      final transaction = Transaction(
        date: DateTime(2024, 3, 25),
        amount: 99.99,
        merchant: 'Test Store',
      );

      expect(transaction.validate(), isNull);
      expect(transaction.isExpense, isTrue);
      expect(transaction.amount, 99.99);
      expect(transaction.merchant, 'Test Store');
    });

    test('validate rejects zero amount', () {
      final transaction = Transaction(
        date: DateTime(2024, 3, 25),
        amount: 0,
        merchant: 'Test Store',
      );

      expect(transaction.validate(), contains('Amount must be greater than 0'));
    });

    test('validate rejects negative amount', () {
      final transaction = Transaction(
        date: DateTime(2024, 3, 25),
        amount: -10.0,
        merchant: 'Test Store',
      );

      expect(transaction.validate(), contains('Amount must be greater than 0'));
    });

    test('validate rejects empty merchant', () {
      final transaction = Transaction(
        date: DateTime(2024, 3, 25),
        amount: 99.99,
        merchant: '',
      );

      expect(transaction.validate(), contains('Merchant name is required'));
    });

    test('validate rejects future date', () {
      final futureDate = DateTime.now().add(const Duration(days: 1));
      final transaction = Transaction(
        date: futureDate,
        amount: 99.99,
        merchant: 'Test Store',
      );

      expect(transaction.validate(), contains('Transaction date cannot be in the future'));
    });

    test('fromMap creates valid transaction', () {
      final now = DateTime.now();
      final map = {
        'id': 1,
        'transaction_id': 'TRANS123',
        'date': now.toIso8601String(),
        'amount': 99.99,
        'merchant': 'Test Store',
        'category': 'Shopping',
        'notes': 'Test note',
        'is_expense': 1,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.id, 1);
      expect(transaction.transactionId, 'TRANS123');
      expect(transaction.date.isAtSameMomentAs(now), isTrue);
      expect(transaction.amount, 99.99);
      expect(transaction.merchant, 'Test Store');
      expect(transaction.category, 'Shopping');
      expect(transaction.notes, 'Test note');
      expect(transaction.isExpense, isTrue);
    });

    test('toMap creates valid map', () {
      final now = DateTime.now();
      final transaction = Transaction(
        id: 1,
        transactionId: 'TRANS123',
        date: now,
        amount: 99.99,
        merchant: 'Test Store',
        category: 'Shopping',
        notes: 'Test note',
        isExpense: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = transaction.toMap();

      expect(map['id'], 1);
      expect(map['transaction_id'], 'TRANS123');
      expect(map['date'], now.toIso8601String());
      expect(map['amount'], 99.99);
      expect(map['merchant'], 'Test Store');
      expect(map['category'], 'Shopping');
      expect(map['notes'], 'Test note');
      expect(map['is_expense'], 1);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Transaction(
        id: 1,
        date: DateTime(2024, 3, 25),
        amount: 99.99,
        merchant: 'Old Store',
      );

      final updated = original.copyWith(
        merchant: 'New Store',
        amount: 149.99,
      );

      expect(updated.id, original.id);
      expect(updated.date, original.date);
      expect(updated.merchant, 'New Store');
      expect(updated.amount, 149.99);
      expect(updated != original, isTrue);
    });
  });
}
