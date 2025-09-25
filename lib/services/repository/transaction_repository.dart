import 'package:sqflite/sqflite.dart';
import 'package:expense_tracker/services/db/migrations.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;

class TransactionRepository {
  Future<Database> get _db async => await DatabaseMigrator.database;

  Future<int> insertTransaction(TxnModel.Transaction txn) async {
    final db = await _db;
    final id = await db.insert('transactions', txn.toMap());
    return id;
  }

  Future<int> countTransactions() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM transactions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Seed sample transactions if the DB is empty. Returns number of inserted rows.
  Future<int> seedSampleData() async {
    final count = await countTransactions();
    if (count > 0) return 0;

    final now = DateTime.now();
    final samples = <TxnModel.Transaction>[
      TxnModel.Transaction(date: now.subtract(const Duration(days: 2)), amount: 12.50, merchant: 'Coffee Shop', category: 'Food', notes: 'Latte', isExpense: true),
      TxnModel.Transaction(date: now.subtract(const Duration(days: 5)), amount: 45.00, merchant: 'Grocery Store', category: 'Groceries', notes: '', isExpense: true),
      TxnModel.Transaction(date: now.subtract(const Duration(days: 10)), amount: 1200.00, merchant: 'ACME Corp', category: 'Salary', notes: 'Monthly salary', isExpense: false),
      TxnModel.Transaction(date: now.subtract(const Duration(days: 20)), amount: 60.75, merchant: 'Bookstore', category: 'Books', notes: '', isExpense: true),
    ];

    int inserted = 0;
    for (final s in samples) {
      await insertTransaction(s);
      inserted++;
    }
    return inserted;
  }

  Future<List<TxnModel.Transaction>> getAllTransactions() async {
    final db = await _db;
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map((r) => TxnModel.Transaction.fromMap(r)).toList();
  }

  Future<int> updateTransaction(TxnModel.Transaction txn) async {
    final db = await _db;
    return db.update('transactions', txn.toMap(), where: 'id = ?', whereArgs: [txn.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _db;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
