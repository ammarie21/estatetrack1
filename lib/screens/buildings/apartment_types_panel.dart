import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/ui/app_components.dart';

class ApartmentTypesPanel extends StatefulWidget {
  const ApartmentTypesPanel({
    super.key,
    this.initialTypes = const [],
    this.onTypesChanged,
  });

  final List<ApartmentTypeModel> initialTypes;
  final void Function(List<ApartmentTypeModel>)? onTypesChanged;

  @override
  State<ApartmentTypesPanel> createState() => ApartmentTypesPanelState();
}

class ApartmentTypesPanelState extends State<ApartmentTypesPanel> {
  List<ApartmentTypeModel> _types = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialTypes.isNotEmpty) {
      _types = List.from(widget.initialTypes);
      _loading = false;
    } else {
      reload();
    }
  }

  @override
  void didUpdateWidget(covariant ApartmentTypesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTypes != oldWidget.initialTypes &&
        widget.initialTypes.isNotEmpty) {
      _types = List.from(widget.initialTypes);
      _loading = false;
      _error = null;
    }
  }

  Future<void> reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final types = await EstateApi.instance.getApartmentTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _loading = false;
      });
      widget.onTypesChanged?.call(types);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> openCreateForm() => _openForm();

  Future<void> _openForm({ApartmentTypeModel? existing}) async {
    final controller = TextEditingController(
      text: existing?.apartmentType ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'New apartment type' : 'Edit apartment type',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Type name',
            hintText: 'e.g. Studio, Duplex',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || name == null || name.isEmpty) return;

    try {
      if (existing == null) {
        await EstateApi.instance.createApartmentType(
          ApartmentTypeModel(typeId: 0, apartmentType: name),
        );
      } else {
        await EstateApi.instance.updateApartmentType(
          existing.copyWith(apartmentType: name),
        );
      }
      await reload();
      if (!mounted) return;
      AppSnackbars.success(
        context,
        existing == null ? 'Apartment type added' : 'Apartment type updated',
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Type save failed: ${e.message}');
    }
  }

  Future<void> _confirmDelete(ApartmentTypeModel type) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete apartment type?',
      message:
          'Remove "${type.apartmentType}"? Apartments using this type may fail validation.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    try {
      await EstateApi.instance.deleteApartmentType(type.typeId);
      await reload();
      if (!mounted) return;
      AppSnackbars.success(context, 'Apartment type deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, 'Type delete failed: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppEmptyState(
        icon: Icons.error_outline,
        title: 'Could not load apartment types',
        message: _error!,
        actionLabel: 'Retry',
        onAction: reload,
      );
    }
    if (_types.isEmpty) {
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: 'No apartment types',
        message:
            'Create types here so apartment forms can classify units correctly.',
        actionLabel: 'Add type',
        onAction: openCreateForm,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, kAppListBottomInset),
      itemCount: _types.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final type = _types[index];
        return Card(
          child: ListTile(
            title: Text(
              type.apartmentType,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('Backend type ID ${type.typeId}'),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _openForm(existing: type);
                } else if (value == 'delete') {
                  _confirmDelete(type);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
