import 'package:expense_tracker/services/parsing/rule_loader.dart';

class ParsingResult {
  final bool success;
  final Map<String, String> matches;
  final ParsingRule rule;

  ParsingResult({
    required this.success,
    required this.matches,
    required this.rule,
  });
}

class ParsedTransaction {
  final double? amount;
  final String? merchant;
  final bool isExpense;
  final double confidence;

  ParsedTransaction({
    this.amount,
    this.merchant,
    required this.isExpense,
    required this.confidence,
  });

  bool get isComplete => amount != null && merchant != null;

  @override
  String toString() => 'ParsedTransaction(amount: $amount, merchant: $merchant, isExpense: $isExpense, confidence: $confidence)';
}

class TransactionParser {
  // Apply a rule to a message string
  ParsingResult _applyRule(String message, ParsingRule rule) {
    for (final pattern in rule.patterns) {
      // Convert template pattern to regex with named capture groups
      var regexPattern = pattern;

      print('Input pattern: $pattern');
      print('Input message: $message');

      final variables = RegExp(r'\{\{(\w+)\}\}').allMatches(pattern).toList();
      final matches = <String, String>{};

      // Replace all variables with their capture groups
      for (final variable in variables) {
        final placeholder = variable.group(0)!;
        final varName = variable.group(1)!;
        final extractor = rule.extractors[varName];
        if (extractor == null) continue;

        // Replace the placeholder with a named capture group
        regexPattern = regexPattern.replaceFirst(
          placeholder,
          '(' + extractor + ')',
        );
      }

      // Make the pattern flexible with whitespace
            // Store original pattern to help with match indexing
      final originalPattern = regexPattern;

      // Add flexibility for line boundaries and whitespace
      regexPattern = r'^\s*' + regexPattern.trim() + r'\s*$';

      print('Generated regex pattern: $regexPattern');

      // Try to match the entire pattern
      final regex = RegExp(regexPattern, multiLine: true);
      final match = regex.firstMatch(message);

      print('Match result: ${match != null ? 'found' : 'not found'}');
      if (match != null) {
        print('Match groups: ${match.groupNames.map((name) => '$name: ${match.namedGroup(name)}').join(', ')}');
      }

      if (match != null) {
        // Extract named groups
        var allMatched = true;
        for (final varName in rule.extractors.keys) {
          final value = match.namedGroup(varName);
          if (value != null && value.trim().isNotEmpty) {
            matches[varName] = value.trim();
          } else {
            allMatched = false;
            break;
          }
        }

        // Only return success if we got all the variables
        if (allMatched) {
          print('Successfully matched with pattern: $pattern');
          print('Extracted matches: $matches');
          return ParsingResult(success: true, matches: matches, rule: rule);
        }
      }
    }

    return ParsingResult(success: false, matches: {}, rule: rule);
  }

  // Parse a message string using a list of rules
  ParsedTransaction? parse(String message, List<ParsingRule> rules) {
    // Try the first line for single transaction parsing
    final firstLine = message.split(RegExp(r'\r?\n')).firstWhere(
      (line) => line.trim().isNotEmpty,
      orElse: () => message,
    );

    // Sort rules by priority
    final sortedRules = List<ParsingRule>.from(rules)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // Try each rule on the first line
    for (final rule in sortedRules) {
      print('\nTrying rule: ${rule.name}');
      final result = _applyRule(firstLine, rule);
      if (result.success) {
        try {
          final amount = double.parse(result.matches['amount'] ?? '');
          final merchant = result.matches['merchant'];
          if (merchant == null) continue;

          return ParsedTransaction(
            amount: amount,
            merchant: merchant.trim(),
            isExpense: rule.isExpense,
            confidence: 1.0,
          );
        } catch (_) {
          continue;  // Skip if amount can't be parsed
        }
      }
    }

    return null;  // No rules matched
  }

  // Parse a message and return multiple possible transactions
  List<ParsedTransaction> parseMultiple(String message, List<ParsingRule> rules) {
    final results = <ParsedTransaction>[];
    final seen = <String>{};

    print('\nParseMultiple input message:\n$message');

    // Sort rules by priority for consistent matching
    final sortedRules = List<ParsingRule>.from(rules)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // Try to find transactions line by line
    final lines = message.split(RegExp(r'\r?\n'));
    print('Split into ${lines.length} lines: ${lines.map((l) => '"${l.trim()}"').join(' | ')}');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) {
        print('Skipping empty line');
        continue;
      }

      print('\nProcessing line: "$trimmedLine"');

      // Try each rule on this line
      for (final rule in sortedRules) {
        print('Trying rule: ${rule.name}');
        final result = _applyRule(trimmedLine, rule);
        if (!result.success) continue;

        try {
          final amount = double.parse(result.matches['amount'] ?? '');
          final merchant = result.matches['merchant'];
          if (merchant == null) continue;

          final key = '$amount-$merchant';
          if (seen.contains(key)) {
            print('Skipping duplicate transaction: $key');
            continue;
          }

          seen.add(key);
          final transaction = ParsedTransaction(
            amount: amount,
            merchant: merchant.trim(),
            isExpense: rule.isExpense,
            confidence: 1.0,
          );
          results.add(transaction);
          print('Added transaction: $transaction');

          // Once we match a line, move to next line
          break;
        } catch (e) {
          print('Error processing match: $e');
          continue; // Skip invalid amounts
        }
      }
    }

    print('\nFound ${results.length} transactions: $results');
    return results;
  }
}
