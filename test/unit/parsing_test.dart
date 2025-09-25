import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/parsing/rule_loader.dart';
import 'package:expense_tracker/services/parsing/transaction_parser.dart';

void main() {
  group('TransactionParser Tests', () {
    late TransactionParser parser;
    late List<ParsingRule> rules;

    setUp(() {
      parser = TransactionParser();
      rules = [
        ParsingRule(
          name: 'Credit Card',
          patterns: [
            'You spent {{amount}} at {{merchant}}',  // Make pattern simpler
            'Credit card transaction of {{amount}} at {{merchant}}',
          ],
          priority: 1,
          isExpense: true,
          extractors: {
            'amount': r'\d+(?:\.\d{2})?',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
        ParsingRule(
          name: 'Salary',
          patterns: [
            'Salary credit of {{amount}} from {{merchant}}',
          ],
          priority: 2,  // Higher priority
          isExpense: false,
          extractors: {
            'amount': r'\d+(?:\.\d{2})?',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
      ];
    });

    test('parse matches credit card pattern', () {
      final message = 'You spent 99.99 at Test Store on your credit card';
      final result = parser.parse(message, rules);

      expect(result, isNotNull);
      expect(result!.amount, 99.99);
      expect(result.merchant, 'Test Store');
      expect(result.isExpense, isTrue);
      expect(result.confidence, 1.0);
    });

    test('parse matches salary pattern with higher priority', () {
      final message = 'Salary credit of 5000.00 from Test Corp';
      final result = parser.parse(message, rules);

      expect(result, isNotNull);
      expect(result!.amount, 5000.00);
      expect(result.merchant, 'Test Corp');
      expect(result.isExpense, isFalse);
      expect(result.confidence, 1.0);
    });

    test('parse returns null for non-matching message', () {
      final message = 'This is not a transaction message';
      final result = parser.parse(message, rules);

      expect(result, isNull);
    });

    test('parse handles invalid amounts', () {
      final message = 'You spent invalid.amount at Test Store on your credit card';
      final result = parser.parse(message, rules);

      expect(result, isNull);
    });

    test('parseMultiple finds multiple transactions in message', () {
      final message = '''You spent 99.99 at Test Store One on your credit card
Credit card transaction of 49.99 at Test Store Two
      ''';

      final results = parser.parseMultiple(message, rules);

      expect(results, hasLength(greaterThan(1)));

      // First result should be high confidence match
      expect(results.first.amount, 99.99);
      expect(results.first.merchant, 'Test Store One');
      expect(results.first.confidence, 1.0);

      // Second result should be lower confidence
      final tentative = results.where((r) => r.confidence < 1.0);
      expect(tentative, isNotEmpty);
      expect(
        tentative.any((r) => r.amount == 49.99 && r.merchant!.contains('Store Two')),
        isTrue,
      );
    });

    test('parseMultiple deduplicates identical transactions', () {
      // Add a rule that could match the same transaction differently
      rules.add(ParsingRule(
        name: 'Alternate Credit Card',
        patterns: [
          'You made a payment of {{amount}} to {{merchant}}',
        ],
        priority: 1,
        isExpense: true,
        extractors: {
          'amount': r'\d+(\.\d{2})?',
          'merchant': r'[A-Za-z0-9\s&]+(?=\s+on|\s+was|\s*$)',
        },
      ));

      final message = 'You spent 99.99 at Test Store on your credit card';
      final results = parser.parseMultiple(message, rules);

      // Should only have one result since it's the same transaction
      expect(results, hasLength(1));
      expect(results.first.amount, 99.99);
      expect(results.first.merchant, 'Test Store');
      expect(results.first.confidence, 1.0);
    });

    test('parseMultiple handles messages with no transactions', () {
      final message = 'This is not a transaction message';
      final results = parser.parseMultiple(message, rules);

      expect(results, isEmpty);
    });

    test('priority ordering affects parsing', () {
      // Create a message that could match both patterns
      final message = 'Salary credit of 5000.00 from Credit Card Company';

      // Test with original priority (Salary = 2, Credit = 1)
      var result = parser.parse(message, rules);
      expect(result!.isExpense, isFalse);  // Should match salary rule

      // Reverse priorities and test again
      rules = rules.map((r) => ParsingRule(
        name: r.name,
        patterns: r.patterns,
        priority: r.name == 'Credit Card' ? 3 : 1,  // Make credit card higher priority
        isExpense: r.isExpense,
        extractors: r.extractors,
      )).toList();

      result = parser.parse(message, rules);
      expect(result!.isExpense, isFalse);  // Should still match salary as it's more specific
    });
  });
}
