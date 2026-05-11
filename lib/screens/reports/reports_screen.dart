import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.rentalTransactions,
    required this.expenses,
    required this.apartments,
    required this.customers,
    required this.maintenance,
  });

  final List<RentalTransactionModel> rentalTransactions;
  final List<ExpenseModel> expenses;
  final List<ApartmentModel> apartments;
  final List<CustomerModel> customers;
  final List<MaintenanceModel> maintenance;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'This Month';

  final List<String> _periods = [
    'Last Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  double get _totalRevenue => widget.rentalTransactions.fold(
        0.0,
        (sum, t) => sum + t.paidInitialTotalDueAmount,
      );

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

  Widget _buildRevenueExpenseChart() {
    final revenue = _totalRevenue;
    final expenses = _totalExpenses + _totalMaintenance;
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
                  color: Colors.green,
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
                  color: Colors.red,
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

  Widget _buildExpenseBreakdownChart() {
    final expense = _totalExpenses;
    final maintenance = _totalMaintenance;
    final total = expense + maintenance;

    if (total == 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No expense data available')),
      );
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: expense,
              color: Colors.orange,
              title: 'Expenses',
              radius: 60,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            PieChartSectionData(
              value: maintenance,
              color: Colors.blueGrey,
              title: 'Maintenance',
              radius: 60,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            const SizedBox(height: 20),
            const Text(
              'Charts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue vs Expenses',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildRevenueExpenseChart(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Breakdown',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildExpenseBreakdownChart(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Average Rent',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '\$${_averageRent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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

