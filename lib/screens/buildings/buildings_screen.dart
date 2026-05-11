import 'package:flutter/material.dart';

import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/screens/buildings/building_form_screen.dart';
import 'package:estatetrack1/screens/buildings/apartment_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

/// Buildings and apartments are owned by [HomeScreen] and passed in so every
/// tab uses the same inventory (backend-ready single source of truth).
class BuildingsScreen extends StatelessWidget {
  const BuildingsScreen({
    super.key,
    required this.buildings,
    required this.apartments,
    required this.onBuildingsChanged,
    required this.onApartmentsChanged,
  });

  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final void Function(List<BuildingModel>) onBuildingsChanged;
  final void Function(List<ApartmentModel>) onApartmentsChanged;

  static int _nextBuildingId(List<BuildingModel> list) {
    if (list.isEmpty) return 1;
    return list.map((e) => e.buildingId).reduce((a, b) => a > b ? a : b) + 1;
  }

  static int _nextApartmentId(List<ApartmentModel> list) {
    if (list.isEmpty) return 1;
    return list.map((e) => e.apartmentId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _openBuildingForm(
    BuildContext context, {
    BuildingModel? existing,
  }) async {
    final result = await Navigator.of(context).push<BuildingModel>(
      MaterialPageRoute(
        builder: (context) => BuildingFormScreen(existing: existing),
      ),
    );
    if (!context.mounted || result == null) return;

    final next = List<BuildingModel>.from(buildings);
    if (existing != null) {
      final i = next.indexWhere((b) => b.buildingId == existing.buildingId);
      if (i >= 0) {
        next[i] = result.copyWith(buildingId: existing.buildingId);
      }
    } else {
      next.add(result.copyWith(buildingId: _nextBuildingId(buildings)));
    }
    onBuildingsChanged(next);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Building updated' : 'Building added',
        ),
      ),
    );
  }

  Future<void> _openApartmentForm(
    BuildContext context, {
    ApartmentModel? existing,
    required int buildingId,
  }) async {
    final result = await Navigator.of(context).push<ApartmentModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentFormScreen(
          existing: existing,
          buildingId: buildingId,
        ),
      ),
    );
    if (!context.mounted || result == null) return;

    final next = List<ApartmentModel>.from(apartments);
    if (existing != null) {
      final i = next.indexWhere((a) => a.apartmentId == existing.apartmentId);
      if (i >= 0) {
        next[i] = result.copyWith(apartmentId: existing.apartmentId);
      }
    } else {
      next.add(result.copyWith(apartmentId: _nextApartmentId(apartments)));
    }
    onApartmentsChanged(next);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Apartment updated' : 'Apartment added',
        ),
      ),
    );
  }

  Future<void> _confirmDeleteBuilding(BuildContext context, BuildingModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete building?'),
        content: Text('Remove ${b.name} and all its apartments in this list?'),
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
    if (ok != true || !context.mounted) return;

    onBuildingsChanged(
      buildings.where((e) => e.buildingId != b.buildingId).toList(),
    );
    onApartmentsChanged(
      apartments.where((e) => e.buildingId != b.buildingId).toList(),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Building deleted')),
    );
  }

  Future<void> _confirmDeleteApartment(
    BuildContext context,
    ApartmentModel a,
  ) async {
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
    if (ok != true || !context.mounted) return;

    onApartmentsChanged(
      apartments.where((e) => e.apartmentId != a.apartmentId).toList(),
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apartment deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (buildings.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_buildings',
          onPressed: () => _openBuildingForm(context),
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
                  'No buildings yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add a building.',
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
        heroTag: 'fab_buildings',
        onPressed: () => _openBuildingForm(context),
        tooltip: 'Add Building',
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: buildings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final b = buildings[index];
          final buildingApartments =
              apartments.where((a) => a.buildingId == b.buildingId).toList();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.floorsCount} floors • ${buildingApartments.length}/${b.totalApartments} apartments',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              b.location,
                              style: TextStyle(
                                color: scheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openBuildingForm(context, existing: b);
                          } else if (value == 'delete') {
                            _confirmDeleteBuilding(context, b);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (buildingApartments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No apartments',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: buildingApartments.length,
                      separatorBuilder: (context, i) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = buildingApartments[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            a.number ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        AppStatusChip(
                                          label:
                                              a.isAvailable ? 'Vacant' : 'Occupied',
                                          tone: a.isAvailable
                                              ? AppChipTone.neutral
                                              : AppChipTone.positive,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${a.bedrooms} bed • ${a.bathrooms} bath • ${a.sizeM2} m²',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      r'$' '${a.rentPricePerMonth.toStringAsFixed(0)}/month',
                                      style: TextStyle(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openApartmentForm(
                                      context,
                                      existing: a,
                                      buildingId: b.buildingId,
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDeleteApartment(context, a);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _openApartmentForm(context, buildingId: b.buildingId),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Apartment'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
