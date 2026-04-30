import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/screens/contracts/contract_form_screen.dart';
import 'package:estatetrack1/screens/contracts/apartment_return_form_screen.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  late List<ContractModel> _contracts;
  late List<ApartmentReturnModel> _returns;
  late List<CustomerModel> _customers;
  late List<ApartmentModel> _apartments;
  late List<RentalBookingModel> _bookings;

  @override
  void initState() {
    super.initState();
    // Mock data - in real app, load from repository
    _customers = [
      const CustomerModel(
        customerId: 1,
        name: 'Sara Al-Masri',
        phone: '+962 79 000 1111',
        nationalNum: '9900123456',
        numberOfRentedApartments: 1,
      ),
      const CustomerModel(
        customerId: 2,
        name: 'Omar Haddad',
        phone: '+962 78 222 3333',
        nationalNum: '8800654321',
        numberOfRentedApartments: 1,
      ),
    ];
    _apartments = [
      const ApartmentModel(
        apartmentId: 1,
        buildingId: 1,
        typeId: 1,
        sizeM2: 80,
        rentPricePerMonth: 450,
        rentPricePerDay: 15,
        isAvailable: false,
        bedrooms: 2,
        bathrooms: 2,
        hasBalcony: true,
        furnished: true,
        hasInternet: true,
        parking: true,
        elevator: true,
        number: 'A-101',
        location: 'Tower A, Floor 1',
      ),
    ];
    _bookings = [
      RentalBookingModel(
        bookingId: 1,
        userId: 1,
        customerId: 1,
        apartmentId: 1,
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2025, 5, 31),
        initialTotalDueAmount: 5400,
        bookingType: 0,
        periodFee: 450,
      ),
    ];
    _contracts = [
      ContractModel(
        contractId: 1,
        customerId: 1,
        apartmentId: 1,
        startDate: DateTime(2024, 6, 1),
        endDate: DateTime(2025, 5, 31),
        totalAmount: 5400,
        status: 'Active',
        bookingId: 1,
        notes: 'Yearly contract',
      ),
    ];
    _returns = [
      ApartmentReturnModel(
        returnId: 1,
        actualReturnDate: DateTime(2025, 5, 31),
        actualRentalDays: 365,
        additionalCharges: 0,
        actualTotalDueAmount: 5400,
        finalCheckNotes: 'Apartment in good condition',
      ),
    ];
  }

  int _nextId() {
    if (_contracts.isEmpty) return 1;
    return _contracts.map((e) => e.contractId).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _nextReturnId() {
    if (_returns.isEmpty) return 1;
    return _returns.map((e) => e.returnId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _openForm({ContractModel? existing}) async {
    final result = await Navigator.of(context).push<ContractModel>(
      MaterialPageRoute(
        builder: (context) => ContractFormScreen(
          existing: existing,
          customers: _customers,
          apartments: _apartments,
          bookings: _bookings,
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _contracts.indexWhere((a) => a.contractId == existing.contractId);
        if (i >= 0) {
          _contracts[i] = result.copyWith(contractId: existing.contractId);
        }
      } else {
        _contracts.add(result.copyWith(contractId: _nextId()));
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Contract updated' : 'Contract added',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ContractModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete contract?'),
        content: Text('Remove contract for customer ${_getCustomerName(c.customerId)}?'),
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

    setState(() {
      _contracts.removeWhere((e) => e.contractId == c.contractId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contract deleted')),
    );
  }

  Future<void> _openReturnForm({ApartmentReturnModel? existing}) async {
    final result = await Navigator.of(context).push<ApartmentReturnModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentReturnFormScreen(
          existing: existing,
          contracts: _contracts,
          customers: _customers,
          apartments: _apartments,
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _returns.indexWhere((r) => r.returnId == existing.returnId);
        if (i >= 0) {
          _returns[i] = result.copyWith(returnId: existing.returnId);
        }
      } else {
        _returns.add(result.copyWith(returnId: _nextReturnId()));
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Return updated' : 'Return added',
        ),
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

    setState(() {
      _returns.removeWhere((e) => e.returnId == r.returnId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return deleted')),
    );
  }

  String _getCustomerName(int customerId) {
    final customer = _customers.where((c) => c.customerId == customerId).firstOrNull;
    return customer?.name ?? 'Unknown';
  }

  String _getApartmentNumber(int apartmentId) {
    final apartment = _apartments.where((a) => a.apartmentId == apartmentId).firstOrNull;
    return apartment?.number ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_contracts.isEmpty && _returns.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_contracts',
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: scheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No contracts yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a contract.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_contracts',
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          title: const Text('Contracts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Contracts'),
              Tab(text: 'Returns'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Contracts Tab
            _buildContractsTab(scheme),
            // Returns Tab
            _buildReturnsTab(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsTab(ColorScheme scheme) {
    if (_contracts.isEmpty) {
      return Center(
        child: Text(
          'No contracts',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _contracts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = _contracts[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                '${_getCustomerName(c.customerId)} - ${_getApartmentNumber(c.apartmentId)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.startDate.toString().split(' ')[0]} - ${c.endDate.toString().split(' ')[0]}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r'$' '${c.totalAmount.toStringAsFixed(0)} total',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Status: ${c.status}',
                      style: TextStyle(
                        color: c.status == 'Active' ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
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
    if (_returns.isEmpty) {
      return Center(
        child: Text(
          'No returns',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _returns.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _returns[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                'Return #${r.returnId}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      r'$' '${r.actualTotalDueAmount.toStringAsFixed(0)} due',
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
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
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
