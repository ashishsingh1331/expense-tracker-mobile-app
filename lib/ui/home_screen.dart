import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:expense_tracker/services/repository/transaction_repository.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;
import 'package:expense_tracker/ui/manual_entry_screen.dart';
import 'package:intl/intl.dart';

class _ChartPoint {
  final DateTime day;
  final double amount;
  _ChartPoint(this.day, this.amount);
}

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
  List<_ChartPoint> _dailyExpenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }


class _ChartPoint {
  final DateTime day;
  final double amount;
  _ChartPoint(this.day, this.amount);
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

    // compute daily totals for last 7 days
    final last7 = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      last7.add(DateTime(now.year, now.month, now.day).subtract(Duration(days: i)));
    }
    final Map<String, double> dailyMap = {for (final d in last7) d.toIso8601String(): 0.0};
    for (final t in items) {
      if (!t.isExpense) continue;
      final keyDate = DateTime(t.date.year, t.date.month, t.date.day);
      final key = keyDate.toIso8601String();
      if (dailyMap.containsKey(key)) {
        dailyMap[key] = (dailyMap[key] ?? 0.0) + t.amount;
      }
    }
    _dailyExpenses = last7.map((d) => _ChartPoint(d, dailyMap[d.toIso8601String()] ?? 0.0)).toList();

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
                        // 7-day expense trend chart
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                          child: Card(
                            child: SizedBox(
                              height: 120,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SfCartesianChart(
                                  primaryXAxis: DateTimeAxis(intervalType: DateTimeIntervalType.days, dateFormat: DateFormat.Md()),
                                  primaryYAxis: NumericAxis(isVisible: false),
                                  series: <CartesianSeries<_ChartPoint, DateTime>>[
                                    AreaSeries<_ChartPoint, DateTime>(
                                      dataSource: _dailyExpenses,
                                      xValueMapper: (_ChartPoint p, _) => p.day,
                                      yValueMapper: (_ChartPoint p, _) => p.amount,
                                      color: Colors.red.withOpacity(0.4),
                                      borderWidth: 2,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                  onTap: () async {
                                    final res = await Navigator.of(context).push<TxnModel.Transaction?>(
                                      MaterialPageRoute(builder: (_) => ManualEntryScreen(transaction: t)),
                                    );
                                    if (res != null) {
                                      // If the returned transaction has an id, treat as update
                                      if (res.id != null) {
                                        await _repo.updateTransaction(res);
                                      } else {
                                        await _repo.insertTransaction(res);
                                      }
                                      await _load();
                                    }
                                  },
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
