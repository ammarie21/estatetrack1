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
import 'package:estatetrack1/utils/return_settlement.dart';

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
  bool _rentalDaysTouched = false;
  bool _totalDueTouched = false;

  List<ContractModel> get _eligibleContracts {
    final returnedBookingIds = widget.returns
        .where((r) => r.bookingId != null)
        .map((r) => r.bookingId!)
        .toSet();
    final seenBookingIds = <int>{};
    final eligible = <ContractModel>[];
    for (final contract in widget.contracts) {
      final bookingId = contract.bookingId;
      final isExistingReturn =
          widget.existing?.bookingId != null &&
          widget.existing!.bookingId == bookingId;
      final isActiveWithoutReturn =
          contract.status == 'Active' &&
          !returnedBookingIds.contains(bookingId);
      if (!isExistingReturn && !isActiveWithoutReturn) continue;
      if (!seenBookingIds.add(bookingId)) continue;
      eligible.add(contract);
    }
    return eligible;
  }

  int? _dropdownBookingId(List<ContractModel> eligible) {
    final ids = eligible.map((c) => c.bookingId).toSet();
    final current = _bookingIdFromContract;
    if (current != null && ids.contains(current)) return current;
    if (eligible.length == 1) return eligible.first.bookingId;
    return null;
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
    _rentalDaysTouched = e != null;
    _totalDueTouched = e != null;
    if (_bookingIdFromContract == null && _eligibleContracts.length == 1) {
      _bookingIdFromContract = _eligibleContracts.first.bookingId;
    } else if (_bookingIdFromContract != null &&
        !_eligibleContracts.any(
          (c) => c.bookingId == _bookingIdFromContract,
        )) {
      _bookingIdFromContract = _eligibleContracts.length == 1
          ? _eligibleContracts.first.bookingId
          : null;
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

  int _inclusiveDays(DateTime start, DateTime end) {
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.difference(startDay).inDays + 1;
  }

  int? _suggestedRentalDays() {
    final bookingId = _bookingIdFromContract;
    final returnDate = _returnDate;
    if (bookingId == null || returnDate == null) return null;

    final contract = _contractForBooking(bookingId);
    if (contract == null) return null;

    final days = _inclusiveDays(contract.startDate, returnDate);
    return days < 1 ? 1 : days;
  }

  String? _rentalDaysHelperText() {
    final bookingId = _bookingIdFromContract;
    final returnDate = _returnDate;
    if (bookingId == null || returnDate == null) {
      return 'Select an agreement and return date to calculate rental days.';
    }

    final contract = _contractForBooking(bookingId);
    if (contract == null) return null;

    final suggested = _suggestedRentalDays();
    if (suggested == null) return null;

    final startLabel =
        contract.startDate.toIso8601String().split('T').first;
    final returnLabel = returnDate.toIso8601String().split('T').first;
    return '$suggested days from agreement start ($startLabel → $returnLabel)';
  }

  void _applySuggestedRentalDays() {
    final suggested = _suggestedRentalDays();
    if (suggested == null) return;
    _actualRentalDays.text = suggested.toString();
  }

  int _agreementDays(ContractModel contract) {
    return inclusiveDaysBetween(contract.startDate, contract.endDate);
  }

  double _proratedRent(ContractModel contract, int actualRentalDays) {
    return proratedAgreementAmount(
      agreementTotal: contract.totalAmount,
      agreementDays: _agreementDays(contract),
      actualRentalDays: actualRentalDays,
    );
  }

  int? _currentRentalDays() {
    final parsed = int.tryParse(_actualRentalDays.text.trim());
    if (parsed != null && parsed > 0) return parsed;
    return _suggestedRentalDays();
  }

  String? _totalDueHelperText() {
    final bookingId = _bookingIdFromContract;
    if (bookingId == null) return null;

    final contract = _contractForBooking(bookingId);
    final actualDays = _currentRentalDays();
    if (contract == null || actualDays == null) return null;

    final agreementDays = _agreementDays(contract);
    final prorated = _proratedRent(contract, actualDays);
    if (actualDays >= agreementDays) {
      return 'Full agreement amount for $agreementDays days.';
    }
    return 'Early checkout: \$${contract.totalAmount.toStringAsFixed(0)} for '
        '$agreementDays days prorated to $actualDays days '
        '(\$${prorated.toStringAsFixed(2)} rent).';
  }

  void _recalculateTotal({bool force = false}) {
    if (_totalDueTouched && !force) return;

    final bookingId = _bookingIdFromContract;
    if (bookingId == null) return;

    final contract = _contractForBooking(bookingId);
    final actualDays = _currentRentalDays();
    if (contract == null || actualDays == null) return;

    final additional =
        double.tryParse(_additionalCharges.text.replaceAll(',', '')) ?? 0;
    final rentDue = _proratedRent(contract, actualDays);
    _actualTotalDueAmount.text = (rentDue + additional).toStringAsFixed(2);
  }

  void _prefillFromContract(int bookingId) {
    final contract = _contractForBooking(bookingId);
    if (contract == null) return;

    if (!_rentalDaysTouched) {
      _applySuggestedRentalDays();
    }
    _recalculateTotal(force: true);
  }

  void _onRentalDaysChanged(String _) {
    setState(() {
      _rentalDaysTouched = true;
      _recalculateTotal(force: true);
    });
  }

  ReturnSettlement? _currentSettlement() {
    final bookingId = _bookingIdFromContract;
    if (bookingId == null) return null;

    final booking = _bookingForId(bookingId);
    final totalDue =
        double.tryParse(_actualTotalDueAmount.text.replaceAll(',', ''));
    if (booking == null || totalDue == null) return null;

    final finalPayment =
        double.tryParse(_finalPaymentCollected.text.replaceAll(',', '')) ?? 0;
    return ReturnSettlement.compute(
      totalDueAmount: totalDue,
      paidOnBooking: paidAmountForBooking(booking),
      finalPaymentCollected: finalPayment,
    );
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
    if (!_totalDueTouched) {
      _recalculateTotal(force: true);
    }

    final rentalDays = int.tryParse(_actualRentalDays.text.trim()) ?? 0;
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
    if (rentalDays <= 0) {
      AppSnackbars.error(context, 'Actual rental days must be at least 1');
      return;
    }
    if (additionalCharges < 0) {
      AppSnackbars.error(context, 'Additional charges cannot be negative');
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
    if (booking == null) {
      AppSnackbars.error(context, 'Linked booking not found');
      return;
    }

    final settlement = ReturnSettlement.compute(
      totalDueAmount: totalDueAmount,
      paidOnBooking: paidAmountForBooking(booking),
      finalPaymentCollected: finalPayment,
    );

    final e = widget.existing;
    final model = ApartmentReturnModel(
      returnId: e?.returnId ?? 0,
      bookingId: _bookingIdFromContract,
      actualReturnDate: _returnDate!,
      actualRentalDays: rentalDays,
      additionalCharges: additionalCharges,
      actualTotalDueAmount: totalDueAmount,
      totalRemaining: settlement.remaining,
      totalRefundedAmount: settlement.refunded,
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
        _rentalDaysTouched = false;
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

    final selectedBookingId = _dropdownBookingId(eligible);

    final contractItems = eligible
        .map(
          (c) => DropdownMenuItem(
            value: c.bookingId,
            child: Text(_contractLabel(c)),
          ),
        )
        .toList();

    final booking = selectedBookingId == null
        ? null
        : _bookingForId(selectedBookingId);
    final settlement = _currentSettlement();
    final paid = booking == null ? 0.0 : paidAmountForBooking(booking);
    final totalDue = settlement?.totalDueAmount ?? 0;
    final finalPayment = settlement?.finalPaymentCollected ?? 0;
    final totalPaid = settlement?.totalPaid ?? paid;
    final remaining = settlement?.remaining ?? 0;
    final refunded = settlement?.refunded ?? 0;

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
                  value: selectedBookingId,
                  items: contractItems,
                  onChanged: (v) => setState(() {
                    _bookingIdFromContract = v;
                    _rentalDaysTouched = false;
                    _totalDueTouched = false;
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
            onChanged: _onRentalDaysChanged,
            decoration: InputDecoration(
              labelText: 'Actual rental days',
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: const OutlineInputBorder(),
              helperText: _rentalDaysHelperText(),
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _additionalCharges,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() => _recalculateTotal(force: true)),
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
            onChanged: (_) => setState(() => _totalDueTouched = true),
            decoration: InputDecoration(
              labelText: 'Final total due',
              prefixIcon: const Icon(Icons.calculate_outlined),
              border: const OutlineInputBorder(),
              helperText: _totalDueHelperText(),
              helperMaxLines: 3,
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
                  Text('Final total due: \$${totalDue.toStringAsFixed(2)}'),
                  if (refunded > 0)
                    Text(
                      'Refund due: \$${refunded.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text('Remaining: \$${remaining.toStringAsFixed(2)}'),
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
          AppFormActions(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _save,
            saveLabel: isEdit ? 'Update Return' : 'Add Return',
          ),
        ],
      ),
    );
  }
}
