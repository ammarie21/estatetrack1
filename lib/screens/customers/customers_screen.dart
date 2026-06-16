import 'package:flutter/material.dart';
import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/screens/customers/customer_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({
    super.key,
    required this.customers,
    required this.onCustomersChanged,
    this.onRefresh,
  });

  final List<CustomerModel> customers;
  final void Function(List<CustomerModel>) onCustomersChanged;
  final Future<void> Function()? onRefresh;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late List<CustomerModel> _customers;
  bool _isSaving = false;
  String _query = '';

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

  List<CustomerModel> get _filteredCustomers {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q) ||
          c.nationalNum.toLowerCase().contains(q);
    }).toList();
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
              result.copyWith(customerId: 0, numberOfRentedApartments: 0),
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
      AppSnackbars.success(
        context,
        existing != null ? 'Customer updated' : 'Customer added',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Save failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete customer?',
      message: 'Remove ${c.name} from the backend?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await EstateApi.instance.deleteCustomer(c.customerId);
      setState(
        () => _customers.removeWhere((e) => e.customerId == c.customerId),
      );
      _notify();

      if (!mounted) return;
      AppSnackbars.success(context, 'Customer deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.statusCode == 400
          ? 'Cannot delete customer while rental bookings still reference them.'
          : 'Delete failed: ${e.message}';
      AppSnackbars.error(context, message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildBody(ColorScheme scheme) {
    final filtered = _filteredCustomers;

    if (_customers.isEmpty) {
      return AppEmptyState(
        icon: Icons.people_outline,
        title: 'No customers yet',
        message: 'Customer records are saved to the backend.',
        actionLabel: 'Add customer',
        onAction: _isSaving ? null : () => _openForm(),
      );
    }

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try a different name, phone, or national ID.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, kAppListBottomInset),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = filtered[index];
        final hasBooking = c.apartment?.isNotEmpty ?? false;
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (hasBooking)
                    const AppStatusChip(
                      label: 'Has booking',
                      tone: AppChipTone.positive,
                    ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.phone),
                    if (hasBooking) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Apartment: ${c.apartment}',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (c.nationalNum.isNotEmpty)
                      Text('National #: ${c.nationalNum}'),
                  ],
                ),
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Edit customer',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _isSaving ? null : () => _openForm(existing: c),
                  ),
                  IconButton(
                    tooltip: 'Delete customer',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: _isSaving ? null : () => _confirmDelete(c),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppFlowBanner(
          icon: Icons.cloud_outlined,
          text:
              'Customer records are backend-backed. Apartment and rental dates shown on cards are derived from bookings.',
        ),
        if (_customers.isNotEmpty)
          AppSearchField(
            hint: 'Search customers',
            onChanged: (value) => setState(() => _query = value),
          ),
        Expanded(child: _buildBody(Theme.of(context).colorScheme)),
      ],
    );

    final stack = Stack(
      children: [
        widget.onRefresh == null
            ? content
            : RefreshIndicator(
                onRefresh: widget.onRefresh!,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: content,
                      ),
                    );
                  },
                ),
              ),
        if (_isSaving)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_customers',
        onPressed: _isSaving ? null : () => _openForm(),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add customer'),
      ),
      body: stack,
    );
  }
}
