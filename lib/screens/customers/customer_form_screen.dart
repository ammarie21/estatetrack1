import 'package:flutter/material.dart';

import 'package:estatetrack1/models/customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.existing});

  final CustomerModel? existing;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _idNumber;
  late final TextEditingController _apartment;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _idNumber = TextEditingController(text: e?.idNumber ?? '');
    _apartment = TextEditingController(text: e?.apartment ?? '');
    _startDate = TextEditingController(text: e?.startDate ?? '');
    _endDate = TextEditingController(text: e?.endDate ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idNumber.dispose();
    _apartment.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  void _save() {
    final e = widget.existing;
    final model = CustomerModel(
      customerId: e?.customerId ?? 0,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      nationalNum: _idNumber.text.trim(),
      numberOfRentedApartments: 1, // Default
      idNumber: _idNumber.text.trim(),
      apartment: _apartment.text.trim(),
      startDate: _startDate.text.trim(),
      endDate: _endDate.text.trim(),
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Add Customer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _idNumber,
            decoration: const InputDecoration(
              labelText: 'ID Number',
              prefixIcon: Icon(Icons.badge_outlined),
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
            controller: _startDate,
            decoration: const InputDecoration(
              labelText: 'Start Date',
              hintText: 'e.g. 2025-01-01',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _endDate,
            decoration: const InputDecoration(
              labelText: 'End Date',
              hintText: 'e.g. 2026-12-31',
              prefixIcon: Icon(Icons.event_outlined),
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
