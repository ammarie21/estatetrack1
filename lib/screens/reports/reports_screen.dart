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
import 'package:estatetrack1/utils/report_period.dart';

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
  });

  final List<RentalTransactionModel> rentalTransactions;
  final List<ApartmentModel> apartments;
  final List<BuildingModel> buildings;
  final List<CustomerModel> customers;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<MaintenanceModel> maintenance;
  final Future<void> Function()? onRefresh;

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

  ReportAnalyticsInput get _analyticsInput => ReportAnalyticsInput(
    transactions: widget.rentalTransactions,
    apartments: widget.apartments,
    buildings: widget.buildings,
    customers: widget.customers,
    bookings: widget.bookings,
    contracts: widget.contracts,
    maintenance: widget.maintenance,
    period: _period,
  );

  List<RentalTransactionModel> get _filteredTransactions =>
      transactionsInPeriod(widget.rentalTransactions, _period);

  List<MaintenanceModel> get _filteredMaintenance =>
      maintenanceInPeriod(widget.maintenance, _period);

  double get _totalRevenue => _filteredTransactions.fold(
    0.0,
    (sum, t) => sum + t.paidInitialTotalDueAmount,
  );

  double get _totalMaintenance =>
      _filteredMaintenance.fold(0, (sum, m) => sum + m.cost);

  double get _netProfit => _totalRevenue - _totalMaintenance;

  double get _outstanding => computeOutstandingBalances(
    _analyticsInput,
  ).fold(0.0, (sum, row) => sum + row.remaining);

  int get _occupiedCount =>
      widget.apartments.where((a) => !a.isAvailable).length;

  double get _occupancyRate => widget.apartments.isEmpty
      ? 0
      : (_occupiedCount / widget.apartments.length * 100);

  double get _averageRent => widget.apartments.isEmpty
      ? 0
      : widget.apartments.fold(0.0, (sum, a) => sum + a.rentPricePerMonth) /
            widget.apartments.length;

  int get _activeLeases =>
      widget.contracts.where((c) => c.status == 'Active').length;

  Map<String, int> get _paymentStatusCounts {
    final counts = <String, int>{};
    for (final t in _filteredTransactions) {
      counts[t.transactionStatus] = (counts[t.transactionStatus] ?? 0) + 1;
    }
    return counts;
  }

  String _periodRangeLabel() {
    final start = _period.start.toIso8601String().split('T').first;
    final end = _period.end.toIso8601String().split('T').first;
    return '$start → $end';
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

  Future<void> _copySummary() async {
    final input = _analyticsInput;
    final collectionRate = computeCollectionRate(_filteredTransactions);
    final vacancyLoss = computeVacancyLoss(widget.apartments);
    final monthCompare = revenueMonthComparison(input);
    final outstanding = computeOutstandingBalances(input);

    final text =
        'EstateTrack report ($_reportTitle)\n'
        'Range: ${_periodRangeLabel()}\n'
        'Revenue: \$${_totalRevenue.toStringAsFixed(2)}\n'
        'Maintenance expenses: \$${_totalMaintenance.toStringAsFixed(2)}\n'
        'Net: \$${_netProfit.toStringAsFixed(2)}\n'
        'Outstanding: \$${_outstanding.toStringAsFixed(2)} (${outstanding.length} bookings)\n'
        'Collection rate: ${collectionRate.toStringAsFixed(0)}%\n'
        'Vacancy loss estimate: \$${vacancyLoss.toStringAsFixed(2)}/mo\n'
        'Revenue this month: \$${monthCompare.current.toStringAsFixed(2)} '
        '(${monthCompare.changePct >= 0 ? '+' : ''}${monthCompare.changePct.toStringAsFixed(0)}% vs last month)\n'
        'Occupancy: ${_occupancyRate.toStringAsFixed(0)}% ($_occupiedCount/${widget.apartments.length})\n'
        'Active leases: $_activeLeases';
    await copyTextToClipboard(context, text);
  }

  Widget _buildRevenueExpenseChart(ColorScheme scheme) {
    final revenue = _totalRevenue;
    final expenses = _totalMaintenance;
    if (revenue <= 0 && expenses <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No revenue or expense data in this period')),
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
      return SizedBox(height: 180, child: Center(child: Text(emptyMessage)));
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
        child: Center(child: Text('No occupancy data yet')),
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
    final input = _analyticsInput;

    final outstanding = computeOutstandingBalances(input);
    final profitByApartment = computeProfitByApartment(input);
    final profitByBuilding = computeProfitByBuilding(input);
    final maintByApartment = maintenanceByApartment(input);
    final maintByBuilding = maintenanceByBuilding(input);
    final topMaintenance = topMaintenanceItems(input);
    final maintTrend = maintenanceMonthlyTrend(input);
    final occupancyTrend = computeOccupancyTrend(input);
    final leaseExpiries = computeLeaseExpiries(input);
    final revenueTrend = computeRevenueTrend(input);
    final monthCompare = revenueMonthComparison(input);
    final collectionRate = computeCollectionRate(_filteredTransactions);
    final customerReliability = computeCustomerReliability(input);
    final vacancyLoss = computeVacancyLoss(widget.apartments);

    final expiring7 = leaseExpiries.where((r) => r.daysUntilEnd <= 7).length;
    final expiring30 = leaseExpiries.where((r) => r.daysUntilEnd <= 30).length;

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
                        onPressed: _copySummary,
                        icon: const Icon(Icons.copy_all_outlined),
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
          if (_paymentStatusCounts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentStatusCounts.entries.map((entry) {
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
                value: '\$${_totalRevenue.toStringAsFixed(0)}',
                subtitle: 'Booking payments in period',
                icon: Icons.attach_money,
                accent: scheme.primary,
              ),
              AppMetricCard(
                label: 'Costs',
                value: '\$${_totalMaintenance.toStringAsFixed(0)}',
                subtitle: 'Maintenance in period',
                icon: Icons.receipt_long_outlined,
                accent: scheme.error,
              ),
              AppMetricCard(
                label: 'Net',
                value: '\$${_netProfit.toStringAsFixed(0)}',
                subtitle: _selectedPeriod,
                icon: Icons.trending_up_rounded,
                accent: _netProfit >= 0 ? Colors.green.shade700 : scheme.error,
              ),
              AppMetricCard(
                label: 'Outstanding',
                value: '\$${_outstanding.toStringAsFixed(0)}',
                subtitle: '${outstanding.length} unpaid bookings',
                icon: Icons.pending_actions_outlined,
                accent: Colors.amber.shade800,
              ),
              AppMetricCard(
                label: 'Collection rate',
                value: '${collectionRate.toStringAsFixed(0)}%',
                subtitle: 'Paid vs due in period',
                icon: Icons.percent_rounded,
                accent: collectionRate >= 80
                    ? Colors.green.shade700
                    : Colors.amber.shade800,
              ),
              AppMetricCard(
                label: 'Vacancy loss',
                value: '\$${vacancyLoss.toStringAsFixed(0)}',
                subtitle: 'Monthly rent at risk',
                icon: Icons.door_front_door_outlined,
                accent: Colors.deepOrange.shade700,
              ),
              AppMetricCard(
                label: 'This month',
                value: '\$${monthCompare.current.toStringAsFixed(0)}',
                subtitle:
                    '${monthCompare.changePct >= 0 ? '+' : ''}${monthCompare.changePct.toStringAsFixed(0)}% vs last month',
                icon: Icons.calendar_month_outlined,
                accent: monthCompare.changePct >= 0
                    ? Colors.green.shade700
                    : scheme.error,
              ),
              AppMetricCard(
                label: 'Occupancy',
                value: '${_occupancyRate.toStringAsFixed(0)}%',
                subtitle:
                    '$_occupiedCount of ${widget.apartments.length} units',
                icon: Icons.pie_chart_outline_rounded,
                accent: scheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Average rent'),
              subtitle: const Text('Current inventory'),
              trailing: Text(
                '\$${_averageRent.toStringAsFixed(0)}/mo',
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
            value: '${outstanding.length} due',
            accent: Colors.amber.shade800,
            onTap: () => _openReportDetail(
              title: 'Cash collection',
              subtitle: _periodRangeLabel(),
              children: [
                AppMetricCard(
                  label: 'Collection rate',
                  value: '${collectionRate.toStringAsFixed(0)}%',
                  subtitle: 'Paid vs due in selected period',
                  icon: Icons.percent_rounded,
                  accent: collectionRate >= 80
                      ? Colors.green.shade700
                      : Colors.amber.shade800,
                ),
                const AppSectionHeader(
                  title: 'Outstanding balances',
                  subtitle: 'Bookings with unpaid balances right now',
                ),
                if (outstanding.isEmpty)
                  const AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'All caught up',
                    message: 'No bookings have outstanding balances.',
                  )
                else
                  ...outstanding.map((row) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          row.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${row.apartmentLabel}\n'
                          'Booking #${row.bookingId} · ends ${row.endDate.toIso8601String().split('T').first}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${row.remaining.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: scheme.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AppStatusChip(
                              label: row.status,
                              tone: chipToneForBookingStatus(row.status),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          _reportDrillCard(
            icon: Icons.event_busy_outlined,
            title: 'Lease expiries',
            subtitle: 'Active agreements ending soon',
            value: '${leaseExpiries.length}',
            accent: expiring30 > 0 ? Colors.amber.shade800 : scheme.secondary,
            onTap: () => _openReportDetail(
              title: 'Lease expiries',
              subtitle: 'Next 90 days',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppStatusChip(
                      label: '$expiring7 in 7 days',
                      tone: expiring7 > 0
                          ? AppChipTone.negative
                          : AppChipTone.neutral,
                    ),
                    AppStatusChip(
                      label: '$expiring30 in 30 days',
                      tone: expiring30 > 0
                          ? AppChipTone.warning
                          : AppChipTone.neutral,
                    ),
                    AppStatusChip(
                      label: '${leaseExpiries.length} in 90 days',
                      tone: AppChipTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (leaseExpiries.isEmpty)
                  const AppEmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No upcoming expiries',
                    message: 'No active leases end in the next 90 days.',
                  )
                else
                  ...leaseExpiries.map((row) {
                    return Card(
                      child: ListTile(
                        title: Text(
                          row.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${row.apartmentLabel}\n'
                          'Ends ${row.contract.endDate.toIso8601String().split('T').first}',
                        ),
                        isThreeLine: true,
                        trailing: AppStatusChip(
                          label: row.daysUntilEnd == 0
                              ? 'Today'
                              : '${row.daysUntilEnd}d left',
                          tone: _leaseExpiryTone(row.daysUntilEnd),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          _reportDrillCard(
            icon: Icons.people_outline,
            title: 'Customer reliability',
            subtitle: 'Risk ranking by remaining balance',
            value: '${customerReliability.length}',
            accent: scheme.secondary,
            onTap: () => _openReportDetail(
              title: 'Customer reliability',
              subtitle: 'Paid totals, remaining balances, and risk flags',
              children: [
                if (customerReliability.isEmpty)
                  const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No customer payment history',
                    message:
                        'Customer rankings appear after bookings are recorded.',
                  )
                else
                  ...customerReliability.take(20).map((row) {
                    return Card(
                      child: ListTile(
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
                '${monthCompare.changePct >= 0 ? '+' : ''}${monthCompare.changePct.toStringAsFixed(0)}%',
            accent: monthCompare.changePct >= 0
                ? Colors.green.shade700
                : scheme.error,
            onTap: () => _openReportDetail(
              title: 'Trends',
              subtitle: 'Rolling 6 months',
              children: [
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
                          points: revenueTrend,
                          color: scheme.primary,
                          emptyMessage:
                              'No revenue recorded in the last 6 months',
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
                        _buildOccupancyTrendChart(scheme, occupancyTrend),
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
                        _buildRevenueExpenseChart(scheme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _reportDrillCard(
            icon: Icons.apartment_rounded,
            title: 'Profit by apartment',
            subtitle: 'Revenue minus maintenance per unit',
            value: '${profitByApartment.length}',
            accent: _netProfit >= 0 ? Colors.green.shade700 : scheme.error,
            onTap: () => _openReportDetail(
              title: 'Profit by apartment',
              subtitle: _periodRangeLabel(),
              children: [_profitList(profitByApartment, scheme)],
            ),
          ),
          _reportDrillCard(
            icon: Icons.business_rounded,
            title: 'Profit by building',
            subtitle: 'Aggregated apartment performance',
            value: '${profitByBuilding.length}',
            accent: _netProfit >= 0 ? Colors.green.shade700 : scheme.error,
            onTap: () => _openReportDetail(
              title: 'Profit by building',
              subtitle: _periodRangeLabel(),
              children: [_profitList(profitByBuilding, scheme)],
            ),
          ),
          _reportDrillCard(
            icon: Icons.build_outlined,
            title: 'Maintenance analysis',
            subtitle: 'Trends, costly apartments, and biggest jobs',
            value: '\$${_totalMaintenance.toStringAsFixed(0)}',
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
                          points: maintTrend,
                          color: scheme.error,
                          emptyMessage:
                              'No maintenance costs in the last 6 months',
                        ),
                      ],
                    ),
                  ),
                ),
                const AppSectionHeader(title: 'By apartment'),
                _labeledAmountList(maintByApartment, scheme),
                const AppSectionHeader(title: 'By building'),
                _labeledAmountList(maintByBuilding, scheme),
                const AppSectionHeader(title: 'Most expensive maintenance'),
                if (topMaintenance.isEmpty)
                  const AppEmptyState(
                    icon: Icons.build_outlined,
                    title: 'No maintenance in period',
                    message:
                        'Top maintenance items appear for the selected period.',
                  )
                else
                  ...topMaintenance.map((m) {
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
            value: '${_filteredMaintenance.length}',
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
                else if (_filteredMaintenance.isEmpty)
                  AppEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Nothing in $_selectedPeriod',
                    message: 'Try a wider period or add a maintenance record.',
                  )
                else
                  ..._filteredMaintenance.map((m) {
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
