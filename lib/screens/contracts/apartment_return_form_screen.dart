import 'package:flutter/material.dart';

import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';

class ApartmentReturnFormScreen extends StatefulWidget {
  const ApartmentReturnFormScreen({
    super.key,
    this.existing,
    required this.contracts,
    required this.bookings,
    required this.returns,
    required this.customers,
    required this.buildings,
    required this.apartments,
  });

  final ApartmentReturnModel? existing;
  final List<ContractModel> contracts;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;

  @override
  State<ApartmentReturnFormScreen> createState() =>
      _ApartmentReturnFormScreenState();
}

class _ApartmentReturnFormScreenState extends State<ApartmentReturnFormScreen> {
  late final TextEditingController _actualRentalDays;
  late final TextEditingController _additionalCharges;
  late final TextEditingController _finalPaymentCollected;
  late final TextEditingController _actualTotalDueAmount;
  late final TextEditingController _finalCheckNotes;
  DateTime? _returnDate;
  int? _bookingIdFromContract;

  List<ContractModel> get _eligibleContracts {
    final returnedBookingIds = widget.returns
        .where((r) => r.bookingId != null)
        .map((r) => r.bookingId!)
        .toSet();
    return widget.contracts.where((c) {
      if (c.status != 'Active') return false;
      if (widget.existing?.bookingId == c.bookingId) return true;
      return !returnedBookingIds.contains(c.bookingId);
    }).toList();
  }

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
    _finalPaymentCollected = TextEditingController(
      text: e != null && e.finalPaymentCollected > 0
          ? e.finalPaymentCollected.toStringAsFixed(2)
          : '',
    );
    _actualTotalDueAmount = TextEditingController(
      text: e != null ? e.actualTotalDueAmount.toStringAsFixed(2) : '',
    );
    _finalCheckNotes = TextEditingController(text: e?.finalCheckNotes ?? '');
    _returnDate = e?.actualReturnDate ?? DateTime.now();
    _bookingIdFromContract = e?.bookingId;
    if (_bookingIdFromContract == null && _eligibleContracts.length == 1) {
      _bookingIdFromContract = _eligibleContracts.first.bookingId;
    }
    if (e == null && _bookingIdFromContract != null) {
      _prefillFromContract(_bookingIdFromContract!);
    }
  }

  @override
  void dispose() {
    _actualRentalDays.dispose();
    _additionalCharges.dispose();
    _finalPaymentCollected.dispose();
    _actualTotalDueAmount.dispose();
    _finalCheckNotes.dispose();
    super.dispose();
  }

  ContractModel? _contractForBooking(int bookingId) {
    return widget.contracts.where((c) => c.bookingId == bookingId).firstOrNull;
  }

  RentalBookingModel? _bookingForId(int bookingId) {
    return widget.bookings.where((b) => b.bookingId == bookingId).firstOrNull;
  }

  void _prefillFromContract(int bookingId) {
    final contract = _contractForBooking(bookingId);
    if (contract == null) return;

    final returnDate = _returnDate ?? DateTime.now();
    final days = returnDate.difference(contract.startDate).inDays;
    final rentalDays = days < 0 ? 0 : days;
    final additional =
        double.tryParse(_additionalCharges.text.replaceAll(',', '')) ?? 0;
    final totalDue = contract.totalAmount + additional;

    _actualRentalDays.text = rentalDays.toString();
    if (_actualTotalDueAmount.text.trim().isEmpty) {
      _actualTotalDueAmount.text = totalDue.toStringAsFixed(2);
    }
  }

  void _recalculateTotal() {
    final bookingId = _bookingIdFromContract;
    if (bookingId == null) return;
    final contract = _contractForBooking(bookingId);
    if (contract == null) return;

    final additional =
        double.tryParse(_additionalCharges.text.replaceAll(',', '')) ?? 0;
    _actualTotalDueAmount.text = (contract.totalAmount + additional)
        .toStringAsFixed(2);
  }

  String _contractLabel(ContractModel c) {
    var cust = 'Customer';
    for (final x in widget.customers) {
      if (x.customerId == c.customerId) {
        cust = x.name;
        break;
      }
    }
    final apt = apartmentDisplayLabelById(
      c.apartmentId,
      widget.apartments,
      widget.buildings,
    );
    return 'Booking ${c.bookingId} · $cust · $apt';
  }

  void _save() {
    final rentalDays = int.tryParse(_actualRentalDays.text) ?? 0;
    final additionalCharges =
        double.tryParse(_additionalCharges.text.replaceAll(',', '')) ?? 0;
    final finalPayment =
        double.tryParse(_finalPaymentCollected.text.replaceAll(',', '')) ?? 0;
    final totalDueAmount =
        double.tryParse(_actualTotalDueAmount.text.replaceAll(',', '')) ?? 0;

    if (_returnDate == null) {
      AppSnackbars.error(context, 'Please select return date');
      return;
    }
    if (_bookingIdFromContract == null) {
      AppSnackbars.error(context, 'Select the contract / booking');
      return;
    }
    if (finalPayment < 0) {
      AppSnackbars.error(context, 'Final payment cannot be negative');
      return;
    }
    if (totalDueAmount <= 0) {
      AppSnackbars.error(context, 'Final total due must be greater than zero');
      return;
    }

    final booking = _bookingForId(_bookingIdFromContract!);
    final paid = booking == null ? 0.0 : paidAmountForBooking(booking);
    final totalPaid = paid + finalPayment;
    final remaining = (totalDueAmount - totalPaid).clamp(0.0, double.infinity);
    final refunded = (totalPaid - totalDueAmount).clamp(0.0, double.infinity);

    final e = widget.existing;
    final model = ApartmentReturnModel(
      returnId: e?.returnId ?? 0,
      bookingId: _bookingIdFromContract,
      actualReturnDate: _returnDate!,
      actualRentalDays: rentalDays,
      additionalCharges: additionalCharges,
      actualTotalDueAmount: totalDueAmount,
      totalRemaining: remaining,
      totalRefundedAmount: refunded,
      finalCheckNotes: _finalCheckNotes.text.trim().isEmpty
          ? null
          : _finalCheckNotes.text.trim(),
      finalPaymentCollected: finalPayment,
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
        if (_bookingIdFromContract != null) {
          _prefillFromContract(_bookingIdFromContract!);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final eligible = _eligibleContracts;

    if (!isEdit && eligible.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Return')),
        body: const AppEmptyState(
          icon: Icons.home_work_outlined,
          title: 'No active agreements',
          message:
              'Create an active lease agreement first, or all active leases already have a return recorded.',
        ),
      );
    }

    final contractItems = eligible
        .map(
          (c) => DropdownMenuItem(
            value: c.bookingId,
            child: Text(_contractLabel(c)),
          ),
        )
        .toList();

    final booking = _bookingIdFromContract == null
        ? null
        : _bookingForId(_bookingIdFromContract!);
    final paid = booking == null ? 0.0 : paidAmountForBooking(booking);
    final totalDue =
        double.tryParse(_actualTotalDueAmount.text.replaceAll(',', '')) ?? 0;
    final finalPayment =
        double.tryParse(_finalPaymentCollected.text.replaceAll(',', '')) ?? 0;
    final totalPaid = paid + finalPayment;
    final remaining = (totalDue - totalPaid).clamp(0.0, double.infinity);
    final refunded = (totalPaid - totalDue).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Return' : 'Add Return')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppFlowBanner(
            icon: Icons.info_outline,
            text: isEdit
                ? 'Return edits are saved by replacing the record (delete + recreate) because the backend update path is unavailable.'
                : 'Recording a return closes the linked agreement and updates payment balances from the booking.',
          ),
          const SizedBox(height: 16),
          if (eligible.isNotEmpty)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Agreement / booking',
                prefixIcon: Icon(Icons.link_outlined),
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _bookingIdFromContract,
                  items: contractItems,
                  onChanged: (v) => setState(() {
                    _bookingIdFromContract = v;
                    if (v != null) _prefillFromContract(v);
                  }),
                ),
              ),
            )
          else
            Text(
              'No active agreements without a return. Add a lease first.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'Return date',
            date: _returnDate,
            onPick: () => _selectDate(context),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _actualRentalDays,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Actual rental days',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _additionalCharges,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_recalculateTotal),
            decoration: const InputDecoration(
              labelText: 'Additional charges',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _finalPaymentCollected,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Final payment collected now',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
              helperText: 'Added to existing booking payments before checkout',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualTotalDueAmount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Final total due',
              prefixIcon: Icon(Icons.calculate_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paid on booking: \$${paid.toStringAsFixed(2)}'),
                  Text(
                    'Final payment now: \$${finalPayment.toStringAsFixed(2)}',
                  ),
                  Text('Total paid: \$${totalPaid.toStringAsFixed(2)}'),
                  Text('Remaining: \$${remaining.toStringAsFixed(2)}'),
                  if (refunded > 0)
                    Text('Refund due: \$${refunded.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _finalCheckNotes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Final check notes',
              prefixIcon: Icon(Icons.notes_outlined),
              border: OutlineInputBorder(),
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
