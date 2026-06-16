import 'package:flutter/material.dart';

import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.existing});

  final CustomerModel? existing;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _idNumber;
  late final TextEditingController _apartment;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;

  bool get _hasDerivedRentalInfo =>
      widget.existing != null &&
      ((widget.existing!.apartment?.isNotEmpty ?? false) ||
          (widget.existing!.startDate?.isNotEmpty ?? false) ||
          (widget.existing!.endDate?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _idNumber = TextEditingController(
      text: e?.idNumber ?? e?.nationalNum ?? '',
    );
    _apartment = TextEditingController(text: e?.apartment ?? '');
    _startDate = TextEditingController(text: e?.startDate ?? '');
    _endDate = TextEditingController(text: e?.endDate ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _idNumber.dispose();
    _apartment.dispose();
    _startDate.dispose();
    _endDate.dispose();
    super.dispose();
  }

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Name is required';
    if (trimmed.length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validatePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Phone is required';
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return 'Enter a valid phone number';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      AppSnackbars.error(context, 'Please fix the highlighted fields');
      return;
    }

    final e = widget.existing;
    final model = CustomerModel(
      customerId: e?.customerId ?? 0,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      nationalNum: _idNumber.text.trim(),
      numberOfRentedApartments: e?.numberOfRentedApartments ?? 0,
      idNumber: _idNumber.text.trim().isEmpty ? null : _idNumber.text.trim(),
      apartment: e?.apartment,
      startDate: e?.startDate,
      endDate: e?.endDate,
    );
    Navigator.of(context).pop(model);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Customer' : 'Add Customer')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_hasDerivedRentalInfo)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AppFlowBanner(
                  icon: Icons.info_outline,
                  text:
                      'Apartment and rental dates shown here come from bookings and are not saved on the customer record.',
                ),
              ),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) => _validateName(value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (value) => _validatePhone(value ?? ''),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _idNumber,
              decoration: const InputDecoration(
                labelText: 'National ID (optional)',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            if (_hasDerivedRentalInfo) ...[
              const SizedBox(height: 20),
              Text(
                'Derived from bookings',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _apartment,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Current apartment',
                  prefixIcon: Icon(Icons.apartment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startDate,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Booking start',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endDate,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Booking end',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
              ),
            ],
            const SizedBox(height: 28),
            AppFormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}
