import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mock database migrator that uses in-memory database
class TestDatabaseMigrator {
  static Database? _database;
  static String schemaSQL = '''
    -- Transactions table
    CREATE TABLE IF NOT EXISTS transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_id TEXT UNIQUE,
      date TEXT NOT NULL,
      amount REAL NOT NULL,
      merchant TEXT NOT NULL,
      category TEXT,
      notes TEXT,
      is_expense BOOLEAN NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX idx_transactions_date ON transactions(date);
    CREATE INDEX idx_transactions_amount ON transactions(amount);
    CREATE INDEX idx_transactions_merchant ON transactions(merchant);

    -- Income table
    CREATE TABLE IF NOT EXISTS income (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      recurrence TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT,
      category TEXT,
      notes TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    -- User settings table
    CREATE TABLE IF NOT EXISTS user_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT NOT NULL UNIQUE,
      value TEXT,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX idx_settings_key ON user_settings(key);
  ''';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: _onCreate,
    );
    return _database!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    List<String> statements = schemaSQL.split(';');
    for (String statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Database Migration Tests', () {
    late Database db;

    setUpAll(() {
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Get a fresh database instance for each test
      db = await TestDatabaseMigrator.database;
    });

    tearDown(() async {
      // Reset database for next test
      await TestDatabaseMigrator.resetDatabase();
    });

    test('Tables are created after migration', () async {
      // Check if tables exist by trying to query them
      var tables = ['transactions', 'income', 'user_settings'];

      for (var table in tables) {
        var result = await db.query(
          table,
          limit: 1,
        );
        expect(result, isA<List>(), reason: 'Table $table should exist and be queryable');
      }
    });

    test('Indexes are created for transactions table', () async {
      var result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='transactions';"
      );

      var indexNames = result.map((row) => row['name'] as String).toList();

      expect(indexNames, containsAll([
        'idx_transactions_date',
        'idx_transactions_amount',
        'idx_transactions_merchant',
      ]));
    });

    test('Settings table has unique constraint on key column', () async {
      // Try to insert duplicate keys - should fail
      await db.insert('user_settings', {'key': 'test_key', 'value': 'value1'});

      expect(
        () => db.insert('user_settings', {'key': 'test_key', 'value': 'value2'}),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}
