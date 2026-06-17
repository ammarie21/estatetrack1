import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/navigation/shell_navigation.dart';
import 'package:estatetrack1/theme/app_semantic_colors.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_period.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.apartments,
    required this.customers,
    required this.bookings,
    required this.returns,
    required this.contracts,
    required this.rentalTransactions,
    required this.maintenance,
    this.onRefresh,
    this.onAttentionTap,
  });

  final List<ApartmentModel> apartments;
  final List<CustomerModel> customers;
  final List<RentalBookingModel> bookings;
  final List<ApartmentReturnModel> returns;
  final List<ContractModel> contracts;
  final List<RentalTransactionModel> rentalTransactions;
  final List<MaintenanceModel> maintenance;
  final Future<void> Function()? onRefresh;
  final void Function(DashboardAction action)? onAttentionTap;

  Widget _buildRevenueSparkline(Color color, List<RevenueMonthPoint> points) {
    if (points.every((p) => p.revenue <= 0)) {
      return SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'No revenue trend yet',
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    final maxY =
        points.fold(0.0, (m, p) => p.revenue > m ? p.revenue : m) * 1.2;

    return SizedBox(
      height: 56,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 100 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].revenue),
              ],
              isCurved: true,
              color: color,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();

    final totalApartments = apartments.length;
    final occupiedCount = apartments.where((a) => !a.isAvailable).length;
    final availCount = totalApartments - occupiedCount;
    final occupancyPct = totalApartments == 0
        ? 0.0
        : (occupiedCount / totalApartments * 100);

    final activeContracts = contracts.where((c) => c.status == 'Active').length;
    final rentCollected = rentalTransactions.fold(
      0.0,
      (sum, x) => sum + x.paidInitialTotalDueAmount,
    );
    final maintenanceCost = maintenance.fold(0.0, (sum, m) => sum + m.cost);
    final outstanding = rentalTransactions.fold(
      0.0,
      (sum, x) => sum + x.totalRemaining,
    );
    final netPosition = rentCollected - maintenanceCost;

    final endingSoon = contracts.where((c) {
      if (c.status != 'Active') return false;
      final days = c.endDate.difference(now).inDays;
      return days >= 0 && days <= 30;
    }).length;

    final unpaidCount = rentalTransactions
        .where(
          (t) =>
              t.transactionStatus == 'Pending' ||
              t.transactionStatus == 'Partial',
        )
        .length;

    final revenueTrend = computeRevenueTrend(
      ReportAnalyticsInput(
        transactions: rentalTransactions,
        apartments: apartments,
        buildings: const [],
        customers: customers,
        bookings: bookings,
        contracts: contracts,
        maintenance: maintenance,
        period: reportPeriodRange('This Year'),
      ),
      months: 6,
    );

    final attention =
        <
          ({
            String title,
            String detail,
            IconData icon,
            AppChipTone tone,
            DashboardAction action,
          })
        >[
          if (availCount > 0)
            (
              title: '$availCount vacant units',
              detail: 'Available apartments ready to lease',
              icon: Icons.door_front_door_outlined,
              tone: AppChipTone.neutral,
              action: DashboardAction.vacantUnits,
            ),
          if (endingSoon > 0)
            (
              title: '$endingSoon leases ending soon',
              detail: 'Active agreements ending within 30 days',
              icon: Icons.event_busy_outlined,
              tone: AppChipTone.warning,
              action: DashboardAction.leasesEnding,
            ),
          if (unpaidCount > 0)
            (
              title: '$unpaidCount unpaid bookings',
              detail: 'Pending or partial payments on rental bookings',
              icon: Icons.payments_outlined,
              tone: AppChipTone.warning,
              action: DashboardAction.unpaidBookings,
            ),
          if (outstanding > 0)
            (
              title: '\$${outstanding.toStringAsFixed(0)} outstanding',
              detail: 'Remaining balances across booking payments',
              icon: Icons.account_balance_wallet_outlined,
              tone: AppChipTone.negative,
              action: DashboardAction.outstandingBalances,
            ),
        ];

    final stats = [
      AppMetricCard(
        label: 'Occupancy',
        value: '${occupancyPct.toStringAsFixed(0)}%',
        subtitle: '$occupiedCount occupied · $availCount vacant',
        icon: Icons.pie_chart_outline_rounded,
        accent: semantic.info,
      ),
      AppMetricCard(
        label: 'Active leases',
        value: '$activeContracts',
        subtitle: 'Derived from bookings + returns',
        icon: Icons.event_available_outlined,
        accent: scheme.primary,
      ),
      AppMetricCard(
        label: 'Rent collected',
        value: '\$${rentCollected.toStringAsFixed(0)}',
        subtitle: 'From booking rentalPrice fields',
        icon: Icons.account_balance_wallet_outlined,
        accent: semantic.success,
      ),
      AppMetricCard(
        label: 'Outstanding',
        value: '\$${outstanding.toStringAsFixed(0)}',
        subtitle: 'Unpaid booking balances',
        icon: Icons.pending_actions_outlined,
        accent: semantic.warning,
      ),
      AppMetricCard(
        label: 'Operating costs',
        value: '\$${maintenanceCost.toStringAsFixed(0)}',
        subtitle: 'Backend maintenance costs',
        icon: Icons.receipt_long_outlined,
        accent: semantic.danger,
      ),
      AppMetricCard(
        label: 'Net position',
        value: '\$${netPosition.toStringAsFixed(0)}',
        subtitle: 'Collected rent minus costs',
        icon: Icons.trending_up_rounded,
        accent: netPosition >= 0 ? semantic.success : semantic.danger,
      ),
      AppMetricCard(
        label: 'Customers',
        value: '${customers.length}',
        subtitle: 'Backend customer records',
        icon: Icons.people_outline_rounded,
        accent: scheme.secondary,
      ),
      AppMetricCard(
        label: 'Returns',
        value: '${returns.length}',
        subtitle: 'Check-outs recorded in backend',
        icon: Icons.logout_rounded,
        accent: scheme.secondary,
      ),
    ];

    final body = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio overview',
                  style: t.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Backend-backed inventory and bookings, with payments and contracts derived client-side.',
                  style: t.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
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
                                    '${occupancyPct.toStringAsFixed(0)}% occupied',
                                    style: t.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '$totalApartments units · $activeContracts active leases',
                                    style: t.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${rentCollected.toStringAsFixed(0)}',
                                  style: t.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: scheme.primary,
                                  ),
                                ),
                                Text(
                                  'collected',
                                  style: t.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '6-month revenue trend',
                          style: t.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildRevenueSparkline(scheme.primary, revenueTrend),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (attention.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: AppSectionHeader(
                title: 'Needs attention',
                subtitle: 'Actionable items from loaded backend data',
              ),
            ),
          ),
        if (attention.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList.separated(
              itemCount: attention.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = attention[index];
                return Card(
                  child: ListTile(
                    leading: Icon(item.icon, color: scheme.primary),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(item.detail),
                    trailing: AppStatusChip(label: 'Review', tone: item.tone),
                    onTap: onAttentionTap == null
                        ? null
                        : () => onAttentionTap!(item.action),
                  ),
                );
              },
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(
            child: AppSectionHeader(
              title: 'Key metrics',
              subtitle: 'All figures from the current API snapshot',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, kAppListBottomInset),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => stats[index],
              childCount: stats.length,
            ),
          ),
        ),
      ],
    );

    if (onRefresh == null) {
      return SafeArea(child: body);
    }
    return SafeArea(
      child: RefreshIndicator(onRefresh: onRefresh!, child: body),
    );
  }
}
