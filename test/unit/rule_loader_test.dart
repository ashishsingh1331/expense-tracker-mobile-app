import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/services/parsing/rule_loader.dart';
import 'package:expense_tracker/models/user_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ParsingRule', () {
    test('fromJson creates valid rule', () {
      final json = {
        'name': 'Test Rule',
        'patterns': ['test {{amount}} pattern'],
        'priority': 1,
        'isExpense': true,
        'extractors': {'amount': '\\d+'}
      };

      final rule = ParsingRule.fromJson(json);

      expect(rule.name, 'Test Rule');
      expect(rule.patterns, ['test {{amount}} pattern']);
      expect(rule.priority, 1);
      expect(rule.isExpense, true);
      expect(rule.extractors, {'amount': '\\d+'});
    });

    test('toJson creates valid json', () {
      final rule = ParsingRule(
        name: 'Test Rule',
        patterns: ['test {{amount}} pattern'],
        priority: 1,
        isExpense: true,
        extractors: {'amount': '\\d+'},
      );

      final json = rule.toJson();

      expect(json['name'], 'Test Rule');
      expect(json['patterns'], ['test {{amount}} pattern']);
      expect(json['priority'], 1);
      expect(json['isExpense'], true);
      expect(json['extractors'], {'amount': '\\d+'});
    });
  });

  group('RuleLoader', () {
    late RuleLoader loader;
    late UserSettings settings;

    setUp(() {
      loader = RuleLoader();
      settings = UserSettings(key: RuleLoader.customRulesKey);

      // Mock asset bundle
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        // Return example rules when asset is requested
        if (message != null) {
          final String assetPath = utf8.decode(message.buffer.asUint8List());
          if (assetPath == RuleLoader.defaultRulePath) {
            final exampleRules = [
              {
                'name': 'Built-in Rule',
                'patterns': ['test pattern'],
                'priority': 1,
                'isExpense': true,
                'extractors': {'amount': '\\d+'}
              }
            ];
            return ByteData.view(Uint8List.fromList(utf8.encode(json.encode(exampleRules))).buffer);
          }
        }
        return null;
      });
    });

    test('loadBuiltInRules loads rules from assets', () async {
      final rules = await loader.loadBuiltInRules();

      expect(rules, isNotEmpty);
      expect(rules.first.name, 'Built-in Rule');
    });

    test('loadCustomRules returns empty list for null settings value', () async {
      final rules = await loader.loadCustomRules(settings);

      expect(rules, isEmpty);
    });

    test('loadCustomRules loads rules from settings', () async {
      final customRules = [
        {
          'name': 'Custom Rule',
          'patterns': ['custom pattern'],
          'priority': 2,
          'isExpense': false,
          'extractors': {'amount': '\\d+'}
        }
      ];

      final settingsWithRules = UserSettings(
        key: 'custom_parsing_rules',
        value: json.encode(customRules),
      );

      final rules = await loader.loadCustomRules(settingsWithRules);

      expect(rules, isNotEmpty);
      expect(rules.first.name, 'Custom Rule');
    });

    test('saveCustomRules and loadCustomRules work together', () async {
      final rules = [
        ParsingRule(
          name: 'Custom Rule',
          patterns: ['custom pattern'],
          priority: 2,
          isExpense: true,
          extractors: {'amount': '\\d+'},
        )
      ];

      // Save the rules and get updated settings
      final updatedSettings = await loader.saveCustomRules(rules, settings);
      expect(updatedSettings.value, isNotNull);

      // Load from updated settings
      final loadedRules = await loader.loadCustomRules(updatedSettings);
      expect(loadedRules, isNotEmpty);
      expect(loadedRules.first.name, 'Custom Rule');
    });

    test('addCustomRule and loadCustomRules work together', () async {
      final newRule = ParsingRule(
        name: 'New Rule',
        patterns: ['new pattern'],
        priority: 3,
        isExpense: true,
        extractors: {'amount': '\\d+'},
      );

      final settings = UserSettings(
        key: RuleLoader.customRulesKey,
        value: '[]',  // Start with empty array
      );

      final updatedSettings = await loader.addCustomRule(newRule, settings);
      expect(updatedSettings.value, isNotNull);

      final rules = await loader.loadCustomRules(updatedSettings);
      expect(rules, isNotEmpty);
      expect(rules.first.name, 'New Rule');
    });

    test('deleteCustomRule removes specific rule', () async {
      // Start with some rules
      final settings = UserSettings(
        key: RuleLoader.customRulesKey,
        value: json.encode([
          {
            'name': 'To Keep',
            'patterns': ['keep pattern'],
            'priority': 1,
            'isExpense': true,
            'extractors': {'amount': '\\d+'}
          },
          {
            'name': 'To Delete',
            'patterns': ['delete pattern'],
            'priority': 2,
            'isExpense': true,
            'extractors': {'amount': '\\d+'}
          }
        ]),
      );

      // Delete one rule and get updated settings
      final updatedSettings = await loader.deleteCustomRule('To Delete', settings);
      expect(updatedSettings.value, isNotNull);

      final rules = await loader.loadCustomRules(updatedSettings);
      expect(rules, hasLength(1));
      expect(rules.first.name, 'To Keep');
    });

    test('getAllRules combines and sorts correctly', () async {
      // Start with some custom rules
      final settings = UserSettings(
        key: RuleLoader.customRulesKey,
        value: json.encode([
          {
            'name': 'Custom High Priority',
            'patterns': ['custom pattern'],
            'priority': 3,
            'isExpense': true,
            'extractors': {'amount': '\\d+'}
          },
          {
            'name': 'Custom Low Priority',
            'patterns': ['custom pattern 2'],
            'priority': 0,
            'isExpense': true,
            'extractors': {'amount': '\\d+'}
          }
        ]),
      );

      final allRules = await loader.getAllRules(settings);

      expect(allRules, hasLength(3));  // 2 custom + 1 built-in
      expect(allRules[0].name, 'Custom High Priority');
      expect(allRules[1].name, 'Built-in Rule');  // Priority 1
      expect(allRules[2].name, 'Custom Low Priority');
    });
  });
}
