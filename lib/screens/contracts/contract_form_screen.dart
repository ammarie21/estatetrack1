import 'package:flutter/material.dart';

import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';

class ContractFormScreen extends StatefulWidget {
  const ContractFormScreen({
    super.key,
    this.existing,
    required this.customers,
    required this.apartments,
    required this.bookings,
  });

  final ContractModel? existing;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<RentalBookingModel> bookings;

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  late final TextEditingController _totalAmount;
  late final TextEditingController _notes;
  late int? _selectedCustomerId;
  late int? _selectedApartmentId;
  /// `0` = create a new [RentalBookingModel] when saving the contract.
  late int _selectedBookingId;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _totalAmount = TextEditingController(
      text: e != null ? e.totalAmount.toStringAsFixed(0) : '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _selectedCustomerId = e?.customerId ??
        (widget.customers.isNotEmpty ? widget.customers.first.customerId : null);
    _selectedApartmentId = e?.apartmentId ??
        (widget.apartments.isNotEmpty ? widget.apartments.first.apartmentId : null);
    _selectedBookingId = e?.bookingId ?? 0;
    _status = e?.status ?? 'Active';
    _startDate = e?.startDate;
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    _totalAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final totalAmount = double.tryParse(_totalAmount.text.replaceAll(',', '')) ?? 0;
    final e = widget.existing;
    if (_selectedCustomerId == null ||
        _selectedApartmentId == null ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    final model = ContractModel(
      contractId: e?.contractId ?? 0,
      customerId: _selectedCustomerId!,
      apartmentId: _selectedApartmentId!,
      startDate: _startDate!,
      endDate: _endDate!,
      totalAmount: totalAmount,
      status: _status,
      bookingId: _selectedBookingId,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );
    Navigator.of(context).pop(model);
  }

  Widget _labeledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit lease agreement' : 'New lease agreement'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _labeledDropdown<int>(
            label: 'Customer',
            icon: Icons.person_outline,
            value: _selectedCustomerId,
            items: widget.customers.map((customer) {
              return DropdownMenuItem(
                value: customer.customerId,
                child: Text(customer.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCustomerId = value),
          ),
          const SizedBox(height: 12),
          _labeledDropdown<int>(
            label: 'Apartment',
            icon: Icons.apartment_outlined,
            value: _selectedApartmentId,
            items: widget.apartments.map((apartment) {
              return DropdownMenuItem(
                value: apartment.apartmentId,
                child: Text(apartment.number ?? 'Unknown'),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedApartmentId = value),
          ),
          const SizedBox(height: 12),
          _labeledDropdown<int>(
            label: 'Booking',
            icon: Icons.book_online_outlined,
            value: _selectedBookingId,
            items: [
              if (widget.existing == null)
                const DropdownMenuItem(
                  value: 0,
                  child: Text('Create new booking'),
                ),
              ...widget.bookings.map((booking) {
                return DropdownMenuItem(
                  value: booking.bookingId,
                  child: Text('Booking ${booking.bookingId}'),
                );
              }),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedBookingId = value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _startDate != null
                      ? 'Start: ${_startDate!.toString().split(' ')[0]}'
                      : 'Select Start Date',
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context, true),
                child: const Text('Pick Date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _endDate != null
                      ? 'End: ${_endDate!.toString().split(' ')[0]}'
                      : 'Select End Date',
                ),
              ),
              TextButton(
                onPressed: () => _selectDate(context, false),
                child: const Text('Pick Date'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total Amount',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          _labeledDropdown<String>(
            label: 'Status',
            icon: Icons.flag_outlined,
            value: _status,
            items: ['Active', 'Expired', 'Terminated'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _status = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Save agreement' : 'Create agreement'),
          ),
        ],
      ),
    );
  }
}