import 'package:flutter/material.dart';

import 'package:estatetrack1/models/payment_model.dart';

class PaymentFormScreen extends StatefulWidget {
  const PaymentFormScreen({super.key, this.existing});

  final PaymentModel? existing;

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late final TextEditingController _customer;
  late final TextEditingController _apartment;
  late final TextEditingController _amount;
  late final TextEditingController _date;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _customer = TextEditingController(text: e?.customer ?? '');
    _apartment = TextEditingController(text: e?.apartment ?? '');
    _amount = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _date = TextEditingController(text: e?.date ?? '');
  }

  @override
  void dispose() {
    _customer.dispose();
    _apartment.dispose();
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  void _save() {
    final amt = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final e = widget.existing;
    Navigator.of(context).pop(
      PaymentModel(
        id: e?.id ?? 0,
        customer: _customer.text.trim(),
        apartment: _apartment.text.trim(),
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
        title: Text(isEdit ? 'Edit Payment' : 'Add Payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _customer,
            decoration: const InputDecoration(
              labelText: 'Customer',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apartment,
            decoration: const InputDecoration(
              labelText: 'Apartment',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixIcon: Icon(Icons.payments_outlined),
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
