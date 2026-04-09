import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    const metrics = [
      _Metric('Revenue', r'$42,500', Icons.trending_up_rounded),
      _Metric('Expenses', r'$9,200', Icons.trending_down_rounded),
      _Metric('Net Profit', r'$33,300', Icons.account_balance_wallet_outlined),
      _Metric('Occupancy Rate', '75%', Icons.pie_chart_outline_rounded),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Analytics overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...metrics.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: Icon(m.icon, color: scheme.onPrimaryContainer),
                    ),
                    title: Text(m.label),
                    trailing: Text(
                      m.value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Text(
                'Charts coming soon',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}
