import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/ui/app_components.dart';
import 'package:estatetrack1/utils/apartment_display.dart';
import 'package:estatetrack1/utils/report_analytics.dart';
import 'package:estatetrack1/utils/report_export.dart';
import 'package:estatetrack1/utils/report_period.dart';
import 'package:estatetrack1/utils/report_snapshot.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.rentalTransactions,
    required this.apartments,
    required this.buildings,
    required this.customers,
    required this.bookings,
    required this.contracts,
    required this.maintenance,
    this.onRefresh,
    this.onOpenOutstandingBooking,
    this.onOpenLeaseExpiry,
    this.onOpenCustomer,
  });

  final List<RentalTransactionModel> rentalTransactions;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;
  final List<CustomerModel> customers;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<MaintenanceModel> maintenance;
  final Future<void> Function()? onRefresh;
  final void Function(int bookingId, String status)? onOpenOutstandingBooking;
  final void Function(ContractModel contract)? onOpenLeaseExpiry;
  final void Function(int customerId)? onOpenCustomer;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'This Month';
  ReportPeriodRange? _customPeriod;

  final List<String> _periods = [
    'Last Week',
    'This Month',
    'This Quarter',
    'This Year',
    'Custom Range',
  ];

  ReportPeriodRange get _period =>
      _selectedPeriod == 'Custom Range' && _customPeriod != null
      ? _customPeriod!
      : reportPeriodRange(_selectedPeriod);

  String get _reportTitle =>
      _selectedPeriod == 'Custom Range' ? 'Custom Range' : _selectedPeriod;

  String _periodRangeLabel() => formatReportPeriodRange(_period);

  ReportSnapshot _buildSnapshot() => ReportSnapshot.compute(
    transactions: widget.rentalTransactions,
    apartments: widget.apartments,
    buildings: widget.buildings,
    customers: widget.customers,
    bookings: widget.bookings,
    contracts: widget.contracts,
    maintenance: widget.maintenance,
    period: _period,
  );

  Future<void> _copySummary(ReportSnapshot snapshot) async {
    final text = buildReportSummaryText(
      snapshot: snapshot,
      periodLabel: _reportTitle,
    );
    await copyTextToClipboard(context, text);
    if (!mounted) return;
    AppSnackbars.success(context, 'Report summary copied');
  }

  Future<void> _exportCsv(ReportSnapshot snapshot) async {
    final csv = buildReportCsv(
      input: snapshot.input,
      periodLabel: _reportTitle,
      period: _period,
      snapshot: snapshot,
    );
    await copyTextToClipboard(context, csv);
    if (!mounted) return;
    AppSnackbars.success(context, 'Report CSV copied to clipboard');
  }

  Future<void> _selectPeriod(String? value) async {
    if (value == null) return;
    if (value != 'Custom Range') {
      setState(() => _selectedPeriod = value);
      return;
    }
    await _pickCustomRange();
  }

  Future<void> _pickCustomRange() async {
    final initialRange = DateTimeRange(
      start: _customPeriod?.start ?? _period.start,
      end: _customPeriod?.end ?? _period.end,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedPeriod = 'Custom Range';
      _customPeriod = ReportPeriodRange(
        DateTime(picked.start.year, picked.start.month, picked.start.day),
        DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59),
      );
    });
  }

  Widget _buildRevenueExpenseChart(ColorScheme scheme, ReportSnapshot snap) {
    final revenue = snap.totalRevenue;
    final expenses = snap.totalMaintenance;
    if (revenue <= 0 && expenses <= 0) {
      return const SizedBox(
        height: 180,
        child: AppEmptyState(
          icon: Icons.bar_chart_outlined,
          title: 'No revenue or expense data',
          message: 'Record payments and maintenance in this period.',
        ),
      );
    }
    final maxY = (revenue > expenses ? revenue : expenses) * 1.25;

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY <= 0 ? 100 : maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                      return const Text('Revenue');
                    case 1:
                      return const Text('Expenses');
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: revenue,
                  color: scheme.primary,
                  width: 30,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: expenses,
                  color: scheme.error,
                  width: 30,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart({
    required ColorScheme scheme,
    required List<RevenueMonthPoint> points,
    required Color color,
    String emptyMessage = 'No trend data yet',
  }) {
    if (points.every((p) => p.revenue <= 0)) {
      return SizedBox(
        height: 180,
        child: AppEmptyState(
          icon: Icons.show_chart_outlined,
          title: emptyMessage,
          message: 'Data will appear once payments are recorded.',
        ),
      );
    }

    final maxY =
        points.fold(0.0, (m, p) => p.revenue > m ? p.revenue : m) * 1.2;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 0 ? 100 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 0 ? 25 : maxY / 4,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].revenue),
              ],
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyTrendChart(
    ColorScheme scheme,
    List<OccupancyMonthPoint> points,
  ) {
    if (points.isEmpty || points.every((p) => p.total == 0)) {
      return const SizedBox(
        height: 180,
        child: AppEmptyState(
          icon: Icons.pie_chart_outline_rounded,
          title: 'No occupancy data yet',
          message: 'Add apartments and bookings to see occupancy trends.',
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  if (value % 25 != 0) return const SizedBox.shrink();
                  return Text('${value.toInt()}%');
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < points.length; i++)
                  FlSpot(i.toDouble(), points[i].rate),
              ],
              isCurved: true,
              color: scheme.tertiary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: scheme.tertiary.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profitList(List<ProfitRow> rows, ColorScheme scheme) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.analytics_outlined,
        title: 'No profit data',
        message: 'Revenue and maintenance in this period will appear here.',
      );
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              title: Text(
                row.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Revenue \$${row.revenue.toStringAsFixed(0)} · '
                'Maintenance \$${row.maintenance.toStringAsFixed(0)}',
              ),
              trailing: Text(
                '\$${row.net.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: row.net >= 0 ? Colors.green.shade700 : scheme.error,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _labeledAmountList(List<LabeledAmount> rows, ColorScheme scheme) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.build_outlined,
        title: 'No maintenance costs',
        message: 'Maintenance logged in this period will appear here.',
      );
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              title: Text(
                row.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '\$${row.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.tertiary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  AppChipTone _leaseExpiryTone(int days) {
    if (days <= 7) return AppChipTone.negative;
    if (days <= 30) return AppChipTone.warning;
    return AppChipTone.neutral;
  }

  List<Widget> _cashCollectionChildren(
    ReportSnapshot snap,
    ColorScheme scheme,
  ) {
    return [
      AppMetricCard(
        label: 'Collection rate',
        value: '${snap.collectionRate.toStringAsFixed(0)}%',
        subtitle: 'Paid vs due in selected period',
        icon: Icons.percent_rounded,
        accent: snap.collectionRate >= 80
            ? Colors.green.shade700
            : Colors.amber.shade800,
      ),
      const AppSectionHeader(
        title: 'Outstanding balances',
        subtitle: 'Bookings with unpaid balances right now',
      ),
      if (snap.outstanding.isEmpty)
        const AppEmptyState(
          icon: Icons.check_circle_outline,
          title: 'All caught up',
          message: 'No bookings have outstanding balances.',
        )
      else
        ...snap.outstanding.map((row) {
          return Card(
            child: ListTile(
              onTap: widget.onOpenOutstandingBooking == null
                  ? null
                  : () => widget.onOpenOutstandingBooking!(
                      row.bookingId,
                      row.status,
                    ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  AppStatusChip(
                    label: row.status,
                    tone: chipToneForBookingStatus(row.status),
                  ),
                ],
              ),
              subtitle: Text(
                '${row.apartmentLabel}\n'
                'Booking #${row.bookingId} · ends ${row.endDate.toIso8601String().split('T').first}',
              ),
              isThreeLine: true,
              trailing: Text(
                '\$${row.remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.error,
                ),
              ),
              leading: widget.onOpenOutstandingBooking == null
                  ? null
                  : Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.primary,
                    ),
            ),
          );
        }),
    ];
  }

  List<Widget> _leaseExpiriesChildren(
    ReportSnapshot snap,
    ColorScheme scheme,
  ) {
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          AppStatusChip(
            label: '${snap.expiringWithin7} in 7 days',
            tone: snap.expiringWithin7 > 0
                ? AppChipTone.negative
                : AppChipTone.neutral,
          ),
          AppStatusChip(
            label: '${snap.expiringWithin30} in 30 days',
            tone: snap.expiringWithin30 > 0
                ? AppChipTone.warning
                : AppChipTone.neutral,
          ),
          AppStatusChip(
            label: '${snap.leaseExpiries.length} in 90 days',
            tone: AppChipTone.neutral,
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (snap.leaseExpiries.isEmpty)
        const AppEmptyState(
          icon: Icons.event_available_outlined,
          title: 'No upcoming expiries',
          message: 'No active leases end in the next 90 days.',
        )
      else
        ...snap.leaseExpiries.map((row) {
          return Card(
            child: ListTile(
              onTap: widget.onOpenLeaseExpiry == null
                  ? null
                  : () => widget.onOpenLeaseExpiry!(row.contract),
              title: Text(
                row.customerName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${row.apartmentLabel}\n'
                'Ends ${row.contract.endDate.toIso8601String().split('T').first}',
              ),
              isThreeLine: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppStatusChip(
                    label: row.daysUntilEnd == 0
                        ? 'Today'
                        : '${row.daysUntilEnd}d left',
                    tone: _leaseExpiryTone(row.daysUntilEnd),
                  ),
                  if (widget.onOpenLeaseExpiry != null) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.handshake_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
    ];
  }

  List<Widget> _trendsChildren(ReportSnapshot snap, ColorScheme scheme) {
    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue trend',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildTrendChart(
                scheme: scheme,
                points: snap.revenueTrend,
                color: scheme.primary,
                emptyMessage: 'No revenue recorded in the last 6 months',
              ),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Occupancy trend',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildOccupancyTrendChart(scheme, snap.occupancyTrend),
            ],
          ),
        ),
      ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue vs maintenance expenses',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildRevenueExpenseChart(scheme, snap),
            ],
          ),
        ),
      ),
    ];
  }

  void _openReportDetail({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: children,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _reportDrillCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: accent.withValues(alpha: 0.14),
                foregroundColor: accent,
                child: Icon(icon),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _maintenanceApartmentLabel(MaintenanceModel maintenance) {
    final aptId = parseMaintenanceApartmentId(maintenance.apartmentId);
    if (aptId == null) return 'Apartment ${maintenance.apartmentId}';
    return apartmentDisplayLabelById(
      aptId,
      widget.apartments,
      widget.buildings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final snap = _buildSnapshot();
    final periodCompare = snap.periodComparison;
    final periodDeltaLabel =
        '${periodCompare.changePct >= 0 ? '+' : ''}${periodCompare.changePct.toStringAsFixed(0)}%';

    void openCashCollection() => _openReportDetail(
      title: 'Cash collection',
      subtitle: _periodRangeLabel(),
      children: _cashCollectionChildren(snap, scheme),
    );

    void openTrends() => _openReportDetail(
      title: 'Trends',
      subtitle: 'Rolling 6 months',
      children: _trendsChildren(snap, scheme),
    );

    final body = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: scheme.primaryContainer.withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports & analytics',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _periodRangeLabel(),
                    style: t.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppStatusChip(
                        label: 'Revenue $periodDeltaLabel vs prior period',
                        tone: periodCompare.changePct >= 0
                            ? AppChipTone.positive
                            : AppChipTone.negative,
                      ),
                      if (snap.expiringWithin7 > 0)
                        AppStatusChip(
                          label: '${snap.expiringWithin7} leases ≤ 7 days',
                          tone: AppChipTone.negative,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedPeriod,
                          decoration: const InputDecoration(
                            labelText: 'Period',
                            isDense: true,
                          ),
                          items: _periods
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: _selectPeriod,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (_selectedPeriod == 'Custom Range') ...[
                        IconButton.filledTonal(
                          tooltip: 'Change custom range',
                          onPressed: _pickCustomRange,
                          icon: const Icon(Icons.date_range_outlined),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton.filledTonal(
                        tooltip: 'Copy summary',
                        onPressed: () => _copySummary(snap),
                        icon: const Icon(Icons.copy_all_outlined),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Export CSV',
                        onPressed: () => _exportCsv(snap),
                        icon: const Icon(Icons.table_chart_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AppFlowBanner(
            icon: Icons.analytics_outlined,
            text:
                'Revenue comes from booking payments. Expenses use backend maintenance. Trends use the last 6 months.',
          ),
          const AppSectionHeader(
            title: 'Key metrics',
            subtitle: 'Period-scoped revenue, collection, and vacancy',
          ),
          if (snap.paymentStatusCounts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: snap.paymentStatusCounts.entries.map((entry) {
                return AppStatusChip(
                  label: '${entry.key}: ${entry.value}',
                  tone: chipToneForBookingStatus(entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              AppMetricCard(
                label: 'Revenue',
                value: '\$${snap.totalRevenue.toStringAsFixed(0)}',
                subtitle: 'Booking payments in period',
                icon: Icons.attach_money,
                accent: scheme.primary,
                onTap: openTrends,
              ),
              AppMetricCard(
                label: 'Costs',
                value: '\$${snap.totalMaintenance.toStringAsFixed(0)}',
                subtitle: 'Maintenance in period',
                icon: Icons.receipt_long_outlined,
                accent: scheme.error,
                onTap: openTrends,
              ),
              AppMetricCard(
                label: 'Net',
                value: '\$${snap.netProfit.toStringAsFixed(0)}',
                subtitle: _selectedPeriod,
                icon: Icons.trending_up_rounded,
                accent: snap.netProfit >= 0 ? Colors.green.shade700 : scheme.error,
                onTap: openTrends,
              ),
              AppMetricCard(
                label: 'Outstanding',
                value: '\$${snap.outstandingTotal.toStringAsFixed(0)}',
                subtitle: '${snap.outstanding.length} unpaid bookings',
                icon: Icons.pending_actions_outlined,
                accent: Colors.amber.shade800,
                onTap: openCashCollection,
              ),
              AppMetricCard(
                label: 'Collection rate',
                value: '${snap.collectionRate.toStringAsFixed(0)}%',
                subtitle: 'Paid vs due in period',
                icon: Icons.percent_rounded,
                accent: snap.collectionRate >= 80
                    ? Colors.green.shade700
                    : Colors.amber.shade800,
                onTap: openCashCollection,
              ),
              AppMetricCard(
                label: 'Vacancy loss',
                value: '\$${snap.vacancyLoss.toStringAsFixed(0)}',
                subtitle: 'Monthly rent at risk',
                icon: Icons.door_front_door_outlined,
                accent: Colors.deepOrange.shade700,
              ),
              AppMetricCard(
                label: 'This month',
                value: '\$${snap.monthComparison.current.toStringAsFixed(0)}',
                subtitle:
                    '${snap.monthComparison.changePct >= 0 ? '+' : ''}${snap.monthComparison.changePct.toStringAsFixed(0)}% vs last month',
                icon: Icons.calendar_month_outlined,
                accent: snap.monthComparison.changePct >= 0
                    ? Colors.green.shade700
                    : scheme.error,
                onTap: openTrends,
              ),
              AppMetricCard(
                label: 'Occupancy',
                value: '${snap.occupancyRate.toStringAsFixed(0)}%',
                subtitle:
                    '${snap.occupiedCount} of ${widget.apartments.length} units',
                icon: Icons.pie_chart_outline_rounded,
                accent: scheme.tertiary,
                onTap: openTrends,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Average rent'),
              subtitle: const Text('Current inventory'),
              trailing: Text(
                '\$${snap.averageRent.toStringAsFixed(0)}/mo',
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const AppSectionHeader(
            title: 'Report drill-downs',
            subtitle: 'Open only the analysis you need',
          ),
          _reportDrillCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cash collection',
            subtitle: 'Outstanding balances and collection rate',
            value: '${snap.outstanding.length} due',
            accent: Colors.amber.shade800,
            onTap: openCashCollection,
          ),
          _reportDrillCard(
            icon: Icons.event_busy_outlined,
            title: 'Lease expiries',
            subtitle: 'Active agreements ending soon',
            value: '${snap.leaseExpiries.length}',
            accent: snap.expiringWithin30 > 0
                ? Colors.amber.shade800
                : scheme.secondary,
            onTap: () => _openReportDetail(
              title: 'Lease expiries',
              subtitle: 'Next 90 days',
              children: _leaseExpiriesChildren(snap, scheme),
            ),
          ),
          _reportDrillCard(
            icon: Icons.people_outline,
            title: 'Customer reliability',
            subtitle: 'Risk ranking by remaining balance',
            value: '${snap.customerReliability.length}',
            accent: scheme.secondary,
            onTap: () => _openReportDetail(
              title: 'Customer reliability',
              subtitle: 'Paid totals, remaining balances, and risk flags',
              children: [
                if (snap.customerReliability.isEmpty)
                  const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No customer payment history',
                    message:
                        'Customer rankings appear after bookings are recorded.',
                  )
                else
                  ...snap.customerReliability.take(20).map((row) {
                    return Card(
                      child: ListTile(
                        onTap: widget.onOpenCustomer == null
                            ? null
                            : () => widget.onOpenCustomer!(row.customerId),
                        title: Text(
                          row.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Paid \$${row.totalPaid.toStringAsFixed(0)} · '
                          'Remaining \$${row.totalRemaining.toStringAsFixed(0)} · '
                          '${row.problemBookings} partial/pending',
                        ),
                        trailing: row.totalRemaining > 0
                            ? AppStatusChip(
                                label: 'At risk',
                                tone: AppChipTone.warning,
                              )
                            : const AppStatusChip(
                                label: 'Good',
                                tone: AppChipTone.positive,
                              ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          _reportDrillCard(
            icon: Icons.show_chart_rounded,
            title: 'Trends',
            subtitle: 'Revenue, occupancy, and revenue vs expenses',
            value:
                '${snap.monthComparison.changePct >= 0 ? '+' : ''}${snap.monthComparison.changePct.toStringAsFixed(0)}%',
            accent: snap.monthComparison.changePct >= 0
                ? Colors.green.shade700
                : scheme.error,
            onTap: openTrends,
          ),
          _reportDrillCard(
            icon: Icons.apartment_rounded,
            title: 'Profit by apartment',
            subtitle: 'Revenue minus maintenance per unit',
            value: '${snap.profitByApartment.length}',
            accent: snap.netProfit >= 0 ? Colors.green.shade700 : scheme.error,
            onTap: () => _openReportDetail(
              title: 'Profit by apartment',
              subtitle: _periodRangeLabel(),
              children: [_profitList(snap.profitByApartment, scheme)],
            ),
          ),
          _reportDrillCard(
            icon: Icons.business_rounded,
            title: 'Profit by building',
            subtitle: 'Aggregated apartment performance',
            value: '${snap.profitByBuilding.length}',
            accent: snap.netProfit >= 0 ? Colors.green.shade700 : scheme.error,
            onTap: () => _openReportDetail(
              title: 'Profit by building',
              subtitle: _periodRangeLabel(),
              children: [_profitList(snap.profitByBuilding, scheme)],
            ),
          ),
          _reportDrillCard(
            icon: Icons.build_outlined,
            title: 'Maintenance analysis',
            subtitle: 'Trends, costly apartments, and biggest jobs',
            value: '\$${snap.totalMaintenance.toStringAsFixed(0)}',
            accent: scheme.error,
            onTap: () => _openReportDetail(
              title: 'Maintenance analysis',
              subtitle: _periodRangeLabel(),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Maintenance trend',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _buildTrendChart(
                          scheme: scheme,
                          points: snap.maintTrend,
                          color: scheme.error,
                          emptyMessage:
                              'No maintenance costs in the last 6 months',
                        ),
                      ],
                    ),
                  ),
                ),
                const AppSectionHeader(title: 'By apartment'),
                _labeledAmountList(snap.maintByApartment, scheme),
                const AppSectionHeader(title: 'By building'),
                _labeledAmountList(snap.maintByBuilding, scheme),
                const AppSectionHeader(title: 'Most expensive maintenance'),
                if (snap.topMaintenance.isEmpty)
                  const AppEmptyState(
                    icon: Icons.build_outlined,
                    title: 'No maintenance in period',
                    message:
                        'Top maintenance items appear for the selected period.',
                  )
                else
                  ...snap.topMaintenance.map((m) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          m.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_maintenanceApartmentLabel(m)} · ${m.date}',
                        ),
                        trailing: Text(
                          '\$${m.cost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.tertiary,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          _reportDrillCard(
            icon: Icons.receipt_long_outlined,
            title: 'Maintenance log',
            subtitle: 'All backend maintenance in selected period',
            value: '${snap.filteredMaintenance.length}',
            accent: scheme.tertiary,
            onTap: () => _openReportDetail(
              title: 'Maintenance log',
              subtitle: _periodRangeLabel(),
              children: [
                if (widget.maintenance.isEmpty)
                  const AppEmptyState(
                    icon: Icons.build_outlined,
                    title: 'No maintenance yet',
                    message:
                        'Log maintenance from Buildings to include backend costs here.',
                  )
                else if (snap.filteredMaintenance.isEmpty)
                  AppEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Nothing in $_selectedPeriod',
                    message: 'Try a wider period or add a maintenance record.',
                  )
                else
                  ...snap.filteredMaintenance.map((m) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          m.description,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_maintenanceApartmentLabel(m)} · ${m.date}',
                        ),
                        trailing: Text(
                          '\$${m.cost.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.tertiary,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: kAppListBottomInset),
        ],
      ),
    );

    return SafeArea(
      child: widget.onRefresh == null
          ? body
          : RefreshIndicator(onRefresh: widget.onRefresh!, child: body),
    );
  }
}
