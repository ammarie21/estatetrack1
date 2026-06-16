import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/screens/apartments/apartment_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

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
      const ApartmentModel(
        apartmentId: 2,
        buildingId: 1,
        typeId: 1,
        sizeM2: 75,
        rentPricePerMonth: 420,
        rentPricePerDay: 14,
        isAvailable: true,
        bedrooms: 2,
        bathrooms: 1,
        hasBalcony: false,
        furnished: true,
        hasInternet: true,
        parking: false,
        elevator: true,
        number: 'A-102',
        location: 'Tower A, Floor 1',
      ),
      const ApartmentModel(
        apartmentId: 3,
        buildingId: 2,
        typeId: 2,
        sizeM2: 120,
        rentPricePerMonth: 680,
        rentPricePerDay: 22.67,
        isAvailable: false,
        bedrooms: 3,
        bathrooms: 2,
        hasBalcony: true,
        furnished: true,
        hasInternet: true,
        parking: true,
        elevator: true,
        number: 'B-204',
        location: 'Tower B, Floor 2',
      ),
      const ApartmentModel(
        apartmentId: 4,
        buildingId: 2,
        typeId: 2,
        sizeM2: 110,
        rentPricePerMonth: 650,
        rentPricePerDay: 21.67,
        isAvailable: false,
        bedrooms: 3,
        bathrooms: 2,
        hasBalcony: true,
        furnished: false,
        hasInternet: true,
        parking: true,
        elevator: true,
        number: 'B-205',
        location: 'Tower B, Floor 2',
      ),
      const ApartmentModel(
        apartmentId: 5,
        buildingId: 3,
        typeId: 3,
        sizeM2: 150,
        rentPricePerMonth: 890,
        rentPricePerDay: 29.67,
        isAvailable: true,
        bedrooms: 4,
        bathrooms: 3,
        hasBalcony: true,
        furnished: true,
        hasInternet: true,
        parking: true,
        elevator: true,
        number: 'C-310',
        location: 'Tower C, Floor 3',
      ),
    ];
  }

  int _nextId() {
    if (_apartments.isEmpty) return 1;
    return _apartments
            .map((e) => e.apartmentId)
            .reduce((a, b) => a > b ? a : b) +
        1;
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
        final i = _apartments.indexWhere(
          (a) => a.apartmentId == existing.apartmentId,
        );
        if (i >= 0) {
          _apartments[i] = result.copyWith(apartmentId: existing.apartmentId);
        }
      } else {
        _apartments.add(result.copyWith(apartmentId: _nextId()));
      }
    });

    if (!mounted) return;
    AppSnackbars.success(
      context,
      existing != null ? 'Apartment updated' : 'Apartment added',
    );
  }

  Future<void> _confirmDelete(ApartmentModel a) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete apartment?',
      message: 'Remove apartment ${a.number} from this local list?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    setState(() {
      _apartments.removeWhere((e) => e.apartmentId == a.apartmentId);
    });
    AppSnackbars.success(context, 'Apartment deleted');
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppFlowBanner(
              icon: Icons.phone_android_outlined,
              text:
                  'Legacy local demo list. Backend apartments are managed from Buildings.',
            ),
            Expanded(
              child: AppEmptyState(
                icon: Icons.apartment_outlined,
                title: 'No apartments yet',
                message: 'Tap + to add an apartment to this local demo list.',
                actionLabel: 'Add apartment',
                onAction: () => _openForm(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_apartments',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppFlowBanner(
            icon: Icons.phone_android_outlined,
            text:
                'Legacy local demo list. Backend apartments are managed from Buildings.',
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                kAppListBottomInset,
              ),
              itemCount: _apartments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = _apartments[index];
                final occupied = a.isOccupied;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        a.number ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.location ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              r'$'
                              '${a.rent.toStringAsFixed(0)} / month',
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
                            icon: Icon(
                              Icons.delete_outline,
                              color: scheme.error,
                            ),
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
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.occupied});

  final bool occupied;

  @override
  Widget build(BuildContext context) {
    final label = occupied ? 'Occupied' : 'Vacant';
    return AppStatusChip(
      label: label,
      tone: occupied ? AppChipTone.warning : AppChipTone.positive,
    );
  }
}
