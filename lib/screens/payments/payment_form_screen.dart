import 'package:flutter/material.dart';

import 'package:estatetrack1/models/payment_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

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
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _customer = TextEditingController(text: e?.customer ?? '');
    _apartment = TextEditingController(text: e?.apartment ?? '');
    _amount = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _date = DateTime.tryParse(e?.date ?? '') ?? DateTime.now();
  }

  @override
  void dispose() {
    _customer.dispose();
    _apartment.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amt = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    if (_customer.text.trim().isEmpty || _apartment.text.trim().isEmpty) {
      AppSnackbars.error(context, 'Enter customer and apartment details');
      return;
    }
    if (amt <= 0) {
      AppSnackbars.error(context, 'Amount must be greater than zero');
      return;
    }
    final e = widget.existing;
    Navigator.of(context).pop(
      PaymentModel(
        id: e?.id ?? 0,
        customer: _customer.text.trim(),
        apartment: _apartment.text.trim(),
        amount: amt,
        date: _date.toIso8601String().split('T').first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Payment' : 'Add Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppFlowBanner(
            icon: Icons.info_outline,
            text:
                'Legacy local payment form. Backend payments should use the Payments tab transaction workflow.',
          ),
          const SizedBox(height: 16),
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
          AppDateField(label: 'Payment date', date: _date, onPick: _pickDate),
          const SizedBox(height: 28),
          AppFormActions(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _save,
          ),
        ],
      ),
    );
  }
}
