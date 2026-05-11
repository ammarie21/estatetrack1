import 'package:flutter/material.dart';

import 'package:estatetrack1/models/expense_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.existing});

  final ExpenseModel? existing;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late final TextEditingController _category;
  late final TextEditingController _amount;
  late final TextEditingController _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = TextEditingController(text: e?.category ?? '');
    _amount = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _date = TextEditingController(text: e?.date ?? '');
  }

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  void _save() {
    final amt = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final e = widget.existing;
    Navigator.of(context).pop(
      ExpenseModel(
        id: e?.id ?? 0,
        category: _category.text.trim(),
        amount: amt,
        date: _date.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _date,
            decoration: const InputDecoration(
              labelText: 'Date',
              hintText: 'e.g. 2025-01-15',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}