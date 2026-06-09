import 'package:flutter/material.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/screens/customers/customer_form_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({
    super.key,
    required this.customers,
    required this.onCustomersChanged,
  });

  final List<CustomerModel> customers;
  final void Function(List<CustomerModel>) onCustomersChanged;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late List<CustomerModel> _customers;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customers = List.from(widget.customers);
  }

  @override
  void didUpdateWidget(covariant CustomersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _customers = List.from(widget.customers);
  }

  int _nextId() {
    if (_customers.isEmpty) return 1;
    return _customers.map((e) => e.customerId).reduce((a, b) => a > b ? a : b) +
        1;
  }

  void _notify() => widget.onCustomersChanged(_customers);

  Future<void> _openForm({CustomerModel? existing}) async {
    final result = await Navigator.of(context).push<CustomerModel>(
      MaterialPageRoute(
        builder: (context) => CustomerFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() => _isSaving = true);
    try {
      final saved = existing != null
          ? await EstateApi.instance.updateCustomer(
              result.copyWith(customerId: existing.customerId),
            )
          : await EstateApi.instance.createCustomer(
              result.copyWith(customerId: _nextId()),
            );

      setState(() {
        if (existing != null) {
          final i = _customers.indexWhere(
            (c) => c.customerId == existing.customerId,
          );
          if (i >= 0) _customers[i] = saved;
        } else {
          _customers.add(saved);
        }
      });
      _notify();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existing != null ? 'Customer updated' : 'Customer added',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

    setState(() => _isSaving = true);
    try {
      await EstateApi.instance.deleteCustomer(c.customerId);
      setState(
        () => _customers.removeWhere((e) => e.customerId == c.customerId),
      );
      _notify();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Customer deleted')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_customers',
        onPressed: _isSaving ? null : () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Stack(
        children: [
          _customers.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: scheme.outline,
                        ),
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _customers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = _customers[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
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
                                Text('National #: ${c.nationalNum}'),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: _isSaving
                                    ? null
                                    : () => _openForm(existing: c),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline,
                                  color: scheme.error,
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => _confirmDelete(c),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
}
