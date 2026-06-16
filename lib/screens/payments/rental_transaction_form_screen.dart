import 'package:flutter/material.dart';
import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';

class RentalTransactionFormScreen extends StatefulWidget {
  const RentalTransactionFormScreen({
    super.key,
    this.existing,
    required this.bookings,
    required this.returns,
    required this.customers,
    required this.buildings,
    required this.apartments,
  });

  final RentalTransactionModel? existing;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;

  @override
  State<RentalTransactionFormScreen> createState() =>
      _RentalTransactionFormScreenState();
}

class _RentalTransactionFormScreenState
    extends State<RentalTransactionFormScreen> {
  late final TextEditingController _paymentDetails;
  late final TextEditingController _paidInitial;
  late final TextEditingController _actualTotal;
  late final TextEditingController _remaining;
  late final TextEditingController _refunded;
  int? _bookingId;
  int? _returnId;
  late String _status;
  DateTime _txnDate = DateTime.now();
  double _currentPaid = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _paymentDetails = TextEditingController(text: e?.paymentDetails ?? '');
    _paidInitial = TextEditingController();
    _actualTotal = TextEditingController(
      text: e != null ? e.actualTotalDueAmount.toStringAsFixed(2) : '',
    );
    _remaining = TextEditingController(
      text: e != null ? e.totalRemaining.toStringAsFixed(2) : '',
    );
    _refunded = TextEditingController(
      text: e != null ? e.totalRefundedAmount.toStringAsFixed(2) : '0',
    );
    _bookingId =
        e?.bookingId ??
        (widget.bookings.isNotEmpty ? widget.bookings.first.bookingId : null);
    _returnId = e?.returnId;
    _status = e?.transactionStatus ?? 'Pending';
    _txnDate = e?.updatedTransactionDate ?? DateTime.now();
    if (_bookingId != null) {
      _prefillFromBooking(_bookingId!);
    }
  }

  RentalBookingModel? _bookingById(int id) {
    return widget.bookings.where((b) => b.bookingId == id).firstOrNull;
  }

  ApartmentReturnModel? _returnForBooking(int bookingId) {
    return widget.returns.where((r) => r.bookingId == bookingId).firstOrNull;
  }

  void _prefillFromBooking(int bookingId) {
    final booking = _bookingById(bookingId);
    if (booking == null) return;

    final relatedReturn = _returnForBooking(bookingId);
    final total =
        relatedReturn?.actualTotalDueAmount ?? booking.initialTotalDueAmount;
    final paid = paidAmountForBooking(booking);
    _currentPaid = paid;
    final remaining = (total - paid).clamp(0.0, double.infinity);

    _actualTotal.text = total.toStringAsFixed(2);
    _remaining.text = remaining.toStringAsFixed(2);
    _status = transactionStatusFor(paid: paid, total: total);
    _paidInitial.clear();
    _paymentDetails.clear();
    if (relatedReturn != null) {
      _returnId = relatedReturn.returnId;
      _txnDate = relatedReturn.actualReturnDate;
    }
  }

  void _recalculateTotals() {
    final payment = double.tryParse(_paidInitial.text.replaceAll(',', '')) ?? 0;
    final total = double.tryParse(_actualTotal.text.replaceAll(',', '')) ?? 0;
    final paid = _currentPaid + payment;
    final remaining = (total - paid).clamp(0.0, double.infinity);
    final refunded = paid > total ? paid - total : 0.0;
    _remaining.text = remaining.toStringAsFixed(2);
    _refunded.text = refunded.toStringAsFixed(2);
    _status = transactionStatusFor(paid: paid, total: total);
  }

  String? _combinedPaymentDetails({
    required RentalBookingModel booking,
    required double payment,
  }) {
    final existing = (booking.paymentDetails ?? booking.initialCheckNotes ?? '')
        .trim();
    final note = _paymentDetails.text.trim();
    final date = _txnDate.toIso8601String().split('T').first;
    final line =
        '$date: received \$${payment.toStringAsFixed(2)}'
        '${note.isEmpty ? '' : ' - $note'}';
    if (existing.isEmpty) return line;
    return '$existing\n$line';
  }

  @override
  void dispose() {
    _paymentDetails.dispose();
    _paidInitial.dispose();
    _actualTotal.dispose();
    _remaining.dispose();
    _refunded.dispose();
    super.dispose();
  }

  String _bookingLabel(RentalBookingModel b) {
    final cust = widget.customers
        .where((c) => c.customerId == b.customerId)
        .map((c) => c.name)
        .firstWhere((_) => true, orElse: () => 'Customer ${b.customerId}');
    final apt = apartmentDisplayLabelById(
      b.apartmentId,
      widget.apartments,
      widget.buildings,
    );
    return 'Booking ${b.bookingId} · $cust · $apt';
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _txnDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _txnDate = picked);
  }

  void _save() {
    if (_bookingId == null) {
      AppSnackbars.error(context, 'Select a booking');
      return;
    }
    final booking = _bookingById(_bookingId!);
    if (booking == null) {
      AppSnackbars.error(context, 'Selected booking was not found');
      return;
    }
    final payment = double.tryParse(_paidInitial.text.replaceAll(',', '')) ?? 0;
    final actual = double.tryParse(_actualTotal.text.replaceAll(',', '')) ?? 0;
    if (payment <= 0) {
      AppSnackbars.error(context, 'Payment received must be greater than zero');
      return;
    }
    if (actual <= 0) {
      AppSnackbars.error(context, 'Total due must be greater than zero');
      return;
    }
    final paid = _currentPaid + payment;
    final remain = double.tryParse(_remaining.text.replaceAll(',', '')) ?? 0;
    final refund = double.tryParse(_refunded.text.replaceAll(',', '')) ?? 0;

    final e = widget.existing;
    Navigator.of(context).pop(
      RentalTransactionModel(
        transactionId: e?.transactionId ?? 0,
        bookingId: _bookingId!,
        returnId: _returnId,
        paidInitialTotalDueAmount: paid,
        actualTotalDueAmount: actual,
        totalRemaining: remain,
        totalRefundedAmount: refund,
        transactionStatus: _status,
        updatedTransactionDate: _txnDate,
        paymentDetails: _combinedPaymentDetails(
          booking: booking,
          payment: payment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    if (widget.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rental transaction')),
        body: const AppEmptyState(
          icon: Icons.handshake_outlined,
          title: 'No bookings yet',
          message:
              'Create a lease agreement (with a booking) first, then you can record payments.',
        ),
      );
    }
    final returnChoices = _bookingId != null
        ? widget.returns.where((r) => r.bookingId == _bookingId).toList()
        : <ApartmentReturnModel>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Receive another payment' : 'Receive payment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppFlowBanner(
            icon: Icons.sync_alt_rounded,
            text:
                'Enter the new amount received. The app adds it to the booking paid total and recalculates the remaining balance.',
          ),
          const SizedBox(height: 16),
          _labeledDropdown<int>(
            label: 'Booking',
            icon: Icons.book_online_outlined,
            value: _bookingId,
            items: widget.bookings.map((b) {
              return DropdownMenuItem<int>(
                value: b.bookingId,
                child: Text(_bookingLabel(b)),
              );
            }).toList(),
            onChanged: (v) => setState(() {
              _bookingId = v;
              _returnId = null;
              if (v != null) _prefillFromBooking(v);
            }),
          ),
          const SizedBox(height: 12),
          _labeledDropdown<int?>(
            label: 'Apartment return (optional)',
            icon: Icons.home_work_outlined,
            value: _returnId,
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('None (installment / before checkout)'),
              ),
              ...returnChoices.map((r) {
                return DropdownMenuItem<int?>(
                  value: r.returnId,
                  child: Text(
                    'Return #${r.returnId} · ${r.actualReturnDate.toString().split(' ')[0]}',
                  ),
                );
              }),
            ],
            onChanged: (v) => setState(() => _returnId = v),
          ),
          const SizedBox(height: 12),
          AppDateField(
            label: 'Transaction date',
            date: _txnDate,
            onPick: _pickDate,
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Already paid',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text('\$${_currentPaid.toStringAsFixed(2)}'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidInitial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_recalculateTotals),
            decoration: const InputDecoration(
              labelText: 'Payment received now',
              prefixIcon: Icon(Icons.payments_outlined),
              helperText: 'This amount is added to the existing paid total',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualTotal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(_recalculateTotals),
            decoration: const InputDecoration(
              labelText: 'Total due (booking or return)',
              prefixIcon: Icon(Icons.calculate_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remaining,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Total remaining',
              prefixIcon: Icon(Icons.hourglass_bottom_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refunded,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Total refunded',
              prefixIcon: Icon(Icons.replay_outlined),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Transaction status',
              prefixIcon: Icon(Icons.flag_outlined),
              border: OutlineInputBorder(),
            ),
            child: Text(_status),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentDetails,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Payment note',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save payment')),
        ],
      ),
    );
  }
}
