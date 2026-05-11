import 'package:flutter/material.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.apartments,
    required this.customers,
    required this.bookings,
    required this.returns,
    required this.rentalTransactions,
    required this.expenses,
  });

  final List<ApartmentModel> apartments;
  final List<CustomerModel> customers;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final totalApartments = apartments.length;
    final totalCustomers = customers.length;
    final occupiedCount = apartments.where((a) => !a.isAvailable).length;
    final availCount = totalApartments - occupiedCount;
    final occupancyPct =
        totalApartments == 0 ? 0.0 : (occupiedCount / totalApartments * 100);

    final rentCollected = rentalTransactions.fold(
      0.0,
      (sum, x) => sum + x.paidInitialTotalDueAmount,
    );
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final stats = <_DashMetric>[
      _DashMetric(
        label: 'Apartments',
        value: '$totalApartments',
        subtitle: 'Inventory units',
        icon: Icons.apartment_rounded,
        accent: scheme.primary,
      ),
      _DashMetric(
        label: 'Customers',
        value: '$totalCustomers',
        subtitle: 'Tenant records',
        icon: Icons.people_outline_rounded,
        accent: scheme.secondary,
      ),
      _DashMetric(
        label: 'Occupancy',
        value: '${occupancyPct.toStringAsFixed(0)}%',
        subtitle: '$occupiedCount occupied · $availCount vacant',
        icon: Icons.pie_chart_outline_rounded,
        accent: scheme.tertiary,
      ),
      _DashMetric(
        label: 'Rental bookings',
        value: '${bookings.length}',
        subtitle: 'Active lease periods',
        icon: Icons.event_available_outlined,
        accent: scheme.primary,
      ),
      _DashMetric(
        label: 'Apartment returns',
        value: '${returns.length}',
        subtitle: 'Check-outs recorded',
        icon: Icons.logout_rounded,
        accent: scheme.secondary,
      ),
      _DashMetric(
        label: 'Rent collected',
        value: '\$${rentCollected.toStringAsFixed(0)}',
        subtitle: 'Sum of transaction payments',
        icon: Icons.account_balance_wallet_outlined,
        accent: Colors.green.shade700,
      ),
      _DashMetric(
        label: 'Expenses',
        value: '\$${totalExpenses.toStringAsFixed(0)}',
        subtitle: 'Operating costs',
        icon: Icons.receipt_long_outlined,
        accent: Colors.deepOrange.shade700,
      ),
    ];

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today\'s snapshot',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Figures map to your ERD: Apartment, Customer, Rental Booking, '
                    'Apartment Return, Rental Transaction.',
                    style: t.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = stats[index];
                  return _MetricTile(metric: s);
                },
                childCount: stats.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashMetric {
  const _DashMetric({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _DashMetric metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: metric.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(metric.icon, color: metric.accent, size: 22),
            ),
            const Spacer(),
            Text(
              metric.value,
              style: t.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              style: t.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Text(
              metric.subtitle,
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
