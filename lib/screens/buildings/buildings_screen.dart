import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/screens/buildings/apartment_detail_screen.dart';
import 'package:estatetrack1/screens/buildings/apartment_form_screen.dart';
import 'package:estatetrack1/screens/buildings/apartment_types_panel.dart';
import 'package:estatetrack1/screens/buildings/building_form_screen.dart';
import 'package:estatetrack1/screens/maintenance/maintenance_panel.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/deferred_delete.dart';

/// Buildings, apartments, and maintenance share one inventory hub.
class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({
    super.key,
    required this.buildings,
    required this.apartments,
    required this.apartmentTypes,
    required this.maintenance,
    required this.onBuildingsChanged,
    required this.onApartmentsChanged,
    required this.onMaintenanceChanged,
    this.onRefresh,
    this.onApartmentTypesChanged,
    this.contracts = const [],
    this.customers = const [],
    this.initialAvailabilityFilter,
  });

  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final List<ApartmentTypeModel> apartmentTypes;
  final List<MaintenanceModel> maintenance;
  final List<ContractModel> contracts;
  final List<CustomerModel> customers;
  final void Function(List<BuildingModel>) onBuildingsChanged;
  final void Function(List<ApartmentModel>) onApartmentsChanged;
  final void Function(List<MaintenanceModel>) onMaintenanceChanged;
  final Future<void> Function()? onRefresh;
  final void Function(List<ApartmentTypeModel>)? onApartmentTypesChanged;
  final String? initialAvailabilityFilter;

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<MaintenancePanelState> _maintenanceKey =
      GlobalKey<MaintenancePanelState>();
  final GlobalKey<ApartmentTypesPanelState> _typesKey =
      GlobalKey<ApartmentTypesPanelState>();
  late String _availabilityFilter;

  @override
  void initState() {
    super.initState();
    _availabilityFilter = widget.initialAvailabilityFilter ?? 'All';
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openBuildingForm({BuildingModel? existing}) async {
    final result = await Navigator.of(context).push<BuildingModel>(
      MaterialPageRoute(
        builder: (context) => BuildingFormScreen(existing: existing),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final saved = existing != null
          ? await EstateApi.instance.updateBuilding(
              result.copyWith(buildingId: existing.buildingId),
            )
          : await EstateApi.instance.createBuilding(
              result.copyWith(buildingId: 0),
            );

      final next = List<BuildingModel>.from(widget.buildings);
      if (existing != null) {
        final i = next.indexWhere((b) => b.buildingId == existing.buildingId);
        if (i >= 0) next[i] = saved;
      } else {
        next.add(saved);
      }
      widget.onBuildingsChanged(next);

      if (!mounted) return;
      AppSnackbars.success(
        context,
        existing != null ? 'Building updated' : 'Building added',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Building save failed: ${e.message}');
    }
  }

  Future<void> _openApartmentForm({
    ApartmentModel? existing,
    required int buildingId,
  }) async {
    final result = await Navigator.of(context).push<ApartmentModel>(
      MaterialPageRoute(
        builder: (context) => ApartmentFormScreen(
          existing: existing,
          buildingId: buildingId,
          apartmentTypes: widget.apartmentTypes,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final apiModel = result.copyWith(
        apartmentId: existing?.apartmentId ?? 0,
        typeId: existing?.typeId ?? result.typeId,
        notes: result.notes ?? result.number,
        description: result.description ?? result.location,
      );
      final saved = existing != null
          ? await EstateApi.instance.updateApartment(apiModel)
          : await EstateApi.instance.createApartment(apiModel);

      final next = List<ApartmentModel>.from(widget.apartments);
      if (existing != null) {
        final i = next.indexWhere((a) => a.apartmentId == existing.apartmentId);
        if (i >= 0) {
          next[i] = saved.copyWith(
            number: result.number,
            location: result.location,
          );
        }
      } else {
        next.add(
          saved.copyWith(number: result.number, location: result.location),
        );
      }
      widget.onApartmentsChanged(next);

      if (!mounted) return;
      AppSnackbars.success(
        context,
        existing != null ? 'Apartment updated' : 'Apartment added',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Apartment save failed: ${e.message}');
    }
  }

  Future<void> _confirmDeleteBuilding(BuildingModel b) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete building?',
      message: 'Remove ${b.name} and all its apartments in this list?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final backupBuildings = List<BuildingModel>.from(widget.buildings);
    final backupApartments = List<ApartmentModel>.from(widget.apartments);

    try {
      await deferredDelete(
        context: context,
        message: '${b.name} removed',
        onRemove: () {
          widget.onBuildingsChanged(
            widget.buildings.where((e) => e.buildingId != b.buildingId).toList(),
          );
          widget.onApartmentsChanged(
            widget.apartments.where((e) => e.buildingId != b.buildingId).toList(),
          );
        },
        onRestore: () {
          widget.onBuildingsChanged(backupBuildings);
          widget.onApartmentsChanged(backupApartments);
        },
        commit: () => EstateApi.instance.deleteBuilding(b.buildingId),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Building delete failed: ${e.message}');
    }
  }

  Future<void> _confirmDeleteApartment(ApartmentModel a) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete apartment?',
      message: 'Remove apartment ${a.number}?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final backup = List<ApartmentModel>.from(widget.apartments);
    try {
      await deferredDelete(
        context: context,
        message: 'Apartment ${a.number} removed',
        onRemove: () {
          widget.onApartmentsChanged(
            widget.apartments
                .where((e) => e.apartmentId != a.apartmentId)
                .toList(),
          );
        },
        onRestore: () => widget.onApartmentsChanged(backup),
        commit: () => EstateApi.instance.deleteApartment(a.apartmentId),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Apartment delete failed: ${e.message}');
    }
  }

  String _typeLabel(int typeId) {
    final type = widget.apartmentTypes
        .where((t) => t.typeId == typeId)
        .firstOrNull;
    return type?.apartmentType ?? 'Type #$typeId';
  }

  void _openApartmentDetail(ApartmentModel apartment, BuildingModel building) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ApartmentDetailScreen(
          apartment: apartment,
          building: building,
          maintenance: widget.maintenance,
          apartmentTypes: widget.apartmentTypes,
          contracts: widget.contracts,
          customers: widget.customers,
        ),
      ),
    );
  }

  Widget _inventoryTab(ColorScheme scheme) {
    if (widget.buildings.isEmpty) {
      return AppEmptyState(
        icon: Icons.apartment_outlined,
        title: 'No buildings yet',
        message: 'Add a building, then register apartments inside it.',
        actionLabel: 'Add building',
        onAction: _openBuildingForm,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, kAppListBottomInset),
      itemCount: widget.buildings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final b = widget.buildings[index];
        final buildingApartments = widget.apartments
            .where((a) => a.buildingId == b.buildingId)
            .where((a) {
              if (_availabilityFilter == 'Vacant') return a.isAvailable;
              if (_availabilityFilter == 'Occupied') return !a.isAvailable;
              return true;
            })
            .toList();

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
                          _openBuildingForm(existing: b);
                        } else if (value == 'delete') {
                          _confirmDeleteBuilding(b);
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
                      return InkWell(
                        onTap: () => _openApartmentDetail(a, b),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
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
                                          label: a.isAvailable
                                              ? 'Vacant'
                                              : 'Occupied',
                                          tone: a.isAvailable
                                              ? AppChipTone.neutral
                                              : AppChipTone.positive,
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${_typeLabel(a.typeId)} • ${a.bedrooms} bed • ${a.bathrooms} bath • ${a.sizeM2} m²',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      r'$'
                                      '${a.rentPricePerMonth.toStringAsFixed(0)}/month',
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
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openApartmentForm(
                                      existing: a,
                                      buildingId: b.buildingId,
                                    );
                                  } else if (value == 'delete') {
                                    _confirmDeleteApartment(a);
                                  }
                                },
                              ),
                            ],
                          ),
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
                          _openApartmentForm(buildingId: b.buildingId),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabController.index;
    final onMaintenance = tabIndex == 1;
    final onTypes = tabIndex == 2;

    return Scaffold(
      floatingActionButton: onMaintenance
          ? FloatingActionButton.extended(
              heroTag: 'fab_maintenance',
              onPressed: () => _maintenanceKey.currentState?.openCreateForm(),
              icon: const Icon(Icons.build_outlined),
              label: const Text('Log maintenance'),
            )
          : onTypes
          ? FloatingActionButton.extended(
              heroTag: 'fab_types',
              onPressed: () => _typesKey.currentState?.openCreateForm(),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Add type'),
            )
          : FloatingActionButton.extended(
              heroTag: 'fab_buildings',
              onPressed: _openBuildingForm,
              tooltip: 'Add Building',
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Add building'),
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFlowBanner(
            icon: Icons.apartment_outlined,
            text: onMaintenance
                ? 'Maintenance records are saved to the backend and linked to apartments.'
                : onTypes
                ? 'Apartment types are stored in the backend and used when classifying units.'
                : 'Manage building inventory and apartment availability from one place.',
          ),
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Inventory'),
                Tab(text: 'Maintenance'),
                Tab(text: 'Types'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    AppFilterChips(
                      options: const ['All', 'Vacant', 'Occupied'],
                      selected: _availabilityFilter,
                      onSelected: (v) =>
                          setState(() => _availabilityFilter = v),
                    ),
                    Expanded(
                      child: widget.onRefresh == null
                          ? _inventoryTab(Theme.of(context).colorScheme)
                          : RefreshIndicator(
                              onRefresh: widget.onRefresh!,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _inventoryTab(
                                        Theme.of(context).colorScheme,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
                MaintenancePanel(
                  key: _maintenanceKey,
                  maintenance: widget.maintenance,
                  apartments: widget.apartments,
                  buildings: widget.buildings,
                  onMaintenanceChanged: widget.onMaintenanceChanged,
                ),
                ApartmentTypesPanel(
                  key: _typesKey,
                  initialTypes: widget.apartmentTypes,
                  onTypesChanged: widget.onApartmentTypesChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
