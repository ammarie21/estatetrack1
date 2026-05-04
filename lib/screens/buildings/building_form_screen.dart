import 'package:flutter/material.dart';

import 'package:estatetrack1/models/building_model.dart';

class BuildingFormScreen extends StatefulWidget {
  const BuildingFormScreen({super.key, this.existing});

  final BuildingModel? existing;

  @override
  State<BuildingFormScreen> createState() => _BuildingFormScreenState();
}

class _BuildingFormScreenState extends State<BuildingFormScreen> {
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
    _constructionYear = TextEditingController(text: e?.constructionYear.toString() ?? '');
    _totalApartments = TextEditingController(text: e?.totalApartments.toString() ?? '');
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
    final floorsCount = int.tryParse(_floorsCount.text) ?? 0;
    final constructionYear = int.tryParse(_constructionYear.text) ?? 2024;
    final totalApartments = int.tryParse(_totalApartments.text) ?? 0;

    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter building name')),
      );
      return;
    }

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
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Building' : 'Add Building'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Building Name',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _floorsCount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Number of Floors',
              prefixIcon: Icon(Icons.layers_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _constructionYear,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Construction Year',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _totalApartments,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Apartments',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Update Building' : 'Add Building'),
          ),
        ],
      ),
    );
  }
}