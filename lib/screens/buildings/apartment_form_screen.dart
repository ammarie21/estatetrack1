import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';

class ApartmentFormScreen extends StatefulWidget {
  const ApartmentFormScreen({
    super.key,
    this.existing,
    required this.buildingId,
  });

  final ApartmentModel? existing;
  final int buildingId;

  @override
  State<ApartmentFormScreen> createState() => _ApartmentFormScreenState();
}

class _ApartmentFormScreenState extends State<ApartmentFormScreen> {
  late final TextEditingController _number;
  late final TextEditingController _location;
  late final TextEditingController _sizeM2;
  late final TextEditingController _rentPerMonth;
  late final TextEditingController _rentPerDay;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late bool _isAvailable;
  late bool _hasBalcony;
  late bool _furnished;
  late bool _hasInternet;
  late bool _parking;
  late bool _elevator;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _number = TextEditingController(text: e?.number ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _sizeM2 = TextEditingController(text: e?.sizeM2.toString() ?? '');
    _rentPerMonth = TextEditingController(text: e?.rentPricePerMonth.toString() ?? '');
    _rentPerDay = TextEditingController(text: e?.rentPricePerDay.toString() ?? '');
    _bedrooms = TextEditingController(text: e?.bedrooms.toString() ?? '');
    _bathrooms = TextEditingController(text: e?.bathrooms.toString() ?? '');
    _isAvailable = e?.isAvailable ?? true;
    _hasBalcony = e?.hasBalcony ?? false;
    _furnished = e?.furnished ?? false;
    _hasInternet = e?.hasInternet ?? false;
    _parking = e?.parking ?? false;
    _elevator = e?.elevator ?? false;
  }

  @override
  void dispose() {
    _number.dispose();
    _location.dispose();
    _sizeM2.dispose();
    _rentPerMonth.dispose();
    _rentPerDay.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    super.dispose();
  }

  void _save() {
    final sizeM2 = int.tryParse(_sizeM2.text) ?? 0;
    final rentPerMonth = double.tryParse(_rentPerMonth.text) ?? 0;
    final rentPerDay = double.tryParse(_rentPerDay.text) ?? 0;
    final bedrooms = int.tryParse(_bedrooms.text) ?? 1;
    final bathrooms = int.tryParse(_bathrooms.text) ?? 1;

    if (_number.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter apartment number')),
      );
      return;
    }

    final e = widget.existing;
    final model = ApartmentModel(
      apartmentId: e?.apartmentId ?? 0,
      buildingId: widget.buildingId,
      typeId: 1, // Default type
      sizeM2: sizeM2,
      rentPricePerMonth: rentPerMonth,
      rentPricePerDay: rentPerDay,
      isAvailable: _isAvailable,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      hasBalcony: _hasBalcony,
      furnished: _furnished,
      hasInternet: _hasInternet,
      parking: _parking,
      elevator: _elevator,
      number: _number.text.trim(),
      location: _location.text.trim(),
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Apartment' : 'Add Apartment'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _number,
            decoration: const InputDecoration(
              labelText: 'Apartment Number',
              prefixIcon: Icon(Icons.tag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location / Floor',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sizeM2,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Size (m²)',
              prefixIcon: Icon(Icons.square_foot_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rentPerMonth,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rent per Month',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rentPerDay,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rent per Day',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bedrooms,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bedrooms',
                    prefixIcon: Icon(Icons.bedroom_parent_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _bathrooms,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bathrooms',
                    prefixIcon: Icon(Icons.bathroom_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Features', style: Theme.of(context).textTheme.titleSmall),
          CheckboxListTile(
            title: const Text('Available'),
            value: _isAvailable,
            onChanged: (value) => setState(() => _isAvailable = value ?? true),
          ),
          CheckboxListTile(
            title: const Text('Has Balcony'),
            value: _hasBalcony,
            onChanged: (value) => setState(() => _hasBalcony = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Furnished'),
            value: _furnished,
            onChanged: (value) => setState(() => _furnished = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Internet'),
            value: _hasInternet,
            onChanged: (value) => setState(() => _hasInternet = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Parking'),
            value: _parking,
            onChanged: (value) => setState(() => _parking = value ?? false),
          ),
          CheckboxListTile(
            title: const Text('Elevator'),
            value: _elevator,
            onChanged: (value) => setState(() => _elevator = value ?? false),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: Text(isEdit ? 'Update Apartment' : 'Add Apartment'),
          ),
        ],
      ),
    );
  }
}