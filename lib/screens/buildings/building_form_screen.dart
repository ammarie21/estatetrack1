import 'package:flutter/material.dart';

import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

class BuildingFormScreen extends StatefulWidget {
  const BuildingFormScreen({super.key, this.existing});

  final BuildingModel? existing;

  @override
  State<BuildingFormScreen> createState() => _BuildingFormScreenState();
}

class _BuildingFormScreenState extends State<BuildingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _floorsCount;
  late final TextEditingController _constructionYear;
  late final TextEditingController _totalApartments;
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _floorsCount = TextEditingController(text: e?.floorsCount.toString() ?? '');
    _constructionYear = TextEditingController(
      text: e?.constructionYear.toString() ?? '',
    );
    _totalApartments = TextEditingController(
      text: e?.totalApartments.toString() ?? '',
    );
    _location = TextEditingController(text: e?.location ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _floorsCount.dispose();
    _constructionYear.dispose();
    _totalApartments.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      AppSnackbars.error(context, 'Please fix the highlighted fields');
      return;
    }
    final floorsCount = int.tryParse(_floorsCount.text) ?? 0;
    final constructionYear = int.tryParse(_constructionYear.text) ?? 2024;
    final totalApartments = int.tryParse(_totalApartments.text) ?? 0;

    final e = widget.existing;
    final model = BuildingModel(
      buildingId: e?.buildingId ?? 0,
      name: _name.text.trim(),
      floorsCount: floorsCount,
      constructionYear: constructionYear,
      totalApartments: totalApartments,
      location: _location.text.trim(),
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Building' : 'Add Building')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Building Name',
                prefixIcon: Icon(Icons.apartment_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Building name is required'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _floorsCount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Number of Floors',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
              validator: (value) {
                final floors = int.tryParse(value ?? '');
                if (floors == null || floors < 1) {
                  return 'Floors count must be at least 1';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _constructionYear,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Construction Year',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (value) {
                final year = int.tryParse(value ?? '');
                if (year == null || year < 1900 || year > 2100) {
                  return 'Enter a valid construction year';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalApartments,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Apartments',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (value) {
                final total = int.tryParse(value ?? '');
                if (total == null || total < 0) {
                  return 'Total apartments cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Location is required'
                  : null,
            ),
            const SizedBox(height: 24),
            AppFormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
              saveLabel: isEdit ? 'Update Building' : 'Add Building',
            ),
          ],
        ),
      ),
    );
  }
}
