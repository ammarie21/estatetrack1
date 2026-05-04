import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:estatetrack1/models/payment_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.payments,
    required this.expenses,
    required this.apartments,
    required this.customers,
    required this.maintenance,
  });

  final List<PaymentModel> payments;
  final List<ExpenseModel> expenses;
  final List<ApartmentModel> apartments;
  final List<CustomerModel> customers;
  final List<MaintenanceModel> maintenance;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _showRentTrend = false;
  bool _showExpenseBreakdown = false;
  bool _showOccupancyTrend = false;
  bool _showSummaryStats = false;
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'Last Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  double get _totalRevenue =>
      widget.payments.fold(0, (sum, p) => sum + p.amount);

  double get _totalExpenses =>
      widget.expenses.fold(0, (sum, e) => sum + e.amount);

  double get _totalMaintenance =>
      widget.maintenance.fold(0, (sum, m) => sum + m.cost);

  double get _netProfit =>
      _totalRevenue - _totalExpenses - _totalMaintenance;

  int get _occupiedCount =>
      widget.apartments.where((a) => a.isOccupied).length;

  double get _occupancyRate => widget.apartments.isEmpty
      ? 0
      : (_occupiedCount / widget.apartments.length * 100);

  double get _averageRent => widget.apartments.isEmpty
      ? 0
      : widget.apartments.fold(0.0, (sum, a) => sum + a.rent) /
      widget.apartments.length;

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text(
            'Report exported successfully! (Feature demonstration)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A3AE8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reports & Analytics',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down),
                              items: _periods
                                  .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p),
                              ))
                                  .toList(),
                              onChanged: (v) => setState(
                                      () => _selectedPeriod = v ?? 'This Month'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _showExportDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.download_outlined,
                            color: Color(0xFF1A3AE8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Key Metrics
            const Text(
              'Key Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _MetricCard(
                  label: 'Revenue',
                  value: '\$${_totalRevenue.toStringAsFixed(0)}',
                  subtitle: _selectedPeriod,
                  icon: Icons.attach_money,
                  iconColor: Colors.green,
                  subtitleColor: Colors.green,
                ),
                _MetricCard(
                  label: 'Expenses',
                  value:
                  '\$${(_totalExpenses + _totalMaintenance).toStringAsFixed(0)}',
                  subtitle: _selectedPeriod,
                  icon: Icons.trending_up,
                  iconColor: Colors.red,
                  subtitleColor: Colors.red,
                ),
                _MetricCard(
                  label: 'Net Profit',
                  value: '\$${_netProfit.toStringAsFixed(0)}',
                  subtitle: _selectedPeriod,
                  icon: Icons.attach_money,
                  iconColor: Colors.blue,
                  subtitleColor: Colors.grey,
                ),
                _MetricCard(
                  label: 'Occupancy',
                  value: '${_occupancyRate.toStringAsFixed(0)}%',
                  subtitle:
                  '$_occupiedCount of ${widget.apartments.length} units',
                  icon: Icons.home_outlined,
                  iconColor: Colors.purple,
                  subtitleColor: Colors.grey,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rent Collection Trend
            _SectionButton(
              title: 'Rent Collection Trend',
              isExpanded: _showRentTrend,
              onTap: () =>
                  setState(() => _showRentTrend = !_showRentTrend),
            ),
            if (_showRentTrend) ...[
              const SizedBox(height: 12),
              _RentCollectionChart(payments: widget.payments),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // Expense Breakdown
            _SectionButton(
              title: 'Expense Breakdown',
              isExpanded: _showExpenseBreakdown,
              onTap: () => setState(
                      () => _showExpenseBreakdown = !_showExpenseBreakdown),
            ),
            if (_showExpenseBreakdown) ...[
              const SizedBox(height: 12),
              _ExpenseBreakdownChart(
                expenses: widget.expenses,
                maintenance: widget.maintenance,
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // Occupancy Rate Trend
            _SectionButton(
              title: 'Occupancy Rate Trend',
              isExpanded: _showOccupancyTrend,
              onTap: () => setState(
                      () => _showOccupancyTrend = !_showOccupancyTrend),
            ),
            if (_showOccupancyTrend) ...[
              const SizedBox(height: 12),
              _OccupancyTrendChart(
                apartments: widget.apartments,
                occupancyRate: _occupancyRate,
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 8),

            // Summary Statistics
            _SectionButton(
              title: 'Summary Statistics',
              isExpanded: _showSummaryStats,
              onTap: () => setState(
                      () => _showSummaryStats = !_showSummaryStats),
            ),
            if (_showSummaryStats) ...[
              const SizedBox(height: 12),
              _SummaryStats(
                customers: widget.customers,
                apartments: widget.apartments,
                payments: widget.payments,
                averageRent: _averageRent,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionButton extends StatelessWidget {
  const _SectionButton({
    required this.title,
    required this.isExpanded,
    required this.onTap,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.subtitleColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),
        ],
      ),
    );
  }
}

class _RentCollectionChart extends StatelessWidget {
  const _RentCollectionChart({required this.payments});

  final List<PaymentModel> payments;

  @override
  Widget build(BuildContext context) {
    final months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
    final monthNumbers = [9, 10, 11, 12, 1];

    final collected = monthNumbers.map((m) {
      return payments
          .where((p) {
        final date = DateTime.tryParse(p.date);
        return date != null && date.month == m;
      })
          .fold(0.0, (sum, p) => sum + p.amount);
    }).toList();

    final avgCollected = collected.isEmpty
        ? 5000.0
        : collected.reduce((a, b) => a + b) / collected.length;

    final expected = List.filled(months.length,
        avgCollected > 0 ? avgCollected : 5000.0);

    final maxY = (collected.reduce((a, b) => a > b ? a : b) * 1.3)
        .clamp(1000.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        months[value.toInt()],
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : '${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: collected[i],
                        color: const Color(0xFF1A3AE8),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expected[i],
                        color: Colors.grey.shade200,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(
                  color: const Color(0xFF1A3AE8), label: 'Collected'),
              const SizedBox(width: 20),
              _Legend(color: Colors.grey.shade300, label: 'Expected'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseBreakdownChart extends StatelessWidget {
  const _ExpenseBreakdownChart({
    required this.expenses,
    required this.maintenance,
  });

  final List<ExpenseModel> expenses;
  final List<MaintenanceModel> maintenance;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryMap = {};

    for (final e in expenses) {
      categoryMap[e.category] =
          (categoryMap[e.category] ?? 0) + e.amount;
    }

    final maintenanceCost =
    maintenance.fold<double>(0, (sum, m) => sum + m.cost);
    if (maintenanceCost > 0) {
      categoryMap['Maintenance'] =
          (categoryMap['Maintenance'] ?? 0) + maintenanceCost;
    }

    if (categoryMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
            child: Text('No expense data available')),
      );
    }

    final colors = [
      const Color(0xFF4285F4),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
      const Color(0xFF00BCD4),
    ];

    final entries = categoryMap.entries.toList();
    final total =
    categoryMap.values.fold<double>(0, (s, v) => s + v);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: entries.asMap().entries.map((e) {
                  final percent =
                  (e.value.value / total * 100).round();
                  return PieChartSectionData(
                    value: e.value.value,
                    color: colors[e.key % colors.length],
                    title: '$percent%',
                    radius: 80,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...entries.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[e.key % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.value.key,
                      style: const TextStyle(fontSize: 14)),
                ),
                Text(
                  '\$${e.value.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _OccupancyTrendChart extends StatelessWidget {
  const _OccupancyTrendChart({
    required this.apartments,
    required this.occupancyRate,
  });

  final List<ApartmentModel> apartments;
  final double occupancyRate;

  @override
  Widget build(BuildContext context) {
    final spots = [
      FlSpot(0, (occupancyRate - 10).clamp(0, 100)),
      FlSpot(1, (occupancyRate - 5).clamp(0, 100)),
      FlSpot(2, occupancyRate.clamp(0, 100)),
      FlSpot(3, (occupancyRate + 5).clamp(0, 100)),
      FlSpot(4, occupancyRate.clamp(0, 100)),
    ];

    final months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.purple,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                        radius: 5,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: Colors.purple,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.purple.withValues(alpha: 0.05),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    months[value.toInt()],
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({
    required this.customers,
    required this.apartments,
    required this.payments,
    required this.averageRent,
  });

  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<PaymentModel> payments;
  final double averageRent;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatRow(
        icon: Icons.people_outline,
        label: 'Total Customers',
        value: '${customers.length}',
      ),
      _StatRow(
        icon: Icons.home_outlined,
        label: 'Total Units',
        value: '${apartments.length}',
      ),
      _StatRow(
        icon: Icons.attach_money,
        label: 'Average Rent',
        value: '\$${averageRent.toStringAsFixed(0)}',
      ),
      _StatRow(
        icon: Icons.calendar_today_outlined,
        label: 'Payments This Month',
        value: '${payments.length}',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: stats.asMap().entries.map((e) {
          final s = e.value;
          final isLast = e.key == stats.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(s.icon, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(s.label,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    Text(
                      s.value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                    height: 1,
                    color: Colors.grey.shade100,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatRow {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
          BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}