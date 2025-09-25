import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/parsing/transaction_parser_new.dart';
import 'package:expense_tracker/services/parsing/rule_loader.dart';

void main() {
  group('TransactionParser Tests', () {
    late TransactionParser parser;

    setUp(() {
      parser = TransactionParser();
    });

    test('Parse single transaction from HDFC debit message', () {
      final rules = [
        ParsingRule(
          name: 'hdfc-debit',
          priority: 1,
          isExpense: true,
          patterns: [
            'Rs {{amount}} spent on HDFC Bank Card ending {{cardnum}} at {{merchant}} on',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'cardnum': r'\d{4}',
            'merchant': r'[A-Za-z0-9\s&\-]+?(?=\s+on\s+)',
          },
        ),
      ];

      final message = 'Rs 1234.56 spent on HDFC Bank Card ending 1234 at AMAZON RETAIL on 01/01/2024';
      final result = parser.parse(message, rules);

      expect(result, isNotNull);
      expect(result!.amount, equals(1234.56));
      expect(result.merchant, equals('AMAZON RETAIL'));
      expect(result.isExpense, isTrue);
    });

    test('Parse multiple transactions from HDFC statement', () {
      final rules = [
        ParsingRule(
          name: 'hdfc-statement',
          priority: 1,
          isExpense: true,
          patterns: [
            'Rs {{amount}} at {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
      ];

      final message = '''
        Statement:
        Rs 100.00 at GROCERY STORE
        Rs 50.50 at CAFE
        Rs 75.25 at BOOKSTORE
      ''';

      final results = parser.parseMultiple(message, rules);

      expect(results.length, equals(3));
      expect(results[0].amount, equals(100.00));
      expect(results[0].merchant, equals('GROCERY STORE'));
      expect(results[1].amount, equals(50.50));
      expect(results[1].merchant, equals('CAFE'));
      expect(results[2].amount, equals(75.25));
      expect(results[2].merchant, equals('BOOKSTORE'));
    });

    test('Parse with multiple rules prioritized correctly', () {
      final rules = [
        ParsingRule(
          name: 'specific-format',
          priority: 2,
          isExpense: true,
          patterns: [
            'DEBIT: {{amount}} from Card ending {{cardnum}} at {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'cardnum': r'\d{4}',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
        ParsingRule(
          name: 'generic-format',
          priority: 1,
          isExpense: true,
          patterns: [
            'Rs {{amount}} at {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
      ];

      final message = 'DEBIT: 500.00 from Card ending 5678 at STORE-NAME';
      final result = parser.parse(message, rules);

      expect(result, isNotNull);
      expect(result!.amount, equals(500.00));
      expect(result.merchant, equals('STORE-NAME'));
    });

    test('Handle no matches gracefully', () {
      final rules = [
        ParsingRule(
          name: 'test-rule',
          priority: 1,
          isExpense: true,
          patterns: [
            'PAYMENT of Rs {{amount}} to {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'merchant': r'[A-Za-z0-9\s]+',
          },
        ),
      ];

      final message = 'This is not a transaction message';
      final result = parser.parse(message, rules);

      expect(result, isNull);
    });

    test('Skip duplicate transactions in multiple parsing', () {
      final rules = [
        ParsingRule(
          name: 'simple-rule',
          priority: 1,
          isExpense: true,
          patterns: [
            'Rs {{amount}} at {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'merchant': r'[A-Za-z0-9\s]+',
          },
        ),
      ];

      final message = '''
        Rs 100.00 at STORE
        Rs 100.00 at STORE
        Rs 200.00 at STORE
      ''';

      final results = parser.parseMultiple(message, rules);

      expect(results.length, equals(2));
      expect(results[0].amount, equals(100.00));
      expect(results[1].amount, equals(200.00));
    });

    test('Handle case-insensitive pattern matching', () {
      final rules = [
        ParsingRule(
          name: 'case-test',
          priority: 1,
          isExpense: true,
          patterns: [
            'DEBIT {{amount}} To {{merchant}}',
          ],
          extractors: {
            'amount': r'\d+(?:\.\d{1,2})?',
            'merchant': r'[A-Za-z0-9\s&\-]+',
          },
        ),
      ];

      final message = 'debit 75.50 to COFFEE SHOP';
      final result = parser.parse(message, rules);

      expect(result, isNotNull);
      expect(result!.amount, equals(75.50));
      expect(result.merchant, equals('COFFEE SHOP'));
    });
  });
}
