import 'package:flutter/material.dart';
import 'package:expense_tracker/services/repository/transaction_repository.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;
import 'package:expense_tracker/ui/manual_entry_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionRepository _repo = TransactionRepository();
  List<TxnModel.Transaction> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _repo.getAllTransactions();
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _onAdd() async {
    final saved = await Navigator.of(context).push<TxnModel.Transaction?>(
      MaterialPageRoute(builder: (_) => const ManualEntryScreen()),
    );
    if (saved != null) {
      await _repo.insertTransaction(saved);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No transactions yet'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final t = _items[index];
                    return ListTile(
                      title: Text(t.merchant),
                      subtitle: Text('${t.date.toLocal()} • ${t.category ?? ''}'),
                      trailing: Text((t.isExpense ? '-' : '+') + t.amount.toStringAsFixed(2)),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
