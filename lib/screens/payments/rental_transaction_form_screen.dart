import 'package:flutter/material.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

class RentalTransactionFormScreen extends StatefulWidget {
  const RentalTransactionFormScreen({
    super.key,
    this.existing,
    required this.bookings,
    required this.returns,
    required this.customers,
    required this.apartments,
  });

  final RentalTransactionModel? existing;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<CustomerModel> customers;
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

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _paymentDetails = TextEditingController(text: e?.paymentDetails ?? '');
    _paidInitial = TextEditingController(
      text: e != null ? e.paidInitialTotalDueAmount.toStringAsFixed(2) : '',
    );
    _actualTotal = TextEditingController(
      text: e != null ? e.actualTotalDueAmount.toStringAsFixed(2) : '',
    );
    _remaining = TextEditingController(
      text: e != null ? e.totalRemaining.toStringAsFixed(2) : '',
    );
    _refunded = TextEditingController(
      text: e != null ? e.totalRefundedAmount.toStringAsFixed(2) : '0',
    );
    _bookingId = e?.bookingId ??
        (widget.bookings.isNotEmpty ? widget.bookings.first.bookingId : null);
    _returnId = e?.returnId;
    _status = e?.transactionStatus ?? 'Pending';
    _txnDate = e?.updatedTransactionDate ?? DateTime.now();
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
    final apt = widget.apartments
        .where((a) => a.apartmentId == b.apartmentId)
        .map((a) => a.number ?? '#${a.apartmentId}')
        .firstWhere((_) => true, orElse: () => 'Apt ${b.apartmentId}');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a booking')),
      );
      return;
    }
    final paid = double.tryParse(_paidInitial.text.replaceAll(',', '')) ?? 0;
    final actual = double.tryParse(_actualTotal.text.replaceAll(',', '')) ?? 0;
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
        paymentDetails: _paymentDetails.text.trim().isEmpty
            ? null
            : _paymentDetails.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    if (widget.bookings.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rental transaction')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Create a contract (with a booking) first, then you can record rental transactions.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final returnChoices = _bookingId != null
        ? widget.returns.where((r) => r.bookingId == _bookingId).toList()
        : <ApartmentReturnModel>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit rental transaction' : 'New rental transaction'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Transaction date: ${_txnDate.toString().split(' ')[0]}',
                ),
              ),
              TextButton(onPressed: _pickDate, child: const Text('Change')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paidInitial,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Paid initial / installment amount',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actualTotal,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Actual total due amount',
              prefixIcon: Icon(Icons.calculate_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remaining,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total remaining',
              prefixIcon: Icon(Icons.hourglass_bottom_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _refunded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total refunded',
              prefixIcon: Icon(Icons.replay_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _labeledDropdown<String>(
            label: 'Transaction status',
            icon: Icons.flag_outlined,
            value: _status,
            items: ['Pending', 'Partial', 'Paid', 'Refunded', 'Closed']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _status = v ?? 'Pending'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _paymentDetails,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Payment details',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Update transaction' : 'Save transaction'),
          ),
        ],
      ),
    );
  }
}
