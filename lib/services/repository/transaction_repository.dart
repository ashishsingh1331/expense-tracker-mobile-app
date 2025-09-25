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
