import 'package:flutter/material.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/payment_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.apartments,
    required this.customers,
    required this.payments,
    required this.expenses,
  });

  final List<ApartmentModel> apartments;
  final List<CustomerModel> customers;
  final List<PaymentModel> payments;
  final List<ExpenseModel> expenses;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final totalApartments = apartments.length;
    final totalCustomers = customers.length;
    final occupiedCount = apartments.where((a) => !a.isAvailable).length;
    final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    final stats = [
      _Stat('Total Apartments', '$totalApartments', Icons.apartment_rounded),
      _Stat('Total Customers', '$totalCustomers', Icons.people_outline_rounded),
      _Stat('Occupied Units', '$occupiedCount', Icons.home_rounded),
      _Stat('Monthly Revenue', '\$${totalRevenue.toStringAsFixed(0)}', Icons.payments_outlined),
      _Stat('Monthly Expenses', '\$${totalExpenses.toStringAsFixed(0)}', Icons.receipt_long_outlined),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final s = stats[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(s.icon, color: scheme.primary, size: 28),
                    const Spacer(),
                    Text(
                      s.value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}