import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/screens/contracts/apartment_return_form_screen.dart';
import 'package:estatetrack1/screens/contracts/contract_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({
    super.key,
    required this.staffUserId,
    required this.customers,
    required this.apartments,
    required this.bookings,
    required this.contracts,
    required this.returns,
    required this.onBookingsChanged,
    required this.onContractsChanged,
    required this.onReturnsChanged,
    required this.onApartmentsChanged,
  });

  final int staffUserId;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final void Function(List<RentalBookingModel>) onBookingsChanged;
  final void Function(List<ContractModel>) onContractsChanged;
  final void Function(List<ApartmentReturnModel>) onReturnsChanged;
  final void Function(List<ApartmentModel>) onApartmentsChanged;

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _nextBookingId() {
    if (widget.bookings.isEmpty) return 1;
    return widget.bookings
            .map((e) => e.bookingId)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  int _estimatedMonths(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days <= 0) return 1;
    return math.max(1, (days / 30).ceil());
  }

  void _setApartmentAvailable(int apartmentId, bool available) {
    final next = widget.apartments.map((a) {
      if (a.apartmentId == apartmentId) {
        return a.copyWith(isAvailable: available);
      }
      return a;
    }).toList();
    widget.onApartmentsChanged(next);
  }

  RentalBookingModel _createBookingFromContract(
    ContractModel c,
    int bookingId,
  ) {
    final months = _estimatedMonths(c.startDate, c.endDate);
    final periodFee = c.totalAmount / months;
    return RentalBookingModel(
      bookingId: bookingId,
      userId: widget.staffUserId,
      customerId: c.customerId,
      apartmentId: c.apartmentId,
      startDate: c.startDate,
      endDate: c.endDate,
      initialTotalDueAmount: c.totalAmount,
      bookingType: 0,
      periodFee: periodFee,
      initialCheckNotes: c.notes,
    );
  }

  ContractModel _contractFromBooking(
    RentalBookingModel b, {
    String status = 'Active',
  }) {
    return ContractModel(
      contractId: b.bookingId,
      customerId: b.customerId,
      apartmentId: b.apartmentId,
      startDate: b.startDate,
      endDate: b.endDate,
      totalAmount: b.initialTotalDueAmount,
      status: status,
      bookingId: b.bookingId,
      notes: b.initialCheckNotes,
    );
  }

  Future<void> _applyContract(
    ContractModel raw,
    ContractModel? existing,
  ) async {
    var bookings = List<RentalBookingModel>.from(widget.bookings);
    final bookingId = raw.bookingId == 0
        ? _nextBookingId()
        : (existing?.bookingId ?? raw.bookingId);
    final bookingToSave = _createBookingFromContract(raw, bookingId);

    final savedBooking = existing == null && raw.bookingId == 0
        ? await EstateApi.instance.createBooking(bookingToSave)
        : await EstateApi.instance.updateBooking(bookingToSave);

    final bookingIndex = bookings.indexWhere(
      (b) => b.bookingId == savedBooking.bookingId,
    );
    if (bookingIndex >= 0) {
      bookings[bookingIndex] = savedBooking;
    } else {
      bookings.add(savedBooking);
    }
    widget.onBookingsChanged(bookings);

    final contracts = List<ContractModel>.from(widget.contracts);
    final contract = _contractFromBooking(savedBooking, status: raw.status);
    if (existing != null) {
      final i = contracts.indexWhere(
        (x) => x.contractId == existing.contractId,
      );
      if (i >= 0) {
        contracts[i] = contract;
      }
    } else {
      final i = contracts.indexWhere(
        (x) => x.bookingId == savedBooking.bookingId,
      );
      if (i >= 0) {
        contracts[i] = contract;
      } else {
        contracts.add(contract);
      }
    }
    widget.onContractsChanged(contracts);

    if (contract.status == 'Active') {
      _setApartmentAvailable(contract.apartmentId, false);
    }
  }

  Future<void> _applyReturn(
    ApartmentReturnModel raw,
    ApartmentReturnModel? existing,
  ) async {
    final saved = existing == null
        ? await EstateApi.instance.createReturn(raw, userId: widget.staffUserId)
        : await EstateApi.instance.updateReturn(
            raw.copyWith(returnId: existing.returnId),
            userId: widget.staffUserId,
          );

    final returns = List<ApartmentReturnModel>.from(widget.returns);
    if (existing != null) {
      final i = returns.indexWhere((x) => x.returnId == existing.returnId);
      if (i >= 0) {
        returns[i] = saved.copyWith(actualRentalDays: raw.actualRentalDays);
      }
    } else {
      returns.add(saved.copyWith(actualRentalDays: raw.actualRentalDays));
    }
    widget.onReturnsChanged(returns);

    final bid = saved.bookingId;
    if (bid != null) {
      RentalBookingModel? b;
      for (final x in widget.bookings) {
        if (x.bookingId == bid) {
          b = x;
          break;
        }
      }
      if (b != null) {
        _setApartmentAvailable(b.apartmentId, true);
      }

      final contracts = List<ContractModel>.from(widget.contracts);
      var changed = false;
      for (var i = 0; i < contracts.length; i++) {
        if (contracts[i].bookingId == bid) {
          contracts[i] = contracts[i].copyWith(status: 'Terminated');
          changed = true;
        }
      }
      if (changed) widget.onContractsChanged(contracts);
    }
  }

  Future<void> _openForm({ContractModel? existing}) async {
    final result = await Navigator.of(context).push<ContractModel>(
      MaterialPageRoute(
        builder: (context) => ContractFormScreen(
          existing: existing,
          customers: widget.customers,
          apartments: widget.apartments,
          bookings: widget.bookings,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _applyContract(result, existing);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agreement save failed: ${e.message}')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Agreement updated' : 'Agreement created',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ContractModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete agreement?'),
        content: Text(
          'Remove contract for customer ${_getCustomerName(c.customerId)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await EstateApi.instance.deleteBooking(c.bookingId);
      final contracts = widget.contracts
          .where((e) => e.contractId != c.contractId)
          .toList();
      final bookings = widget.bookings
          .where((e) => e.bookingId != c.bookingId)
          .toList();
      widget.onContractsChanged(contracts);
      widget.onBookingsChanged(bookings);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agreement delete failed: ${e.message}')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Agreement removed')));
  }

  Future<void> _openReturnForm({ApartmentReturnModel? existing}) async {
    final result = await Navigator.of(context).push<ApartmentReturnModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentReturnFormScreen(
          existing: existing,
          contracts: widget.contracts,
          customers: widget.customers,
          apartments: widget.apartments,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _applyReturn(result, existing);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return save failed: ${e.message}')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing != null ? 'Return updated' : 'Return recorded'),
      ),
    );
  }

  Future<void> _confirmDeleteReturn(ApartmentReturnModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete return?'),
        content: const Text('Remove this apartment return record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await EstateApi.instance.deleteReturn(r.returnId);
      final returns = widget.returns
          .where((e) => e.returnId != r.returnId)
          .toList();
      widget.onReturnsChanged(returns);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return delete failed: ${e.message}')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Return deleted')));
  }

  String _getCustomerName(int customerId) {
    for (final c in widget.customers) {
      if (c.customerId == customerId) return c.name;
    }
    return 'Unknown';
  }

  String _getApartmentNumber(int apartmentId) {
    for (final a in widget.apartments) {
      if (a.apartmentId == apartmentId) {
        return a.number ?? '#${a.apartmentId}';
      }
    }
    return 'Unknown';
  }

  String _returnSubtitle(ApartmentReturnModel r) {
    if (r.bookingId == null) return 'Booking not linked';
    return 'Booking ${r.bookingId}';
  }

  String _flowBannerText() => _tabController.index == 1
      ? 'Apartment Return captures checkout: link to the booking’s agreement, then finalize amounts in Rental Transactions.'
      : 'Agreements mirror your Rental Booking + lease totals. Each row ties Customer → Apartment → Booking ID.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          final onReturns = _tabController.index == 1;
          return FloatingActionButton.extended(
            heroTag: 'fab_contracts',
            onPressed: () {
              if (onReturns) {
                _openReturnForm();
              } else {
                _openForm();
              }
            },
            icon: Icon(onReturns ? Icons.logout_rounded : Icons.add_rounded),
            label: Text(onReturns ? 'Record return' : 'New agreement'),
          );
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFlowBanner(icon: Icons.schema_outlined, text: _flowBannerText()),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Agreements'),
                Tab(text: 'Returns'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildContractsTab(scheme), _buildReturnsTab(scheme)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractsTab(ColorScheme scheme) {
    if (widget.contracts.isEmpty) {
      return AppEmptyState(
        icon: Icons.article_outlined,
        title: 'No lease agreements yet',
        message:
            'Tap “New agreement” to create a Rental Booking line (or link an existing one) with dates and totals.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: widget.contracts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = widget.contracts[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_getCustomerName(c.customerId)} · ${_getApartmentNumber(c.apartmentId)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  AppStatusChip(
                    label: c.status,
                    tone: chipToneForLeaseStatus(c.status),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.startDate.toString().split(' ')[0]} → ${c.endDate.toString().split(' ')[0]}',
                    ),
                    Text(
                      'Rental booking #${c.bookingId}',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r'$'
                      '${c.totalAmount.toStringAsFixed(0)} estimated total',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _openForm(existing: c);
                      break;
                    case 'delete':
                      _confirmDelete(c);
                      break;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReturnsTab(ColorScheme scheme) {
    if (widget.returns.isEmpty) {
      return AppEmptyState(
        icon: Icons.key_off_outlined,
        title: 'No apartment returns yet',
        message:
            'When a tenant checks out, record an Apartment Return linked to their booking. '
            'Outstanding balances are settled as Rental Transactions.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: widget.returns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = widget.returns[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Return #${r.returnId}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (r.bookingId != null)
                    AppStatusChip(
                      label: 'Booking #${r.bookingId}',
                      tone: AppChipTone.neutral,
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.bookingId == null) Text(_returnSubtitle(r)),
                    Text(
                      'Return Date: ${r.actualReturnDate.toString().split(' ')[0]}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rental Days: ${r.actualRentalDays}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      r'$'
                      '${r.actualTotalDueAmount.toStringAsFixed(0)} due',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (r.additionalCharges > 0)
                      Text(
                        'Additional Charges: \$${r.additionalCharges.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _openReturnForm(existing: r);
                      break;
                    case 'delete':
                      _confirmDeleteReturn(r);
                      break;
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
