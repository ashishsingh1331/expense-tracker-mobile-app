import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_tracker/models/user_settings.dart';

class ParsingRule {
  final String name;
  final List<String> patterns;
  final int priority;
  final bool isExpense;
  final Map<String, String> extractors;

  ParsingRule({
    required this.name,
    required this.patterns,
    required this.priority,
    required this.isExpense,
    required this.extractors,
  });

  factory ParsingRule.fromJson(Map<String, dynamic> json) {
    return ParsingRule(
      name: json['name'] as String,
      patterns: List<String>.from(json['patterns'] as List),
      priority: json['priority'] as int,
      isExpense: json['isExpense'] as bool,
      extractors: Map<String, String>.from(json['extractors'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'patterns': patterns,
      'priority': priority,
      'isExpense': isExpense,
      'extractors': extractors,
    };
  }
}

class RuleLoader {
  static const customRulesKey = 'custom_parsing_rules';
  static const defaultRulePath = 'assets/parsers/example_rules.json';

  // Load built-in rules from assets
  Future<List<ParsingRule>> loadBuiltInRules() async {
    try {
      final String jsonString = await rootBundle.loadString(defaultRulePath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ParsingRule.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Log error and return empty list if file not found or invalid
      print('Error loading built-in rules: $e');
      return [];
    }
  }

  // Load custom rules from user settings
  Future<List<ParsingRule>> loadCustomRules(UserSettings settings) async {
    try {
      final String? jsonString = settings.value;
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((json) => ParsingRule.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      // Log error and return empty list if settings invalid
      print('Error loading custom rules: $e');
      return [];
    }
  }

  // Save custom rules to user settings, returns updated settings
  Future<UserSettings> saveCustomRules(List<ParsingRule> rules, UserSettings settings) async {
    try {
      final jsonList = rules.map((rule) => rule.toJson()).toList();
      final jsonString = json.encode(jsonList);

      // Create new settings instance with new value
      return settings.copyWith(
        key: customRulesKey,
        value: jsonString,
      );
    } catch (e) {
      print('Error saving custom rules: $e');
      throw Exception('Failed to save custom rules: $e');
    }
  }

  // Add a new custom rule
  Future<UserSettings> addCustomRule(ParsingRule rule, UserSettings settings) async {
    final existingRules = await loadCustomRules(settings);
    existingRules.add(rule);
    return saveCustomRules(existingRules, settings);
  }

  // Delete a custom rule
  Future<UserSettings> deleteCustomRule(String ruleName, UserSettings settings) async {
    final existingRules = await loadCustomRules(settings);
    existingRules.removeWhere((rule) => rule.name == ruleName);
    return saveCustomRules(existingRules, settings);
  }

  // Get all rules (built-in + custom) sorted by priority
  Future<List<ParsingRule>> getAllRules(UserSettings settings) async {
    final customRules = await loadCustomRules(settings);
    final builtInRules = await loadBuiltInRules();

    final allRules = [...customRules, ...builtInRules];
    allRules.sort((a, b) => b.priority.compareTo(a.priority)); // Higher priority first

    return allRules;
  }
}
