import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/screens/contracts/rental_calendar_screen.dart';
import 'package:estatetrack1/ui/app_components.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.contracts,
    required this.returns,
    required this.rentalTransactions,
    required this.customers,
    required this.apartments,
    this.maintenance = const [],
    this.onRefresh,
    this.onEditContract,
  });

  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final List<MaintenanceModel> maintenance;
  final Future<void> Function()? onRefresh;
  final void Function(ContractModel contract)? onEditContract;

  Widget _banner() {
    return AppFlowBanner(
      icon: Icons.calendar_month_outlined,
      text: maintenance.isEmpty
          ? 'Lease starts, ends, apartment returns, and rental transaction dates.'
          : 'Lease starts, ends, returns, payments, and ${maintenance.length} maintenance records.',
    );
  }

  Widget _calendar({required double height}) {
    return SizedBox(
      height: height,
      child: RentalCalendarScreen(
        contracts: contracts,
        returns: returns,
        rentalTransactions: rentalTransactions,
        customers: customers,
        apartments: apartments,
        maintenance: maintenance,
        onEditContract: onEditContract,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const bannerHeight = 72.0;
        final calendarHeight = (constraints.maxHeight - bannerHeight).clamp(
          320.0,
          constraints.maxHeight,
        );

        if (onRefresh == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _banner(),
              Expanded(child: _calendar(height: calendarHeight)),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh!,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _banner(),
              _calendar(height: calendarHeight),
            ],
          ),
        );
      },
    );
  }
}
