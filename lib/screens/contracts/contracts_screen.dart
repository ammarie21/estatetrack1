import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/screens/contracts/apartment_return_form_screen.dart';
import 'package:estatetrack1/screens/contracts/contract_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/deferred_delete.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({
    super.key,
    required this.staffUserId,
    required this.customers,
    required this.buildings,
    required this.apartments,
    required this.bookings,
    required this.contracts,
    required this.returns,
    required this.onBookingsChanged,
    required this.onContractsChanged,
    required this.onReturnsChanged,
    required this.onApartmentsChanged,
    this.onRefresh,
    this.initialStatusFilter,
    this.initialSearchQuery,
  });

  final int staffUserId;
  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final void Function(List<RentalBookingModel>) onBookingsChanged;
  final void Function(List<ContractModel>) onContractsChanged;
  final void Function(List<ApartmentReturnModel>) onReturnsChanged;
  final void Function(List<ApartmentModel>) onApartmentsChanged;
  final Future<void> Function()? onRefresh;
  final String? initialStatusFilter;
  final String? initialSearchQuery;

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late EstateIndexes _indexes;
  late String _statusFilter;
  late String _query;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _statusFilter = widget.initialStatusFilter ?? 'All';
    _query = widget.initialSearchQuery ?? '';
    _searchController = TextEditingController(text: _query);
    _tabController = TabController(length: 2, vsync: this);
    _indexes = _buildIndexes();
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  EstateIndexes _buildIndexes() => EstateIndexes.fromLists(
    customers: widget.customers,
    buildings: widget.buildings,
    apartments: widget.apartments,
    bookings: widget.bookings,
    returns: widget.returns,
  );

  @override
  void didUpdateWidget(covariant ContractsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customers != widget.customers ||
        oldWidget.buildings != widget.buildings ||
        oldWidget.apartments != widget.apartments ||
        oldWidget.bookings != widget.bookings ||
        oldWidget.returns != widget.returns) {
      _indexes = _buildIndexes();
    }
  }

  int _estimatedMonths(DateTime start, DateTime end) {
    final days = end.difference(start).inDays;
    if (days <= 0) return 1;
    return math.max(1, (days / 30).ceil());
  }

  Future<void> _setApartmentAvailable(int apartmentId, bool available) async {
    final apartment = widget.apartments
        .where((a) => a.apartmentId == apartmentId)
        .firstOrNull;
    if (apartment == null) return;

    try {
      final saved = await EstateApi.instance.updateApartment(
        apartment.copyWith(isAvailable: available),
      );
      final next = widget.apartments.map((a) {
        if (a.apartmentId == apartmentId) {
          return saved.copyWith(number: a.number, location: a.location);
        }
        return a;
      }).toList();
      widget.onApartmentsChanged(next);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Apartment update failed: ${e.message}');
    }
  }

  RentalBookingModel _createBookingFromContract(
    ContractModel c,
    int bookingId, {
    RentalBookingModel? existingBooking,
  }) {
    final months = _estimatedMonths(c.startDate, c.endDate);
    final periodFee = c.totalAmount / months;
    final initialPayment = c.initialPayment > 0
        ? c.initialPayment
        : (existingBooking?.rentalPrice ?? 0);
    final paymentDetails = initialPayment > 0
        ? 'Initial payment: \$${initialPayment.toStringAsFixed(2)}'
        : existingBooking?.paymentDetails;
    return RentalBookingModel(
      bookingId: bookingId,
      userId: widget.staffUserId,
      customerId: c.customerId,
      apartmentId: c.apartmentId,
      startDate: c.startDate,
      endDate: c.endDate,
      initialTotalDueAmount: c.totalAmount,
      bookingType: c.bookingType,
      periodFee: periodFee,
      rentalPrice: initialPayment,
      paymentDetails: paymentDetails,
      isActive: existingBooking?.isActive ?? true,
      initialCheckNotes: c.notes,
    );
  }

  ContractModel _contractFromBooking(
    RentalBookingModel b, {
    String? statusOverride,
  }) {
    final base = contractFromBooking(b, returns: widget.returns);
    if (statusOverride == null) return base;
    return base.copyWith(status: statusOverride);
  }

  double _paidForBooking(int? bookingId) => _indexes.paidForBooking(bookingId);

  Future<void> _applyContract(
    ContractModel raw,
    ContractModel? existing,
  ) async {
    var bookings = List<RentalBookingModel>.from(widget.bookings);
    final isNew = existing == null && raw.bookingId == 0;
    final bookingId = isNew ? 0 : (existing?.bookingId ?? raw.bookingId);
    final existingBooking = isNew
        ? null
        : widget.bookings.where((b) => b.bookingId == bookingId).firstOrNull;
    final bookingToSave = _createBookingFromContract(
      raw,
      bookingId,
      existingBooking: existingBooking,
    );

    final savedBooking = isNew
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
    final contract = _contractFromBooking(
      savedBooking,
    ).copyWith(status: raw.status);
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
      await _setApartmentAvailable(contract.apartmentId, false);
    }
  }

  Future<void> _applyReturn(
    ApartmentReturnModel raw,
    ApartmentReturnModel? existing,
  ) async {
    var paid = _paidForBooking(raw.bookingId);
    var bookings = List<RentalBookingModel>.from(widget.bookings);
    if (raw.finalPaymentCollected > 0 && raw.bookingId != null) {
      final booking = bookings
          .where((item) => item.bookingId == raw.bookingId)
          .firstOrNull;
      if (booking != null) {
        final updatedPaid = paid + raw.finalPaymentCollected;
        final existingDetails = (booking.paymentDetails ?? '').trim();
        final note = raw.finalCheckNotes?.trim() ?? '';
        final paymentLine =
            '${raw.actualReturnDate.toIso8601String().split('T').first}: '
            'checkout payment \$${raw.finalPaymentCollected.toStringAsFixed(2)}'
            '${note.isEmpty ? '' : ' - $note'}';
        final savedBooking = await EstateApi.instance.saveBookingPayment(
          booking: booking,
          paidAmount: updatedPaid,
          paymentDetails: existingDetails.isEmpty
              ? paymentLine
              : '$existingDetails\n$paymentLine',
        );
        final bookingIndex = bookings.indexWhere(
          (item) => item.bookingId == savedBooking.bookingId,
        );
        if (bookingIndex >= 0) {
          bookings[bookingIndex] = savedBooking;
          widget.onBookingsChanged(bookings);
          paid = updatedPaid;
        }
      }
    }

    final saved = existing == null
        ? await EstateApi.instance.createReturn(
            raw,
            userId: widget.staffUserId,
            paidOnBooking: paid,
          )
        : await EstateApi.instance.updateReturn(
            raw.copyWith(returnId: existing.returnId),
            userId: widget.staffUserId,
            paidOnBooking: paid,
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
        await _setApartmentAvailable(b.apartmentId, true);
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
          buildings: widget.buildings,
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
      AppSnackbars.error(context, 'Agreement save failed: ${e.message}');
      return;
    }

    if (!mounted) return;
    AppSnackbars.success(
      context,
      existing != null ? 'Agreement updated' : 'Agreement created',
    );
  }

  ApartmentModel? _apartmentForContract(ContractModel contract) {
    return widget.apartments
        .where((apartment) => apartment.apartmentId == contract.apartmentId)
        .firstOrNull;
  }

  Future<void> _extendAgreement(ContractModel contract) async {
    if (contract.status == 'Terminated') {
      AppSnackbars.error(
        context,
        'This agreement is already checked out. Create a new agreement instead.',
      );
      return;
    }

    final apartment = _apartmentForContract(contract);
    final amountController = TextEditingController();
    final daysController = TextEditingController(text: '7');
    var extensionDays = 7;

    double suggestedAmount(int days) {
      if (apartment == null) return 0;
      if (days == 30 && apartment.rentPricePerMonth > 0) {
        return apartment.rentPricePerMonth;
      }
      return apartment.rentPricePerDay * days;
    }

    amountController.text = suggestedAmount(extensionDays).toStringAsFixed(2);

    final result = await showDialog<({int days, double amount})>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void setDays(int days) {
              setDialogState(() {
                extensionDays = days;
                daysController.text = days.toString();
                amountController.text = suggestedAmount(
                  days,
                ).toStringAsFixed(2);
              });
            }

            return AlertDialog(
              title: const Text('Extend agreement'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Current end: ${contract.endDate.toIso8601String().split('T').first}',
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('+7 days')),
                      ButtonSegment(value: 30, label: Text('+1 month')),
                      ButtonSegment(value: 0, label: Text('Custom')),
                    ],
                    selected: {
                      extensionDays == 7 || extensionDays == 30
                          ? extensionDays
                          : 0,
                    },
                    onSelectionChanged: (values) {
                      final value = values.first;
                      if (value == 0) {
                        setDays(1);
                      } else {
                        setDays(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Extra days',
                      prefixIcon: Icon(Icons.date_range_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final days = int.tryParse(value) ?? 0;
                      setDialogState(() {
                        extensionDays = days;
                        amountController.text = suggestedAmount(
                          days,
                        ).toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Added amount due',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      helperText:
                          'Calculated from the apartment rent, editable',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(
                          amountController.text.replaceAll(',', ''),
                        ) ??
                        0;
                    if (extensionDays <= 0 || amount < 0) return;
                    Navigator.of(
                      dialogContext,
                    ).pop((days: extensionDays, amount: amount));
                  },
                  child: const Text('Extend'),
                ),
              ],
            );
          },
        );
      },
    );
    amountController.dispose();
    daysController.dispose();

    if (result == null || !mounted) return;

    final extended = contract.copyWith(
      endDate: contract.endDate.add(Duration(days: result.days)),
      totalAmount: contract.totalAmount + result.amount,
      status: 'Active',
      notes: [
        if ((contract.notes ?? '').trim().isNotEmpty) contract.notes!.trim(),
        'Extended ${result.days} day(s), added \$${result.amount.toStringAsFixed(2)}',
      ].join('\n'),
    );

    try {
      await _applyContract(extended, contract);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Extension failed: ${e.message}');
      return;
    }

    if (!mounted) return;
    AppSnackbars.success(context, 'Agreement extended');
  }

  Future<void> _confirmDelete(ContractModel c) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete agreement?',
      message:
          'Remove contract for customer ${_getCustomerName(c.customerId)}?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final backupContracts = List<ContractModel>.from(widget.contracts);
    final backupBookings = List<RentalBookingModel>.from(widget.bookings);

    try {
      await deferredDelete(
        context: context,
        message: 'Agreement removed',
        onRemove: () {
          widget.onContractsChanged(
            widget.contracts
                .where((e) => e.contractId != c.contractId)
                .toList(),
          );
          widget.onBookingsChanged(
            widget.bookings.where((e) => e.bookingId != c.bookingId).toList(),
          );
        },
        onRestore: () {
          widget.onContractsChanged(backupContracts);
          widget.onBookingsChanged(backupBookings);
        },
        commit: () => EstateApi.instance.deleteBooking(c.bookingId),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Agreement delete failed: ${e.message}');
    }
  }

  Future<void> _openReturnForm({ApartmentReturnModel? existing}) async {
    final result = await Navigator.of(context).push<ApartmentReturnModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentReturnFormScreen(
          existing: existing,
          contracts: widget.contracts,
          bookings: widget.bookings,
          returns: widget.returns,
          customers: widget.customers,
          buildings: widget.buildings,
          apartments: widget.apartments,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      await _applyReturn(result, existing);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Return save failed: ${e.message}');
      return;
    }

    if (!mounted) return;
    AppSnackbars.success(
      context,
      existing != null ? 'Return updated' : 'Return recorded',
    );
  }

  Future<void> _confirmDeleteReturn(ApartmentReturnModel r) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete return?',
      message: 'Remove this apartment return record?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final backup = List<ApartmentReturnModel>.from(widget.returns);
    try {
      await deferredDelete(
        context: context,
        message: 'Return record removed',
        onRemove: () {
          widget.onReturnsChanged(
            widget.returns.where((e) => e.returnId != r.returnId).toList(),
          );
        },
        onRestore: () => widget.onReturnsChanged(backup),
        commit: () => EstateApi.instance.deleteReturn(r.returnId),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Return delete failed: ${e.message}');
    }
  }

  String _getCustomerName(int customerId) => _indexes.customerName(customerId);

  String _getApartmentNumber(int apartmentId) =>
      _indexes.apartmentNumber(apartmentId);

  String _returnSubtitle(ApartmentReturnModel r) {
    if (r.bookingId == null) return 'Booking not linked';
    return 'Booking ${r.bookingId}';
  }

  String _flowBannerText() => _tabController.index == 1
      ? 'Apartment Return finalizes checkout. Remaining/refund amounts are sent '
            'using booking payments (rentalPrice) and checkout totals.'
      : 'Agreements mirror Rental Booking rows. Status is derived from returns and lease dates.';

  List<ContractModel> get _filteredContracts {
    return widget.contracts.where((c) {
      if (_statusFilter != 'All' && c.status != _statusFilter) return false;
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      final customer = _getCustomerName(c.customerId).toLowerCase();
      final apt = _getApartmentNumber(c.apartmentId).toLowerCase();
      return customer.contains(q) ||
          apt.contains(q) ||
          c.bookingId.toString().contains(q);
    }).toList();
  }

  double _paidForContract(ContractModel c) => _paidForBooking(c.bookingId);

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
              children: [
                _wrapRefresh(_buildContractsTab(scheme)),
                _wrapRefresh(_buildReturnsTab(scheme)),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildContractsTab(ColorScheme scheme) {
    if (widget.contracts.isEmpty) {
      return AppEmptyState(
        icon: Icons.article_outlined,
        title: 'No lease agreements yet',
        message:
            'Tap “New agreement” to create a Rental Booking line with dates and totals.',
        actionLabel: 'New agreement',
        onAction: _openForm,
      );
    }

    final filtered = _filteredContracts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSearchField(
          hint: 'Search agreements',
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
        ),
        AppFilterChips(
          options: const ['All', 'Active', 'Expired', 'Terminated'],
          selected: _statusFilter,
          onSelected: (value) => setState(() => _statusFilter = value),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Try another status filter or search term.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    0,
                    16,
                    kAppListBottomInset,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final paid = _paidForContract(c);
                    final progress = c.totalAmount <= 0
                        ? 0.0
                        : (paid / c.totalAmount).clamp(0.0, 1.0);
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                                  'Rental booking #${c.bookingId} · ${c.bookingType == 1 ? 'Daily' : 'Monthly'}',
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
                                const SizedBox(height: 6),
                                LinearProgressIndicator(
                                  value: progress,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                Text(
                                  'Paid \$${paid.toStringAsFixed(0)} of \$${c.totalAmount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'extend',
                                child: Text('Extend agreement'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _openForm(existing: c);
                                  break;
                                case 'extend':
                                  _extendAgreement(c);
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
                ),
        ),
      ],
    );
  }

  Widget _buildReturnsTab(ColorScheme scheme) {
    if (widget.returns.isEmpty) {
      return AppEmptyState(
        icon: Icons.key_off_outlined,
        title: 'No apartment returns yet',
        message:
            'When a tenant checks out, record an Apartment Return linked to their booking. '
            'Settlement amounts are calculated from booking payments and checkout totals.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, kAppListBottomInset),
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
                        'Additional charges: \$${r.additionalCharges.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    if (r.totalRemaining > 0)
                      Text(
                        'Remaining: \$${r.totalRemaining.toStringAsFixed(2)}',
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    if (r.totalRefundedAmount > 0)
                      Text(
                        'Refund: \$${r.totalRefundedAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    if (r.finalCheckNotes?.trim().isNotEmpty == true)
                      Text(
                        r.finalCheckNotes!.trim(),
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
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
