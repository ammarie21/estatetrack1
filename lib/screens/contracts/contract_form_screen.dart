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
  late final TextEditingController _initialPayment;
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
  bool _totalAmountTouched = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _totalAmount = TextEditingController(
      text: e != null ? e.totalAmount.toStringAsFixed(0) : '',
    );
    final existingBooking = e == null
        ? null
        : widget.bookings
            .where((booking) => booking.bookingId == e.bookingId)
            .firstOrNull;
    final existingInitialPayment = e?.initialPayment ?? 0;
    final paidOnBooking = existingBooking?.rentalPrice ?? 0;
    final initialPayment = existingInitialPayment > 0
        ? existingInitialPayment
        : paidOnBooking;
    _initialPayment = TextEditingController(
      text: initialPayment > 0 ? initialPayment.toStringAsFixed(0) : '',
    );
    _notes = TextEditingController(text: e?.notes ?? '');
    _selectedCustomerId = _validOption(
      e?.customerId,
      widget.customers.map((customer) => customer.customerId),
    );
    _selectedApartmentId = _validOption(
      e?.apartmentId,
      widget.apartments.map((apartment) => apartment.apartmentId),
    );
    _selectedBookingId = _validBookingId(e?.bookingId);
    _bookingType = _normalizeBookingType(e?.bookingType ?? 0);
    _status = e?.status ?? 'Active';
    _startDate = e?.startDate;
    _endDate = e?.endDate;
    _totalAmountTouched = e != null;
  }

  bool get _hasValidDateRange =>
      _startDate != null &&
      _endDate != null &&
      !_endDate!.isBefore(_startDate!);

  @override
  void dispose() {
    _totalAmount.dispose();
    _initialPayment.dispose();
    _notes.dispose();
    super.dispose();
  }

  int _normalizeBookingType(int type) => type == 1 ? 1 : 0;

  int? _validOption(int? value, Iterable<int> options) {
    final ids = options.toSet();
    if (value != null && ids.contains(value)) return value;
    return ids.isEmpty ? null : ids.first;
  }

  int _validBookingId(int? value) {
    if (widget.existing == null) return 0;
    if (value != null &&
        widget.bookings.any((booking) => booking.bookingId == value)) {
      return value;
    }
    return widget.bookings.isNotEmpty ? widget.bookings.first.bookingId : 0;
  }

  ApartmentModel? get _selectedApartment => widget.apartments
      .where((apartment) => apartment.apartmentId == _selectedApartmentId)
      .firstOrNull;

  static const double _daysPerMonth = 30;

  int _inclusiveDays(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.difference(startDay).inDays + 1;
  }

  double _monthlyProratedTotal(double monthlyRate, int days) {
    return monthlyRate * (days / _daysPerMonth);
  }

  double? _suggestedTotalAmount() {
    final apartment = _selectedApartment;
    if (apartment == null || !_hasValidDateRange) return null;

    final days = _inclusiveDays(_startDate!, _endDate!);
    if (_bookingType == 1) {
      return apartment.rentPricePerDay * days;
    }

    return _monthlyProratedTotal(apartment.rentPricePerMonth, days);
  }

  String? _amountHelperText() {
    final apartment = _selectedApartment;
    if (apartment == null) return null;

    final monthlyRate = apartment.rentPricePerMonth.toStringAsFixed(0);
    final dailyRate = apartment.rentPricePerDay.toStringAsFixed(0);

    if (!_hasValidDateRange) {
      return 'Apartment rates: \$$monthlyRate/mo · \$$dailyRate/day. '
          'Choose start and end dates to calculate a suggested total.';
    }

    final days = _inclusiveDays(_startDate!, _endDate!);
    final suggested = _suggestedTotalAmount();
    if (suggested == null) return null;

    if (_bookingType == 1) {
      return '$days days × \$$dailyRate/day = '
          '\$${suggested.toStringAsFixed(0)} suggested (editable)';
    }

    final monthlyDayRate =
        apartment.rentPricePerMonth / _daysPerMonth;
    return '$days days × \$${monthlyDayRate.toStringAsFixed(2)}/day '
        '(\$$monthlyRate/mo prorated) = '
        '\$${suggested.toStringAsFixed(0)} suggested (editable)';
  }

  void _applySuggestedAmount() {
    if (_totalAmountTouched) return;
    final suggested = _suggestedTotalAmount();
    if (suggested == null || suggested <= 0) return;
    _totalAmount.text = suggested.toStringAsFixed(0);
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
    final initialPayment =
        double.tryParse(_initialPayment.text.replaceAll(',', '')) ?? 0;
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
    if (initialPayment > totalAmount) {
      AppSnackbars.error(
        context,
        'Initial payment cannot be greater than the total amount',
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
      bookingType: _bookingType,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      initialPayment: initialPayment,
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
          value: items.any((item) => item.value == value) ? value : null,
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
        if (_hasValidDateRange) {
          _applySuggestedAmount();
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
        _bookingType = _normalizeBookingType(booking.bookingType);
        _selectedCustomerId = _validOption(
          booking.customerId,
          widget.customers.map((customer) => customer.customerId),
        );
        _selectedApartmentId = _validOption(
          booking.apartmentId,
          widget.apartments.map((apartment) => apartment.apartmentId),
        );
        _startDate = booking.startDate;
        _endDate = booking.endDate;
        _totalAmountTouched = true;
        _totalAmount.text = booking.initialTotalDueAmount.toStringAsFixed(0);
        _initialPayment.text = booking.rentalPrice > 0
            ? booking.rentalPrice.toStringAsFixed(0)
            : '';
        _notes.text = booking.initialCheckNotes ?? '';
        _startDateError = null;
        _endDateError = null;
      } else {
        _totalAmountTouched = false;
        _totalAmount.text = '';
        _initialPayment.text = '';
        if (_hasValidDateRange) {
          _applySuggestedAmount();
        }
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
              onChanged: (value) {
                setState(() {
                  _selectedApartmentId = value;
                  if (_hasValidDateRange) {
                    _applySuggestedAmount();
                  }
                });
              },
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
                setState(() {
                  _bookingType = _normalizeBookingType(value);
                  if (_hasValidDateRange) {
                    _applySuggestedAmount();
                  }
                });
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
              decoration: InputDecoration(
                labelText: 'Total Amount',
                prefixIcon: const Icon(Icons.attach_money),
                helperText: _amountHelperText(),
                helperMaxLines: 3,
              ),
              onChanged: (_) => _totalAmountTouched = true,
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
            if (_suggestedTotalAmount() != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _totalAmountTouched = false;
                      _applySuggestedAmount();
                    });
                  },
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Use suggested amount'),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _initialPayment,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: widget.existing == null
                    ? 'Initial payment (optional)'
                    : 'Initial payment',
                prefixIcon: const Icon(Icons.payments_outlined),
                helperText: widget.existing == null
                    ? 'Recorded on the booking and shown in Payments. Leave blank if none.'
                    : 'Updates the amount already paid on this booking.',
                helperMaxLines: 2,
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final payment = double.tryParse(text.replaceAll(',', ''));
                if (payment == null || payment < 0) {
                  return 'Enter a valid payment amount';
                }
                final total = double.tryParse(
                  _totalAmount.text.replaceAll(',', ''),
                );
                if (total != null && payment > total) {
                  return 'Cannot exceed total amount';
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
