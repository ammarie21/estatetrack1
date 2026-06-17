import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/screens/buildings/maintenance_form_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/deferred_delete.dart';
import 'package:estatetrack1/utils/apartment_display.dart';

class MaintenancePanel extends StatefulWidget {
  const MaintenancePanel({
    super.key,
    required this.maintenance,
    required this.apartments,
    required this.buildings,
    required this.onMaintenanceChanged,
  });

  final List<MaintenanceModel> maintenance;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;
  final void Function(List<MaintenanceModel>) onMaintenanceChanged;

  @override
  State<MaintenancePanel> createState() => MaintenancePanelState();
}

class MaintenancePanelState extends State<MaintenancePanel> {
  String _searchQuery = '';

  List<MaintenanceModel> get _filteredMaintenance {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return widget.maintenance;
    return widget.maintenance.where((item) {
      final apartment = _apartmentLabel(item.apartmentId).toLowerCase();
      return item.description.toLowerCase().contains(q) ||
          apartment.contains(q) ||
          item.date.toLowerCase().contains(q);
    }).toList();
  }

  String _apartmentLabel(String apartmentId) {
    final id = int.tryParse(apartmentId);
    if (id == null) return 'Unit $apartmentId';
    final apartment = widget.apartments
        .where((a) => a.apartmentId == id)
        .firstOrNull;
    if (apartment == null) return 'Unit #$id';
    return apartmentDisplayLabel(apartment, widget.buildings);
  }

  AppChipTone _maintenanceTone(String status) {
    switch (status.toLowerCase()) {
      case 'done':
      case 'completed':
        return AppChipTone.positive;
      case 'pending':
      case 'in progress':
        return AppChipTone.warning;
      default:
        return AppChipTone.neutral;
    }
  }

  bool _canComplete(String status) {
    final normalized = status.toLowerCase();
    return normalized != 'done' && normalized != 'completed';
  }

  Future<void> _completeMaintenance(MaintenanceModel item) async {
    try {
      await EstateApi.instance.endMaintenance(item.id);
      final next = List<MaintenanceModel>.from(widget.maintenance);
      final index = next.indexWhere((m) => m.id == item.id);
      if (index >= 0) {
        next[index] = item.copyWith(status: 'Done');
      }
      widget.onMaintenanceChanged(next);

      if (!mounted) return;
      AppSnackbars.success(context, 'Maintenance marked complete');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Complete failed: ${e.message}');
    }
  }

  Future<void> openCreateForm() => _openForm();

  Future<void> _openForm({MaintenanceModel? existing}) async {
    final result = await Navigator.of(context).push<MaintenanceModel>(
      MaterialPageRoute(
        builder: (context) => MaintenanceFormScreen(
          existing: existing,
          apartments: widget.apartments,
          buildings: widget.buildings,
        ),
      ),
    );
    if (!mounted || result == null) return;

    try {
      final saved = existing != null
          ? await EstateApi.instance.updateMaintenance(
              result.copyWith(id: existing.id),
            )
          : await EstateApi.instance.createMaintenance(result.copyWith(id: 0));

      final next = List<MaintenanceModel>.from(widget.maintenance);
      if (existing != null) {
        final index = next.indexWhere((m) => m.id == existing.id);
        if (index >= 0) next[index] = saved;
      } else {
        next.add(saved);
      }
      next.sort((a, b) => b.date.compareTo(a.date));
      widget.onMaintenanceChanged(next);

      if (!mounted) return;
      AppSnackbars.success(
        context,
        existing != null ? 'Maintenance updated' : 'Maintenance logged',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Maintenance save failed: ${e.message}');
    }
  }

  Future<void> _confirmDelete(MaintenanceModel item) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete maintenance?',
      message: 'Remove "${item.description}" from the maintenance log?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (ok != true || !mounted) return;

    final backup = List<MaintenanceModel>.from(widget.maintenance);
    try {
      await deferredDelete(
        context: context,
        message: 'Maintenance record removed',
        onRemove: () {
          widget.onMaintenanceChanged(
            widget.maintenance.where((m) => m.id != item.id).toList(),
          );
        },
        onRestore: () => widget.onMaintenanceChanged(backup),
        commit: () => EstateApi.instance.deleteMaintenance(item.id),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Maintenance delete failed: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalCost = widget.maintenance.fold(
      0.0,
      (sum, item) => sum + item.cost,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Records',
                  value: '${widget.maintenance.length}',
                  icon: Icons.list_alt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: 'Total cost',
                  value: '\$${totalCost.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                ),
              ),
            ],
          ),
        ),
        if (widget.maintenance.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppSearchField(
              hint: 'Search maintenance…',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        Expanded(
          child: widget.maintenance.isEmpty
              ? AppEmptyState(
                  icon: Icons.build_circle_outlined,
                  title: 'No maintenance logged',
                  message:
                      'Log repairs, inspections, and service costs against apartments so reports stay accurate.',
                  actionLabel: 'Log maintenance',
                  onAction: openCreateForm,
                )
              : _filteredMaintenance.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_off_outlined,
                  title: 'No matches',
                  message: 'Try a different search term.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: _filteredMaintenance.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _filteredMaintenance[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          item.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${_apartmentLabel(item.apartmentId)} · ${item.date}',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${item.cost.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: scheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                AppStatusChip(
                                  label: item.status,
                                  tone: _maintenanceTone(item.status),
                                ),
                              ],
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                if (_canComplete(item.status))
                                  const PopupMenuItem(
                                    value: 'complete',
                                    child: Text('Mark complete'),
                                  ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openForm(existing: item);
                                } else if (value == 'complete') {
                                  _completeMaintenance(item);
                                } else if (value == 'delete') {
                                  _confirmDelete(item);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
