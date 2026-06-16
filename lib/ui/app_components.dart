import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Extra bottom padding so list content clears FAB + bottom navigation.
const double kAppListBottomInset = 96;

/// Shared layout and empty-state pieces for consistent UX across the app.
class AppToolbarTitle extends StatelessWidget {
  const AppToolbarTitle({super.key, required this.title, this.erdHint});

  final String title;

  /// Short line tying the screen to the data model (optional).
  final String? erdHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: titleStyle),
        if (erdHint != null && erdHint!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            erdHint!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: scheme.primary.withValues(alpha: 0.45)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class AppFlowBanner extends StatelessWidget {
  const AppFlowBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact status chip for list rows (e.g. transaction or lease status).
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.label,
    this.tone = AppChipTone.neutral,
  });

  final String label;
  final AppChipTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late Color bg;
    late Color fg;
    switch (tone) {
      case AppChipTone.positive:
        bg = Colors.green.withValues(alpha: 0.15);
        fg = Colors.green.shade800;
        break;
      case AppChipTone.warning:
        bg = Colors.orange.withValues(alpha: 0.18);
        fg = Colors.orange.shade900;
        break;
      case AppChipTone.negative:
        bg = scheme.errorContainer.withValues(alpha: 0.6);
        fg = scheme.onErrorContainer;
        break;
      case AppChipTone.neutral:
        bg = scheme.surfaceContainerHighest.withValues(alpha: 0.85);
        fg = scheme.onSurfaceVariant;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

enum AppChipTone { neutral, positive, warning, negative }

AppChipTone chipToneForBookingStatus(String status) {
  switch (status) {
    case 'Paid':
    case 'Closed':
      return AppChipTone.positive;
    case 'Partial':
    case 'Pending':
      return AppChipTone.warning;
    case 'Refunded':
      return AppChipTone.neutral;
    default:
      return AppChipTone.neutral;
  }
}

AppChipTone chipToneForLeaseStatus(String status) {
  switch (status) {
    case 'Active':
      return AppChipTone.positive;
    case 'Expired':
      return AppChipTone.warning;
    case 'Terminated':
      return AppChipTone.negative;
    default:
      return AppChipTone.neutral;
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = accent ?? scheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const Spacer(),
            Text(
              value,
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: t.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
    this.controller,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 4),
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
    );
  }
}

class AppFilterChips extends StatelessWidget {
  const AppFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onSelected(option),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AppInlineError extends StatelessWidget {
  const AppInlineError({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      borderRadius: BorderRadius.circular(compact ? 12 : 16),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: compact ? 13 : 14,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

enum AppBackendSyncState { loading, online, error }

class AppBackendStatusChip extends StatelessWidget {
  const AppBackendStatusChip({
    super.key,
    required this.state,
    this.lastRefreshed,
  });

  final AppBackendSyncState state;
  final DateTime? lastRefreshed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late Color bg;
    late Color fg;
    late IconData icon;
    late String label;

    switch (state) {
      case AppBackendSyncState.loading:
        bg = scheme.surfaceContainerHighest;
        fg = scheme.onSurfaceVariant;
        icon = Icons.sync_rounded;
        label = 'Syncing';
        break;
      case AppBackendSyncState.online:
        bg = scheme.primaryContainer.withValues(alpha: 0.7);
        fg = scheme.onPrimaryContainer;
        icon = Icons.cloud_done_outlined;
        label = _lastRefreshedLabel();
        break;
      case AppBackendSyncState.error:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        icon = Icons.cloud_off_outlined;
        label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  String _lastRefreshedLabel() {
    if (lastRefreshed == null) return 'Synced';
    final diff = DateTime.now().difference(lastRefreshed!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class AppSnackbars {
  static void success(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.primary,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  static void error(BuildContext context, String message) {
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.error,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> copyTextToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  AppSnackbars.success(context, 'Copied to clipboard');
}

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
    this.icon = Icons.calendar_today_outlined,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final Future<void> Function() onPick;
  final IconData icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = date == null
        ? 'Select $label'
        : '$label: ${date!.toIso8601String().split('T').first}';
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: date == null ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),
            Text(
              'Change',
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppFormActions extends StatelessWidget {
  const AppFormActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
    this.isSaving = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;
  final String cancelLabel;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isSaving ? null : onCancel,
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
