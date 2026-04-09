import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';

class ApartmentFormScreen extends StatefulWidget {
  const ApartmentFormScreen({super.key, this.existing});

  final ApartmentModel? existing;

  @override
  State<ApartmentFormScreen> createState() => _ApartmentFormScreenState();
}

class _ApartmentFormScreenState extends State<ApartmentFormScreen> {
  late final TextEditingController _number;
  late final TextEditingController _location;
  late final TextEditingController _rent;
  late final TextEditingController _bedrooms;
  late final TextEditingController _bathrooms;
  late bool _occupied;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _number = TextEditingController(text: e?.number ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _rent = TextEditingController(
      text: e != null ? e.rent.toStringAsFixed(0) : '',
    );
    _bedrooms = TextEditingController(
      text: e != null ? e.bedrooms.toString() : '',
    );
    _bathrooms = TextEditingController(
      text: e != null ? e.bathrooms.toString() : '',
    );
    _occupied = e?.isOccupied ?? false;
  }

  @override
  void dispose() {
    _number.dispose();
    _location.dispose();
    _rent.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    super.dispose();
  }

  void _save() {
    final rent = double.tryParse(_rent.text.replaceAll(',', '')) ?? 0;
    final beds = int.tryParse(_bedrooms.text) ?? 0;
    final baths = int.tryParse(_bathrooms.text) ?? 0;
    final e = widget.existing;
    final model = ApartmentModel(
      id: e?.id ?? 0,
      number: _number.text.trim(),
      location: _location.text.trim(),
      rent: rent,
      bedrooms: beds,
      bathrooms: baths,
      isOccupied: _occupied,
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
              labelText: 'Number',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rent,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Rent',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bedrooms,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bedrooms',
              prefixIcon: Icon(Icons.bed_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bathrooms,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Bathrooms',
              prefixIcon: Icon(Icons.bathtub_outlined),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Occupied'),
            value: _occupied,
            onChanged: (v) => setState(() => _occupied = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
