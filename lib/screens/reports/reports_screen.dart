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

