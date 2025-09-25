import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class DatabaseMigrator {
  static const String _dbName = 'expense_tracker.db';
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Read and execute schema.sql
    String schema = await rootBundle.loadString('lib/services/db/schema.sql');
    List<String> statements = schema.split(';');
    
    for (String statement in statements) {
      if (statement.trim().isNotEmpty) {
        await db.execute(statement);
      }
    }
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when needed
    // For initial version, we don't need any migration logic
  }

  // Helper method to reset database (useful for testing)
  static Future<void> resetDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    
    // Delete existing database
    await deleteDatabase(path);
    
    // Reinitialize
    _database = null;
    await database;
  }
}