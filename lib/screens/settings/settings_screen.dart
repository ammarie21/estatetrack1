import 'package:flutter/material.dart';

import 'package:estatetrack1/config/api_config.dart';
import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/notifications/lease_reminder_service.dart';
import 'package:estatetrack1/settings/app_settings.dart';
import 'package:estatetrack1/ui/app_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.account,
    required this.isLoadingFromApi,
    this.apiError,
    this.lastRefreshed,
    this.recordCounts,
    this.onRefresh,
    this.onLogout,
  });

  final AccountModel account;
  final bool isLoadingFromApi;
  final String? apiError;
  final DateTime? lastRefreshed;
  final BackendRecordCounts? recordCounts;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onLogout;

  static const appVersion = '1.0.0';

  AppBackendSyncState get _syncState {
    if (isLoadingFromApi) return AppBackendSyncState.loading;
    if (apiError != null) return AppBackendSyncState.error;
    return AppBackendSyncState.online;
  }

  String _formatTimestamp(DateTime? time) {
    if (time == null) return 'Not refreshed yet';
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} at $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final settings = AppSettings.instance;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kAppListBottomInset),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    account.isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : Icons.person_outline,
                    size: 32,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppStatusChip(
                        label: account.role,
                        tone: account.isAdmin
                            ? AppChipTone.positive
                            : AppChipTone.neutral,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(title: 'Account'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _InfoTile(
                icon: Icons.email_outlined,
                label: 'Email',
                value: account.email.isNotEmpty ? account.email : '—',
              ),
              const Divider(height: 1, indent: 56),
              _InfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: account.phone.isNotEmpty ? account.phone : '—',
              ),
              const Divider(height: 1, indent: 56),
              _InfoTile(
                icon: Icons.badge_outlined,
                label: 'User ID',
                value: account.id,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(
          title: 'Backend connection',
          subtitle: 'API endpoint and sync status',
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API base URL',
                            style: t.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            AppSettings.instance.effectiveApiBaseUrl,
                            style: t.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit API URL',
                      onPressed: () => _editApiUrl(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    AppBackendStatusChip(
                      state: _syncState,
                      lastRefreshed: lastRefreshed,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Last refresh: ${_formatTimestamp(lastRefreshed)}',
                  style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (apiError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    apiError!,
                    style: t.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
                if (recordCounts != null) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'Synced records',
                    style: t.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _CountChip(
                        label: 'Customers',
                        value: recordCounts!.customers,
                      ),
                      _CountChip(
                        label: 'Buildings',
                        value: recordCounts!.buildings,
                      ),
                      _CountChip(
                        label: 'Apartments',
                        value: recordCounts!.apartments,
                      ),
                      _CountChip(
                        label: 'Bookings',
                        value: recordCounts!.bookings,
                      ),
                      _CountChip(
                        label: 'Returns',
                        value: recordCounts!.returns,
                      ),
                      _CountChip(
                        label: 'Maintenance',
                        value: recordCounts!.maintenance,
                      ),
                      _CountChip(label: 'Staff', value: recordCounts!.staff),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${recordCounts!.total} total rows loaded from backend',
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (onRefresh != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoadingFromApi ? null : () => onRefresh!(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh data now'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(title: 'Appearance'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) {
                    AppSettings.instance.setThemeMode(selection.first);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(title: 'Notifications'),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: AppSettings.instance,
          builder: (context, _) {
            return Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.event_available_outlined),
                title: const Text('Lease expiry reminders'),
                subtitle: const Text(
                  'Local alerts for active agreements ending within 7 days',
                ),
                value: AppSettings.instance.leaseRemindersEnabled,
                onChanged: (enabled) async {
                  await AppSettings.instance.setLeaseRemindersEnabled(enabled);
                  if (!enabled) {
                    await LeaseReminderService.instance.clearReminders();
                  }
                },
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const AppSectionHeader(title: 'About'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.home_work_outlined),
                title: Text('EstateTrack'),
                subtitle: Text(
                  'Apartment rental management with backend-backed inventory, bookings, and payments.',
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: Text(
                  appVersion,
                  style: t.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (onLogout != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.errorContainer,
                foregroundColor: scheme.onErrorContainer,
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editApiUrl(BuildContext context) async {
    final controller = TextEditingController(
      text: AppSettings.instance.effectiveApiBaseUrl,
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API base URL'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Backend URL',
            hintText: ApiConfig.defaultBaseUrl,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await AppSettings.instance.resetApiBaseUrl();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Reset default'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      final value = controller.text.trim();
      if (value.isNotEmpty && value != ApiConfig.defaultBaseUrl) {
        await AppSettings.instance.setApiBaseUrl(value);
      } else if (value.isEmpty || value == ApiConfig.defaultBaseUrl) {
        await AppSettings.instance.resetApiBaseUrl();
      }
    }
    controller.dispose();
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
