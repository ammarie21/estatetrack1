import 'package:flutter/material.dart';

import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
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
    this.onEditContract,
  });

  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
  final List<CustomerModel> customers;
  final List<ApartmentModel> apartments;
  final void Function(ContractModel contract)? onEditContract;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppFlowBanner(
          icon: Icons.calendar_month_outlined,
          text:
              'Lease starts, ends, apartment returns, and rental transaction dates.',
        ),
        Expanded(
          child: RentalCalendarScreen(
            contracts: contracts,
            returns: returns,
            rentalTransactions: rentalTransactions,
            customers: customers,
            apartments: apartments,
            onEditContract: onEditContract,
          ),
        ),
      ],
    );
  }
}
