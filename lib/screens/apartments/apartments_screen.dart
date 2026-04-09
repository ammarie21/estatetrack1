import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/screens/apartments/apartment_form_screen.dart';

class ApartmentsScreen extends StatefulWidget {
  const ApartmentsScreen({super.key});

  @override
  State<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends State<ApartmentsScreen> {
  late List<ApartmentModel> _apartments;

  @override
  void initState() {
    super.initState();
    _apartments = [
      const ApartmentModel(
        id: 1,
        number: 'A-101',
        location: 'Tower A, Floor 1',
        rent: 450,
        bedrooms: 2,
        bathrooms: 2,
        isOccupied: true,
      ),
      const ApartmentModel(
        id: 2,
        number: 'A-102',
        location: 'Tower A, Floor 1',
        rent: 420,
        bedrooms: 2,
        bathrooms: 1,
        isOccupied: false,
      ),
      const ApartmentModel(
        id: 3,
        number: 'B-204',
        location: 'Tower B, Floor 2',
        rent: 680,
        bedrooms: 3,
        bathrooms: 2,
        isOccupied: true,
      ),
      const ApartmentModel(
        id: 4,
        number: 'B-205',
        location: 'Tower B, Floor 2',
        rent: 650,
        bedrooms: 3,
        bathrooms: 2,
        isOccupied: true,
      ),
      const ApartmentModel(
        id: 5,
        number: 'C-310',
        location: 'Tower C, Floor 3',
        rent: 890,
        bedrooms: 4,
        bathrooms: 3,
        isOccupied: false,
      ),
    ];
  }

  int _nextId() {
    if (_apartments.isEmpty) return 1;
    return _apartments.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _openForm({ApartmentModel? existing}) async {
    final result = await Navigator.of(context).push<ApartmentModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _apartments.indexWhere((a) => a.id == existing.id);
        if (i >= 0) {
          _apartments[i] = result.copyWith(id: existing.id);
        }
      } else {
        _apartments.add(result.copyWith(id: _nextId()));
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Apartment updated' : 'Apartment added',
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ApartmentModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete apartment?'),
        content: Text('Remove apartment ${a.number}?'),
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
      _apartments.removeWhere((e) => e.id == a.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apartment deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_apartments.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_apartments',
          onPressed: () => _openForm(),
          child: const Icon(Icons.add),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apartment_outlined, size: 64, color: scheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No apartments yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add an apartment.',
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
        heroTag: 'fab_apartments',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _apartments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final a = _apartments[index];
          final occupied = a.isOccupied;
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  a.number,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.location),
                      const SizedBox(height: 4),
                      Text(
                        r'$' '${a.rent.toStringAsFixed(0)} / month',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _StatusBadge(occupied: occupied),
                      ),
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
                      onPressed: () => _openForm(existing: a),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: scheme.error),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(a),
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.occupied});

  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = occupied
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = occupied ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;
    final label = occupied ? 'Occupied' : 'Vacant';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
