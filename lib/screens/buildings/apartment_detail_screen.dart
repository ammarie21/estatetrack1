import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

class ApartmentDetailScreen extends StatelessWidget {
  const ApartmentDetailScreen({
    super.key,
    required this.apartment,
    required this.building,
    required this.maintenance,
    required this.apartmentTypes,
    this.contracts = const [],
    this.customers = const [],
  });

  final ApartmentModel apartment;
  final BuildingModel building;
  final List<MaintenanceModel> maintenance;
  final List<ApartmentTypeModel> apartmentTypes;
  final List<ContractModel> contracts;
  final List<CustomerModel> customers;

  List<MaintenanceModel> get _apartmentMaintenance =>
      maintenance
          .where((m) => m.apartmentId == apartment.apartmentId.toString())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double get _maintenanceCost =>
      _apartmentMaintenance.fold(0.0, (sum, m) => sum + m.cost);

  ContractModel? get _activeLease {
    for (final contract in contracts) {
      if (contract.apartmentId == apartment.apartmentId &&
          contract.status == 'Active') {
        return contract;
      }
    }
    return null;
  }

  String get _typeLabel {
    final type = apartmentTypes
        .where((t) => t.typeId == apartment.typeId)
        .firstOrNull;
    return type?.apartmentType ?? 'Type #${apartment.typeId}';
  }

  String? get _tenantName {
    final lease = _activeLease;
    if (lease == null) return null;
    return customers
        .where((c) => c.customerId == lease.customerId)
        .firstOrNull
        ?.name;
  }

  AppChipTone _maintenanceTone(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return AppChipTone.positive;
      case 'pending':
        return AppChipTone.warning;
      default:
        return AppChipTone.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final title = apartment.number?.trim().isNotEmpty == true
        ? apartment.number!.trim()
        : 'Apartment #${apartment.apartmentId}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kAppListBottomInset),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: t.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      AppStatusChip(
                        label: apartment.isAvailable ? 'Vacant' : 'Occupied',
                        tone: apartment.isAvailable
                            ? AppChipTone.neutral
                            : AppChipTone.positive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    building.name,
                    style: t.titleSmall?.copyWith(color: scheme.primary),
                  ),
                  if (apartment.location?.trim().isNotEmpty == true)
                    Text(
                      apartment.location!.trim(),
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    building.location,
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (_tenantName != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Current tenant: $_tenantName',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _DetailStatCard(
                label: 'Bedrooms',
                value: '${apartment.bedrooms}',
                icon: Icons.bed_outlined,
                accent: scheme.primary,
              ),
              _DetailStatCard(
                label: 'Bathrooms',
                value: '${apartment.bathrooms}',
                icon: Icons.bathtub_outlined,
                accent: scheme.primary,
              ),
              _DetailStatCard(
                label: 'Size',
                value: '${apartment.sizeM2} m²',
                icon: Icons.square_foot_outlined,
                accent: scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DetailStatCard(
                  label: 'Rent / month',
                  value: '\$${apartment.rentPricePerMonth.toStringAsFixed(0)}',
                  icon: Icons.calendar_month_outlined,
                  accent: Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailStatCard(
                  label: 'Rent / day',
                  value: '\$${apartment.rentPricePerDay.toStringAsFixed(0)}',
                  icon: Icons.today_outlined,
                  accent: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Unit details'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: $_typeLabel'),
                  if (apartment.description?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(apartment.description!.trim()),
                  ],
                  if (apartment.notes?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Text(
                      apartment.notes!.trim(),
                      style: t.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const AppSectionHeader(title: 'Features'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (apartment.hasBalcony)
                _FeatureChip(label: 'Balcony', icon: Icons.balcony),
              if (apartment.furnished)
                _FeatureChip(label: 'Furnished', icon: Icons.chair_outlined),
              if (apartment.hasInternet)
                _FeatureChip(label: 'Internet', icon: Icons.wifi),
              if (apartment.parking)
                _FeatureChip(label: 'Parking', icon: Icons.local_parking),
              if (apartment.elevator)
                _FeatureChip(label: 'Elevator', icon: Icons.elevator),
              if (!apartment.hasBalcony &&
                  !apartment.furnished &&
                  !apartment.hasInternet &&
                  !apartment.parking &&
                  !apartment.elevator)
                Text(
                  'No feature flags recorded',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AppSectionHeader(
            title: 'Maintenance history',
            subtitle: _apartmentMaintenance.isEmpty
                ? 'No records yet'
                : 'Total cost: \$${_maintenanceCost.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          if (_apartmentMaintenance.isEmpty)
            const AppEmptyState(
              icon: Icons.build_outlined,
              title: 'No maintenance logged',
              message: 'Maintenance records for this unit appear here.',
            )
          else
            ..._apartmentMaintenance.map((m) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer.withValues(
                      alpha: 0.5,
                    ),
                    child: Icon(
                      Icons.build_outlined,
                      color: scheme.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    m.description,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(m.date.split('T').first),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${m.cost.toStringAsFixed(0)}',
                        style: t.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppStatusChip(
                        label: m.status,
                        tone: _maintenanceTone(m.status),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  const _DetailStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: t.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              label,
              style: t.labelSmall?.copyWith(
                color: accent.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label),
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.35),
    );
  }
}
