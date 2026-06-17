import 'package:flutter/material.dart';

import 'package:estatetrack1/data/estate_api.dart';
import 'package:estatetrack1/models/user_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/deferred_delete.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key, this.initialUsers});

  final List<UserModel>? initialUsers;

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final seeded = widget.initialUsers;
    if (seeded != null && seeded.isNotEmpty) {
      _users = List<UserModel>.from(seeded);
      _loading = false;
    } else {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await EstateApi.instance.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _confirmDeleteUser(UserModel user) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete user?',
      message: 'Remove ${user.name} (UserID ${user.userId}) from the backend?',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final backup = List<UserModel>.from(_users);
    try {
      await deferredDelete(
        context: context,
        message: '${user.name} removed',
        onRemove: () {
          setState(() {
            _users.removeWhere((x) => x.userId == user.userId);
          });
        },
        onRestore: () => setState(() => _users = backup),
        commit: () => EstateApi.instance.deleteUser(user.userId),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, e.message);
    }
  }

  List<UserModel> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _users;
    return _users
        .where(
          (u) =>
              u.userId.toString().contains(query) ||
              u.name.toLowerCase().contains(query) ||
              u.phone.contains(query),
        )
        .toList();
  }

  int _nextUserId() {
    if (_users.isEmpty) return 1;
    return _users.map((e) => e.userId).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> _showAccountEditor({UserModel? user}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final passwordController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user == null ? 'Create User' : 'Edit User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: user == null
                              ? 'Initial Password'
                              : 'New Password (leave blank to keep current)',
                        ),
                        validator: (v) {
                          if (user == null && (v == null || v.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            try {
                              final model = UserModel(
                                userId: user?.userId ?? _nextUserId(),
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                password: passwordController.text.isEmpty
                                    ? (user?.password ?? '')
                                    : passwordController.text,
                              );
                              final saved = user == null
                                  ? await EstateApi.instance.createUser(model)
                                  : await EstateApi.instance.updateUser(model);
                              if (!mounted) return;
                              setState(() {
                                if (user == null) {
                                  _users.add(saved);
                                } else {
                                  final i = _users.indexWhere(
                                    (x) => x.userId == user.userId,
                                  );
                                  if (i >= 0) _users[i] = saved;
                                }
                              });
                              if (context.mounted) Navigator.of(context).pop();
                              if (!mounted) return;
                              AppSnackbars.success(
                                this.context,
                                user == null ? 'User created' : 'User updated',
                              );
                            } on ApiException catch (e) {
                              if (!mounted) return;
                              AppSnackbars.error(this.context, e.message);
                            }
                          },
                          child: Text(
                            user == null ? 'Create User' : 'Save Changes',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  Future<void> _resetPassword(UserModel user) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (shouldSave == true) {
      try {
        final saved = await EstateApi.instance.updateUser(
          user.copyWith(password: controller.text),
        );
        if (!mounted) return;
        setState(() {
          final i = _users.indexWhere((x) => x.userId == user.userId);
          if (i >= 0) _users[i] = saved;
        });
        AppSnackbars.success(context, 'Password reset successfully.');
      } on ApiException catch (e) {
        if (!mounted) return;
        AppSnackbars.error(context, e.message);
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final users = _filteredUsers;
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return AppEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Could not load accounts',
        message: _error!,
        actionLabel: 'Retry',
        onAction: _loadUsers,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Search accounts',
                  padding: EdgeInsets.zero,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showAccountEditor(),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Expanded(
          child: users.isEmpty
              ? const AppEmptyState(
                  icon: Icons.manage_accounts_outlined,
                  title: 'No matching accounts',
                  message: 'Try a different name, phone number, or UserID.',
                )
              : ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, index) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(user.userId.toString()),
                      ),
                      title: Text(user.name),
                      subtitle: Text(
                        'Phone: ${user.phone}\nBackend UserID: ${user.userId}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showAccountEditor(user: user);
                          } else if (value == 'reset') {
                            _resetPassword(user);
                          } else if (value == 'delete') {
                            await _confirmDeleteUser(user);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'reset',
                            child: Text('Reset Password'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
