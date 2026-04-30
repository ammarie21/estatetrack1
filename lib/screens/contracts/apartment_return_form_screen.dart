import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';

class ApartmentReturnFormScreen extends StatefulWidget {
  const ApartmentReturnFormScreen({
    super.key,
    this.existing,
    required this.contracts,
    required this.customers,
    required this.apartments,
  });

  final ApartmentReturnModel? existing;
  final List<ContractModel> contracts;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;

  @override
  State<ApartmentReturnFormScreen> createState() => _ApartmentReturnFormScreenState();
}

class _ApartmentReturnFormScreenState extends State<ApartmentReturnFormScreen> {
  late final TextEditingController _actualRentalDays;
  late final TextEditingController _additionalCharges;
  late final TextEditingController _actualTotalDueAmount;
  late final TextEditingController _finalCheckNotes;
  DateTime? _returnDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _actualRentalDays = TextEditingController(
      text: e?.actualRentalDays.toString() ?? '',
    );
    _additionalCharges = TextEditingController(
      text: e != null ? e.additionalCharges.toStringAsFixed(2) : '0',
    );
    _actualTotalDueAmount = TextEditingController(
      text: e != null ? e.actualTotalDueAmount.toStringAsFixed(2) : '',
    );
    _finalCheckNotes = TextEditingController(text: e?.finalCheckNotes ?? '');
    _returnDate = e?.actualReturnDate;
  }

  @override
  void dispose() {
    _actualRentalDays.dispose();
    _additionalCharges.dispose();
    _actualTotalDueAmount.dispose();
    _finalCheckNotes.dispose();
    super.dispose();
  }

  void _save() {
    final rentalDays = int.tryParse(_actualRentalDays.text) ?? 0;
    final additionalCharges = double.tryParse(_additionalCharges.text) ?? 0;
    final totalDueAmount = double.tryParse(_actualTotalDueAmount.text) ?? 0;

    if (_returnDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select return date')),
      );
      return;
    }

    final e = widget.existing;
    final model = ApartmentReturnModel(
      returnId: e?.returnId ?? 0,
      actualReturnDate: _returnDate!,
      actualRentalDays: rentalDays,
      additionalCharges: additionalCharges,
      actualTotalDueAmount: totalDueAmount,
      finalCheckNotes: _finalCheckNotes.text.trim().isEmpty ? null : _finalCheckNotes.text.trim(),
    );
    Navigator.of(context).pop(model);
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _returnDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Return' : 'Add Return'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _returnDate != null
                      ? 'Return: ${_returnDate!.toString().split(' ')[0]}'
                      : 'Select Return Date',
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: const Text('Pick Date'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _actualRentalDays,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Actual Rental Days',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _additionalCharges,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Additional Charges',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualTotalDueAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Due Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _finalCheckNotes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Final Check Notes',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Update Return' : 'Add Return'),
          ),
        ],
      ),
    );
  }
}