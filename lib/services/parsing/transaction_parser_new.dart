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
    final normalizedMessage = message.trim();

    for (final pattern in rule.patterns) {
      final matches = <String, String>{};
      var remainingPattern = pattern.trim();
      var remainingMessage = normalizedMessage;
      var success = true;

      // Get all variables from pattern
      final variables = RegExp(r'\{\{(\w+)\}\}').allMatches(pattern).toList();

      // Extract each variable in sequence
      for (var i = 0; i < variables.length && success; i++) {
        final placeholder = variables[i].group(0)!;
        final varName = variables[i].group(1)!;

        // Get text before variable
        final beforeVar = remainingPattern.substring(0, remainingPattern.indexOf(placeholder)).trim();

        // Check for exact text match if there is text before variable
        if (beforeVar.isNotEmpty) {
          final beforeIndex = remainingMessage.toLowerCase().indexOf(beforeVar.toLowerCase());
          if (beforeIndex == -1) {
            success = false;
            break;
          }

          // Remove matched text
          if (beforeIndex > 0) {
            remainingMessage = remainingMessage.substring(beforeIndex);
          }
          remainingMessage = remainingMessage.substring(beforeVar.length).trimLeft();
          remainingPattern = remainingPattern.substring(remainingPattern.indexOf(placeholder) + placeholder.length).trimLeft();
        }

        // Get extractor for this variable
        final extractor = rule.extractors[varName];
        if (extractor == null) {
          success = false;
          break;
        }

        // Try to extract value
        final match = RegExp('^\\s*(' + extractor + ')').firstMatch(remainingMessage);
        if (match == null) {
          success = false;
          break;
        }

        // Store match and continue
        matches[varName] = match.group(1)!.trim();
        remainingMessage = remainingMessage.substring(match.group(0)!.length).trimLeft();
      }

      // Check any remaining pattern text matches
      if (success) {
        final remaining = remainingPattern.trim();
        if (remaining.isEmpty || remainingMessage.trimLeft().toLowerCase().startsWith(remaining.toLowerCase())) {
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

    // Try each rule on this line
    for (final rule in sortedRules) {
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

    // Sort rules by priority for consistent matching
    final sortedRules = List<ParsingRule>.from(rules)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // Try to find transactions line by line
    for (final line in message.split(RegExp(r'\r?\n'))) {
      if (line.trim().isEmpty) continue;

      // Try each rule on this line
      for (final rule in sortedRules) {
        final result = _applyRule(line, rule);
        if (!result.success) continue;

        try {
          final amount = double.parse(result.matches['amount'] ?? '');
          final merchant = result.matches['merchant'];
          if (merchant == null) continue;

          final key = '$amount-${merchant.toLowerCase()}';
          if (seen.contains(key)) continue;

          seen.add(key);
          results.add(ParsedTransaction(
            amount: amount,
            merchant: merchant.trim(),
            isExpense: rule.isExpense,
            confidence: 1.0,
          ));

          // Once we match a line, move to next line
          break;
        } catch (_) {
          continue; // Skip invalid amounts
        }
      }
    }

    return results;
  }
}
