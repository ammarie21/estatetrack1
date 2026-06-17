import 'package:flutter/material.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/data/staff_user_registry.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/payments/rental_transaction_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';
import 'package:estatetrack1/utils/deferred_delete.dart';
import 'package:estatetrack1/utils/payment_details_parser.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.rentalTransactions,
    required this.staffUserId,
    required this.bookings,
    required this.returns,
    required this.customers,
    required this.buildings,
    required this.apartments,
    required this.onRentalTransactionsChanged,
    required this.onBookingsChanged,
    this.onRefresh,
    this.initialTxnFilter,
    this.initialSearchQuery,
  });

  final List<RentalTransactionModel> rentalTransactions;
  final int staffUserId;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final void Function(List<RentalTransactionModel>) onRentalTransactionsChanged;
  final void Function(List<RentalBookingModel>) onBookingsChanged;
  final Future<void> Function()? onRefresh;
  final String? initialTxnFilter;
  final String? initialSearchQuery;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late List<RentalTransactionModel> _transactions;
  late String _txnFilter;
  late String _query;
  late final TextEditingController _searchController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _txnFilter = widget.initialTxnFilter ?? 'All';
    _query = widget.initialSearchQuery ?? '';
    _searchController = TextEditingController(text: _query);
    _transactions = List.from(widget.rentalTransactions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PaymentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rentalTransactions != widget.rentalTransactions) {
      _transactions = List.from(widget.rentalTransactions);
    }
  }

  Future<void> _openTransactionForm({RentalTransactionModel? existing}) async {
    final result = await Navigator.of(context).push<RentalTransactionModel>(
      MaterialPageRoute(
        builder: (context) => RentalTransactionFormScreen(
          existing: existing,
          bookings: widget.bookings,
          returns: widget.returns,
          customers: widget.customers,
          buildings: widget.buildings,
          apartments: widget.apartments,
        ),
      ),
    );
    if (!mounted || result == null) return;

    final booking = widget.bookings
        .where((b) => b.bookingId == result.bookingId)
        .firstOrNull;
    if (booking == null) return;

    setState(() => _isSaving = true);
    try {
      final saved = await EstateApi.instance.saveBookingPayment(
        booking: booking,
        paidAmount: result.paidInitialTotalDueAmount,
        paymentDetails: result.paymentDetails,
      );

      final nextBookings = List<RentalBookingModel>.from(widget.bookings);
      final bookingIndex = nextBookings.indexWhere(
        (b) => b.bookingId == saved.bookingId,
      );
      if (bookingIndex >= 0) {
        nextBookings[bookingIndex] = saved;
      }
      final nextTransactions = buildTransactionsFromBookings(
        nextBookings,
        widget.returns,
      );
      setState(() => _transactions = nextTransactions);
      widget.onBookingsChanged(nextBookings);
      widget.onRentalTransactionsChanged(nextTransactions);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Payment save failed: ${e.message}');
      return;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }

    if (!mounted) return;
    AppSnackbars.success(context, 'Payment received');
  }

  Future<void> _confirmDeleteTransaction(RentalTransactionModel t) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Clear payment?',
      message:
          'This clears the paid amount on the linked booking. The rental agreement itself is not deleted.',
      confirmLabel: 'Clear payment',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final booking = widget.bookings
        .where((b) => b.bookingId == t.bookingId)
        .firstOrNull;
    if (booking == null) return;

    final backupBookings = List<RentalBookingModel>.from(widget.bookings);
    final backupTransactions = List<RentalTransactionModel>.from(_transactions);

    setState(() => _isSaving = true);
    try {
      await deferredDelete(
        context: context,
        message: 'Payment cleared for booking #${t.bookingId}',
        onRemove: () {
          final cleared = booking.copyWith(rentalPrice: 0, paymentDetails: '');
          final nextBookings = List<RentalBookingModel>.from(widget.bookings);
          final i = nextBookings.indexWhere((b) => b.bookingId == cleared.bookingId);
          if (i >= 0) nextBookings[i] = cleared;
          final nextTransactions = buildTransactionsFromBookings(
            nextBookings,
            widget.returns,
          );
          setState(() => _transactions = nextTransactions);
          widget.onBookingsChanged(nextBookings);
          widget.onRentalTransactionsChanged(nextTransactions);
        },
        onRestore: () {
          setState(() => _transactions = backupTransactions);
          widget.onBookingsChanged(backupBookings);
          widget.onRentalTransactionsChanged(backupTransactions);
        },
        commit: () => EstateApi.instance.saveBookingPayment(
          booking: booking,
          paidAmount: 0,
          paymentDetails: '',
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Transaction delete failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _bookingSubtitle(RentalTransactionModel t) {
    RentalBookingModel? b;
    for (final x in widget.bookings) {
      if (x.bookingId == t.bookingId) {
        b = x;
        break;
      }
    }
    if (b == null) return 'Booking ${t.bookingId}';
    String? cust;
    for (final c in widget.customers) {
      if (c.customerId == b.customerId) {
        cust = c.name;
        break;
      }
    }
    final apt = apartmentDisplayLabelById(
      b.apartmentId,
      widget.apartments,
      widget.buildings,
    );
    return '${cust ?? 'Customer'} · $apt';
  }

  List<RentalTransactionModel> get _filteredTransactions {
    return _transactions.where((t) {
      if (_txnFilter != 'All' && t.transactionStatus != _txnFilter) {
        return false;
      }
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.bookingId.toString().contains(q) ||
          _bookingSubtitle(t).toLowerCase().contains(q);
    }).toList();
  }

  Widget _wrapRefresh(Widget child) {
    if (widget.onRefresh == null) return child;
    return RefreshIndicator(
      onRefresh: widget.onRefresh!,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(height: constraints.maxHeight, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_payments',
        onPressed: _isSaving ? null : () => _openTransactionForm(),
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Receive payment'),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppFlowBanner(
                icon: Icons.sync_alt_rounded,
                text:
                    'Payments are saved on the linked Rental Booking (rentalPrice and paymentDetails). Maintenance costs are tracked from Buildings.',
              ),
              Expanded(child: _wrapRefresh(_transactionsList(scheme))),
            ],
          ),
          if (_isSaving)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _transactionsList(ColorScheme scheme) {
    if (_transactions.isEmpty) {
      return AppEmptyState(
        icon: Icons.payments_outlined,
        title: 'No rental transactions',
        message:
            'Payments are saved on rental bookings. Record a payment after creating an agreement.',
        actionLabel: 'Receive payment',
        onAction: _openTransactionForm,
      );
    }

    final filtered = _filteredTransactions;
    return Column(
      children: [
        AppSearchField(
          hint: 'Search transactions',
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        AppFilterChips(
          options: const ['All', 'Pending', 'Partial', 'Paid', 'Refunded', 'Closed'],
          selected: _txnFilter,
          onSelected: (value) => setState(() => _txnFilter = value),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Try another payment status or search term.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    kAppListBottomInset,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final t = filtered[index];
                    final booking = widget.bookings
                        .where((b) => b.bookingId == t.bookingId)
                        .firstOrNull;
                    final paymentNotes = summarizePaymentDetails(
                      t.paymentDetails,
                    );
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Booking #${t.bookingId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            AppStatusChip(
                              label: t.transactionStatus,
                              tone: chipToneForBookingStatus(
                                t.transactionStatus,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_bookingSubtitle(t)),
                              const SizedBox(height: 4),
                              Text(
                                'Paid \$${t.paidInitialTotalDueAmount.toStringAsFixed(2)} · '
                                'Due \$${t.actualTotalDueAmount.toStringAsFixed(2)} · '
                                '${t.totalRefundedAmount > 0 ? 'Refund \$${t.totalRefundedAmount.toStringAsFixed(2)}' : 'Remaining \$${t.totalRemaining.toStringAsFixed(2)}'}',
                                style: TextStyle(
                                  color: scheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                              if (booking != null && booking.periodFee > 0)
                                Text(
                                  'Period fee \$${booking.periodFee.toStringAsFixed(2)} · '
                                  'Staff: ${staffUserName(booking.userId)}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              if (paymentNotes.isNotEmpty)
                                Text(
                                  paymentNotes,
                                  style: TextStyle(
                                    color: scheme.outline,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                '${t.updatedTransactionDate.toString().split(' ')[0]}'
                                '${t.returnId != null ? ' · Linked return #${t.returnId}' : ' · No return linked'}',
                                style: TextStyle(
                                  color: scheme.outline,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_card_outlined),
                              tooltip: 'Receive another payment',
                              onPressed: () =>
                                  _openTransactionForm(existing: t),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: scheme.error,
                              ),
                              onPressed: () => _confirmDeleteTransaction(t),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
