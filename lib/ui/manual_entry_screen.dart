import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction.dart' as TxnModel;

class ManualEntryScreen extends StatefulWidget {
  final dynamic transaction; // keep dynamic to avoid import cycles in some setups
  const ManualEntryScreen({super.key, this.transaction});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isExpense = true;

  TxnModel.Transaction? _original;

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // If a transaction was passed, prefill the form for editing
    final t = widget.transaction as TxnModel.Transaction?;
    if (t != null) {
      _original = t;
      _merchantCtrl.text = t.merchant;
      _amountCtrl.text = t.amount.toString();
      _notesCtrl.text = t.notes ?? '';
      _date = t.date;
      _isExpense = t.isExpense;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text);
    if (_original != null) {
      final updated = _original!.copyWith(
        date: _date,
        amount: amount,
        merchant: _merchantCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        isExpense: _isExpense,
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(updated);
      return;
    }

    final txn = TxnModel.Transaction(
      date: _date,
      amount: amount,
      merchant: _merchantCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      isExpense: _isExpense,
    );

    Navigator.of(context).pop(txn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(labelText: 'Merchant'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Type:'),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _isExpense,
                    onSelected: (s) => setState(() => _isExpense = true),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: !_isExpense,
                    onSelected: (s) => setState(() => _isExpense = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
