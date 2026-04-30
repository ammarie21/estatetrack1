import 'package:flutter/material.dart';

import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/screens/buildings/building_form_screen.dart';
import 'package:estatetrack1/screens/buildings/apartment_form_screen.dart';

class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  late List<BuildingModel> _buildings;
  late List<ApartmentModel> _apartments;

  @override
  void initState() {
    super.initState();
    _buildings = [
      const BuildingModel(
        buildingId: 1,
        name: 'Tower A',
        floorsCount: 5,
        constructionYear: 2020,
        totalApartments: 15,
        location: 'Downtown',
      ),
      const BuildingModel(
        buildingId: 2,
        name: 'Tower B',
        floorsCount: 8,
        constructionYear: 2019,
        totalApartments: 24,
        location: 'Business District',
      ),
      const BuildingModel(
        buildingId: 3,
        name: 'Tower C',
        floorsCount: 10,
        constructionYear: 2021,
        totalApartments: 30,
        location: 'Residential Area',
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
    ];
  }

  int _nextBuildingId() {
    if (_buildings.isEmpty) return 1;
    return _buildings.map((e) => e.buildingId).reduce((a, b) => a > b ? a : b) + 1;
  }

  int _nextApartmentId() {
    if (_apartments.isEmpty) return 1;
    return _apartments.map((e) => e.apartmentId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _openBuildingForm({BuildingModel? existing}) async {
    final result = await Navigator.of(context).push<BuildingModel>(
      MaterialPageRoute(
        builder: (context) => BuildingFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _buildings.indexWhere((b) => b.buildingId == existing.buildingId);
        if (i >= 0) {
          _buildings[i] = result.copyWith(buildingId: existing.buildingId);
        }
      } else {
        _buildings.add(result.copyWith(buildingId: _nextBuildingId()));
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existing != null ? 'Building updated' : 'Building added',
        ),
      ),
    );
  }

  Future<void> _openApartmentForm({ApartmentModel? existing, required int buildingId}) async {
    final result = await Navigator.of(context).push<ApartmentModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentFormScreen(
          existing: existing,
          buildingId: buildingId,
        ),
      ),
    );
    if (!mounted || result == null) return;

    setState(() {
      if (existing != null) {
        final i = _apartments.indexWhere((a) => a.apartmentId == existing.apartmentId);
        if (i >= 0) {
          _apartments[i] = result.copyWith(apartmentId: existing.apartmentId);
        }
      } else {
        _apartments.add(result.copyWith(apartmentId: _nextApartmentId()));
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

  void _confirmDeleteBuilding(BuildingModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete building?'),
        content: Text('Remove ${b.name}?'),
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
      _buildings.removeWhere((e) => e.buildingId == b.buildingId);
      _apartments.removeWhere((e) => e.buildingId == b.buildingId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Building deleted')),
    );
  }

  void _confirmDeleteApartment(ApartmentModel a) async {
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
      _apartments.removeWhere((e) => e.apartmentId == a.apartmentId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apartment deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_buildings.isEmpty) {
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_buildings',
          onPressed: () => _openBuildingForm(),
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
        onPressed: () => _openBuildingForm(),
        tooltip: 'Add Building',
        child: const Icon(Icons.add),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _buildings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final b = _buildings[index];
          final buildingApartments = _apartments.where((a) => a.buildingId == b.buildingId).toList();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Building Header
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
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openBuildingForm(existing: b);
                          } else if (value == 'delete') {
                            _confirmDeleteBuilding(b);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  // Apartments List
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
                                    Text(
                                      a.number ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
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
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openApartmentForm(existing: a, buildingId: b.buildingId);
                                  } else if (value == 'delete') {
                                    _confirmDeleteApartment(a);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  // Add Apartment Button
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openApartmentForm(buildingId: b.buildingId),
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