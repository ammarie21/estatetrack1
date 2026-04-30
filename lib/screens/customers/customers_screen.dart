import 'package:flutter/material.dart';

import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/screens/customers/customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late List<CustomerModel> _customers;

  @override
  void initState() {
    super.initState();
    _customers = [
      const CustomerModel(
        customerId: 1,
        name: 'Sara Al-Masri',
        phone: '+962 79 000 1111',
        nationalNum: '9900123456',
        numberOfRentedApartments: 1,
        idNumber: '9900123456',
        apartment: 'A-101',
        startDate: '2024-06-01',
        endDate: '2025-05-31',
      ),
      const CustomerModel(
        customerId: 2,
        name: 'Omar Haddad',
        phone: '+962 78 222 3333',
        nationalNum: '8800654321',
        numberOfRentedApartments: 1,
        idNumber: '8800654321',
        apartment: 'B-204',
        startDate: '2024-01-15',
        endDate: '2025-01-14',
      ),
      const CustomerModel(
        customerId: 3,
        name: 'Layla Nasser',
        phone: '+962 77 444 5555',
        nationalNum: '7700112233',
        numberOfRentedApartments: 1,
        idNumber: '7700112233',
        apartment: 'C-310',
        startDate: '2023-09-01',
        endDate: '2024-08-31',
      ),
    ];
  }

  int _nextId() {
    if (_customers.isEmpty) return 1;
    return _customers.map((e) => e.customerId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _openForm({CustomerModel? existing}) async {
    final result = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _customers.indexWhere((c) => c.customerId == existing.customerId);
        if (i >= 0) {
          _customers[i] = result.copyWith(customerId: existing.customerId);
        }
      } else {
        _customers.add(result.copyWith(customerId: _nextId()));
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(existing != null ? 'Customer updated' : 'Customer added'),
      ),
    );
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Remove ${c.name} from the list?'),
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
      _customers.removeWhere((e) => e.customerId == c.customerId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_customers.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_customers',
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: scheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No customers yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add your first customer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_customers',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _customers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final c = _customers[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  c.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.phone),
                      const SizedBox(height: 2),
                      Text('Apartment: ${c.apartment ?? ''}'),
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => _openForm(existing: c),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(c),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
