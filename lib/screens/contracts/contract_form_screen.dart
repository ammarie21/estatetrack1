import 'package:flutter/material.dart';

import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';

class ContractFormScreen extends StatefulWidget {
  const ContractFormScreen({
    super.key,
    this.existing,
    required this.customers,
    required this.buildings,
    required this.apartments,
    required this.bookings,
  });

  final ContractModel? existing;
  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final List<RentalBookingModel> bookings;

  @override
  State<ContractFormScreen> createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _totalAmount;
  late final TextEditingController _notes;
  late int? _selectedCustomerId;
  late int? _selectedApartmentId;

  /// `0` = create a new [RentalBookingModel] when saving the contract.
  late int _selectedBookingId;
  late int _bookingType;
  late String _status;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _startDateError;
  String? _endDateError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _totalAmount = TextEditingController(
      text: e != null ? e.totalAmount.toStringAsFixed(0) : '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _selectedCustomerId =
        e?.customerId ??
        (widget.customers.isNotEmpty
            ? widget.customers.first.customerId
            : null);
    _selectedApartmentId =
        e?.apartmentId ??
        (widget.apartments.isNotEmpty
            ? widget.apartments.first.apartmentId
            : null);
    _selectedBookingId = e?.bookingId ?? 0;
    _bookingType = e?.bookingType ?? 0;
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
    setState(() {
      _startDateError = _startDate == null ? 'Start date is required' : null;
      _endDateError = _endDate == null ? 'End date is required' : null;
    });
    if (!_formKey.currentState!.validate()) {
      AppSnackbars.error(context, 'Please fix the highlighted fields');
      return;
    }
    final totalAmount =
        double.tryParse(_totalAmount.text.replaceAll(',', '')) ?? 0;
    final e = widget.existing;
    if (_selectedCustomerId == null ||
        _selectedApartmentId == null ||
        _startDate == null ||
        _endDate == null) {
      AppSnackbars.error(context, 'Please fill all required fields');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      setState(() {
        _endDateError = 'End date must be on or after start date';
      });
      AppSnackbars.error(context, 'Please fix the highlighted fields');
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
      bookingType: _bookingType,
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
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateError = null;
        } else {
          _endDate = picked;
          _endDateError = null;
        }
      });
    }
  }

  void _selectBooking(int value) {
    final booking = widget.bookings
        .where((item) => item.bookingId == value)
        .firstOrNull;
    setState(() {
      _selectedBookingId = value;
      if (booking != null) {
        _bookingType = booking.bookingType;
        _selectedCustomerId = booking.customerId;
        _selectedApartmentId = booking.apartmentId;
        _startDate = booking.startDate;
        _endDate = booking.endDate;
        _totalAmount.text = booking.initialTotalDueAmount.toStringAsFixed(0);
        _notes.text = booking.initialCheckNotes ?? '';
        _startDateError = null;
        _endDateError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    if (widget.customers.isEmpty || widget.apartments.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? 'Edit lease agreement' : 'New lease agreement'),
        ),
        body: AppEmptyState(
          icon: Icons.handshake_outlined,
          title: 'Prerequisites missing',
          message: widget.customers.isEmpty
              ? 'Add at least one customer before creating an agreement.'
              : 'Add at least one apartment in Buildings before creating an agreement.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit lease agreement' : 'New lease agreement'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const AppFlowBanner(
              icon: Icons.info_outline,
              text:
                  'Contracts are saved as rental bookings. Status is derived from returns and is not sent to the backend.',
            ),
            const SizedBox(height: 16),
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
                  child: Text(
                    apartmentDisplayLabel(apartment, widget.buildings),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => _selectedApartmentId = value),
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
                _selectBooking(value);
              },
            ),
            const SizedBox(height: 12),
            _labeledDropdown<int>(
              label: 'Rental type',
              icon: Icons.schedule_outlined,
              value: _bookingType,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Monthly rental')),
                DropdownMenuItem(value: 1, child: Text('Daily rental')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _bookingType = value);
              },
            ),
            const SizedBox(height: 12),
            AppDateField(
              label: 'Start date',
              date: _startDate,
              onPick: () => _selectDate(context, true),
              errorText: _startDateError,
            ),
            const SizedBox(height: 12),
            AppDateField(
              label: 'End date',
              date: _endDate,
              onPick: () => _selectDate(context, false),
              errorText: _endDateError,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalAmount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Total Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                final total = double.tryParse(
                  (value ?? '').replaceAll(',', ''),
                );
                if (total == null || total <= 0) {
                  return 'Total amount must be greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Status (derived)',
                prefixIcon: Icon(Icons.flag_outlined),
                border: OutlineInputBorder(),
                helperText: 'Updated automatically when a return is recorded',
              ),
              child: Text(_status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 20),
            AppFormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
              saveLabel: isEdit ? 'Save agreement' : 'Create agreement',
            ),
          ],
        ),
      ),
    );
  }
}
