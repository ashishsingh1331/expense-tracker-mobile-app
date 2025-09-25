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
  double _totalExpenses = 0.0;
  double _totalIncome = 0.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Seed sample data on first run if DB is empty so dashboard has content
    final currentCount = await _repo.countTransactions();
    if (currentCount == 0) {
      await _repo.seedSampleData();
    }

    final items = await _repo.getAllTransactions();
    // compute totals for current month
    final now = DateTime.now();
    final monthItems = items.where((t) => t.date.year == now.year && t.date.month == now.month).toList();
    double expenses = 0.0, income = 0.0;
    for (final t in monthItems) {
      if (t.isExpense) {
        expenses += t.amount;
      } else {
        income += t.amount;
      }
    }

    setState(() {
      _items = items;
      _totalExpenses = expenses;
      _totalIncome = income;
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
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(child: Text('No transactions yet')),
                      ],
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('Expenses', style: TextStyle(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text('-' + _totalExpenses.toStringAsFixed(2), style: const TextStyle(fontSize: 18, color: Colors.red)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('Income', style: TextStyle(fontSize: 12)),
                                      const SizedBox(height: 8),
                                      Text('+' + _totalIncome.toStringAsFixed(2), style: const TextStyle(fontSize: 18, color: Colors.green)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final t = _items[index];
                              return Dismissible(
                                key: ValueKey(t.id ?? index),
                                background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 16), child: const Icon(Icons.delete, color: Colors.white)),
                                secondaryBackground: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
                                confirmDismiss: (direction) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete'),
                                      content: const Text('Delete this transaction?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                                        TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) async {
                                  if (t.id != null) await _repo.deleteTransaction(t.id!);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
                                  await _load();
                                },
                                child: ListTile(
                                  title: Text(t.merchant),
                                  subtitle: Text('${t.date.toLocal()} • ${t.category ?? ''}'),
                                  trailing: Text((t.isExpense ? '-' : '+') + t.amount.toStringAsFixed(2)),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
