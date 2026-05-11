import 'package:flutter/material.dart';

/// Shared layout and empty-state pieces for consistent UX across the app.
class AppToolbarTitle extends StatelessWidget {
  const AppToolbarTitle({
    super.key,
    required this.title,
    this.erdHint,
  });

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
