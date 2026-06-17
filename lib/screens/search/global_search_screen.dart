import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({
    super.key,
    required this.indexes,
    required this.onOpenCustomer,
    required this.onOpenBooking,
    required this.onOpenApartment,
  });

  final EstateIndexes indexes;
  final void Function(CustomerModel customer) onOpenCustomer;
  final void Function(int bookingId) onOpenBooking;
  final void Function(int apartmentId) onOpenApartment;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  late final TextEditingController _controller;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final results = q.isEmpty ? const <_SearchHit>[] : _search(q);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Search customers, apartments, bookings…',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: q.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_rounded,
                  title: 'Search everything',
                  message:
                      'Find customers by name or phone, apartments by number, or bookings by ID.',
                )
              : results.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches',
                  message: 'Try another name, unit number, or booking ID.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    kAppListBottomInset,
                  ),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final hit = results[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(hit.icon, color: hit.color),
                        title: Text(
                          hit.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(hit.subtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: hit.onTap,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<_SearchHit> _search(String q) {
    final hits = <_SearchHit>[];
    final scheme = Theme.of(context).colorScheme;

    for (final customer in widget.indexes.allCustomers) {
      if (!_matchesCustomer(customer, q)) continue;
      hits.add(
        _SearchHit(
          title: customer.name,
          subtitle: 'Customer · ${customer.phone}',
          icon: Icons.person_outline,
          color: scheme.primary,
          onTap: () => widget.onOpenCustomer(customer),
        ),
      );
    }

    for (final apt in widget.indexes.allApartments) {
      final label = widget.indexes.apartmentLabel(apt.apartmentId);
      if (!label.toLowerCase().contains(q) &&
          !apt.apartmentId.toString().contains(q)) {
        continue;
      }
      hits.add(
        _SearchHit(
          title: label,
          subtitle: apt.isAvailable ? 'Vacant unit' : 'Occupied unit',
          icon: Icons.apartment_outlined,
          color: scheme.tertiary,
          onTap: () => widget.onOpenApartment(apt.apartmentId),
        ),
      );
    }

    for (final booking in widget.indexes.allBookings) {
      if (!booking.bookingId.toString().contains(q)) continue;
      hits.add(
        _SearchHit(
          title: 'Booking #${booking.bookingId}',
          subtitle:
              '${widget.indexes.customerName(booking.customerId)} · '
              '${widget.indexes.apartmentLabel(booking.apartmentId)}',
          icon: Icons.handshake_outlined,
          color: scheme.secondary,
          onTap: () => widget.onOpenBooking(booking.bookingId),
        ),
      );
    }

    hits.sort((a, b) => a.title.compareTo(b.title));
    return hits.take(40).toList();
  }

  bool _matchesCustomer(CustomerModel customer, String q) {
    return customer.name.toLowerCase().contains(q) ||
        customer.phone.toLowerCase().contains(q) ||
        customer.nationalNum.toLowerCase().contains(q) ||
        customer.customerId.toString().contains(q);
  }
}

class _SearchHit {
  const _SearchHit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
