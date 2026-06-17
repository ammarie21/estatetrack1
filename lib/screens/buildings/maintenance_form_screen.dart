import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';

class MaintenanceFormScreen extends StatefulWidget {
  const MaintenanceFormScreen({
    super.key,
    this.existing,
    required this.apartments,
    required this.buildings,
  });

  final MaintenanceModel? existing;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;

  @override
  State<MaintenanceFormScreen> createState() => _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends State<MaintenanceFormScreen> {
  late final TextEditingController _description;
  late final TextEditingController _cost;
  String? _apartmentId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _description = TextEditingController(text: e?.description ?? '');
    _cost = TextEditingController(
      text: e != null ? e.cost.toStringAsFixed(2) : '',
    );
    _apartmentId =
        e?.apartmentId ??
        (widget.apartments.isNotEmpty
            ? widget.apartments.first.apartmentId.toString()
            : null);
    if (e != null) {
      _date = DateTime.tryParse(e.date) ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _cost.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (_apartmentId == null || _description.text.trim().isEmpty) {
      AppSnackbars.error(
        context,
        'Select an apartment and enter a description',
      );
      return;
    }

    final cost = double.tryParse(_cost.text.replaceAll(',', '')) ?? 0;
    if (cost < 0) {
      AppSnackbars.error(context, 'Cost cannot be negative');
      return;
    }

    final e = widget.existing;
    Navigator.of(context).pop(
      MaintenanceModel(
        id: e?.id ?? 0,
        apartmentId: _apartmentId!,
        description: _description.text.trim(),
        cost: cost,
        date: _date.toIso8601String().split('T').first,
        status: e?.status ?? 'Pending',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.apartments.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Maintenance')),
        body: const AppEmptyState(
          icon: Icons.apartment_outlined,
          title: 'No apartments yet',
          message: 'Add apartments first, then you can log maintenance work.',
        ),
      );
    }

    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit maintenance' : 'Log maintenance'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const AppFlowBanner(
            icon: Icons.receipt_long_outlined,
            text:
                'Maintenance is saved against the apartment as a backend-backed expense and included in reports.',
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Apartment',
              prefixIcon: Icon(Icons.apartment_outlined),
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _apartmentId,
                items: widget.apartments.map((a) {
                  return DropdownMenuItem(
                    value: a.apartmentId.toString(),
                    child: Text(
                      apartmentDisplayLabel(a, widget.buildings),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _apartmentId = v),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.build_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Maintenance expense cost',
              prefixIcon: Icon(Icons.attach_money),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          AppDateField(label: 'Service date', date: _date, onPick: _pickDate),
          const SizedBox(height: 24),
          AppFormActions(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _save,
            saveLabel: isEdit ? 'Save changes' : 'Log maintenance',
          ),
        ],
      ),
    );
  }
}
