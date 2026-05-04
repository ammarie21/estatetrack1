import 'package:flutter/material.dart';

import 'package:estatetrack1/data/mock_auth_repository.dart';
import 'package:estatetrack1/models/account_model.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  State<AdminAccountsScreen> createState() => _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends State<AdminAccountsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AccountModel> get _filteredAccounts {
    final query = _searchController.text.trim().toLowerCase();
    final accounts = MockAuthRepository.instance.accounts;
    if (query.isEmpty) return accounts;
    return accounts
        .where(
          (a) =>
      a.name.toLowerCase().contains(query) ||
          a.email.toLowerCase().contains(query) ||
          a.phone.contains(query) ||
          a.role.toLowerCase().contains(query),
    )
        .toList();
  }

  Future<void> _showAccountEditor({AccountModel? account}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: account?.name ?? '');
    final emailController = TextEditingController(text: account?.email ?? '');
    final phoneController = TextEditingController(text: account?.phone ?? '');
    final passwordController = TextEditingController();
    var role = account?.role ?? 'User';
    var isActive = account?.isActive ?? true;

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
                        account == null ? 'Create Account' : 'Edit Account',
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
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Invalid email' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'User', child: Text('User')),
                          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                        ],
                        onChanged: (value) {
                          setModalState(() => role = value ?? 'User');
                        },
                      ),
                      const SizedBox(height: 10),
                      if (account == null)
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration:
                          const InputDecoration(labelText: 'Initial Password'),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            return MockAuthRepository.instance
                                .validatePasswordRules(v);
                          },
                        ),
                      if (account != null)
                        SwitchListTile(
                          value: isActive,
                          onChanged: (value) =>
                              setModalState(() => isActive = value),
                          title: const Text('Active'),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            String? error;
                            if (account == null) {
                              error = MockAuthRepository.instance.createAccount(
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                password: passwordController.text,
                                role: role,
                              );
                            } else {
                              error = MockAuthRepository.instance.updateAccount(
                                id: account.id,
                                name: nameController.text,
                                email: emailController.text,
                                phone: phoneController.text,
                                role: role,
                                isActive: isActive,
                              );
                            }
                            if (error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error)),
                              );
                              return;
                            }
                            Navigator.of(context).pop();
                            setState(() {});
                          },
                          child:
                          Text(account == null ? 'Create Account' : 'Save Changes'),
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
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  Future<void> _resetPassword(AccountModel account) async {
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
                return MockAuthRepository.instance.validatePasswordRules(value);
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
      final error = MockAuthRepository.instance.resetPassword(
        id: account.id,
        newPassword: controller.text,
      );
      if (!mounted) {
        controller.dispose();
        return;
      }
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully.')),
        );
      }
    }
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _filteredAccounts;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search accounts',
                    prefixIcon: Icon(Icons.search),
                  ),
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
          child: ListView.separated(
            itemCount: accounts.length,
            separatorBuilder: (_, index) => const Divider(height: 0),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(account.role == 'Admin' ? 'A' : 'U'),
                ),
                title: Text(account.name),
                subtitle: Text(
                  '${account.email}\n${account.phone} - ${account.role} - ${account.isActive ? 'Active' : 'Inactive'}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showAccountEditor(account: account);
                    } else if (value == 'reset') {
                      _resetPassword(account);
                    } else if (value == 'toggle') {
                      final error = MockAuthRepository.instance.updateAccount(
                        id: account.id,
                        name: account.name,
                        email: account.email,
                        phone: account.phone,
                        role: account.role,
                        isActive: !account.isActive,
                      );
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      } else {
                        setState(() {});
                      }
                    } else if (value == 'delete') {
                      MockAuthRepository.instance.deleteAccount(account.id);
                      setState(() {});
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'reset',
                      child: Text('Reset Password'),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(account.isActive ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
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