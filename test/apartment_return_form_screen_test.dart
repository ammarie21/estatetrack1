import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/screens/contracts/apartment_return_form_screen.dart';
import 'test_fixtures.dart';
import 'test_helpers.dart';

List<ContractModel> _contracts({
  required ContractModel primary,
  ContractModel? duplicate,
}) {
  if (duplicate == null) return [primary];
  return [primary, duplicate];
}

void main() {
  testWidgets('add return loads with a single active agreement', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer(bookingId: 4);
    final booking = bookingForContract(contract, rentalPrice: 500);

    await pumpScreen(
      tester,
      ApartmentReturnFormScreen(
        contracts: [contract],
        bookings: [booking],
        returns: const [],
        customers: [testCustomer],
        buildings: [testBuilding],
        apartments: [testApartmentOccupied],
      ),
    );

    expect(find.text('Add Return'), findsWidgets);
    expect(find.textContaining('Booking 4'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edit return keeps terminated agreement in dropdown', (
    WidgetTester tester,
  ) async {
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 5, 30);
    final contract = ContractModel(
      contractId: 4,
      customerId: testCustomer.customerId,
      apartmentId: testApartmentOccupied.apartmentId,
      startDate: start,
      endDate: end,
      totalAmount: 3000,
      status: 'Terminated',
      bookingId: 4,
      initialPayment: 3000,
    );
    final booking = bookingForContract(contract, rentalPrice: 3000).copyWith(
      isActive: false,
    );
    final existing = ApartmentReturnModel(
      returnId: 9,
      bookingId: 4,
      actualReturnDate: DateTime(2026, 3, 30),
      actualRentalDays: 30,
      additionalCharges: 150,
      actualTotalDueAmount: 1150,
      totalRemaining: 0,
      totalRefundedAmount: 1850,
    );

    await pumpScreen(
      tester,
      ApartmentReturnFormScreen(
        existing: existing,
        contracts: [contract],
        bookings: [booking],
        returns: [existing],
        customers: [testCustomer],
        buildings: [testBuilding],
        apartments: [testApartmentOccupied],
      ),
    );

    expect(find.text('Edit Return'), findsOneWidget);
    expect(find.textContaining('Booking 4'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate active contracts with same booking do not crash', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer(bookingId: 4);
    final duplicate = contract.copyWith(contractId: 99);
    final booking = bookingForContract(contract, rentalPrice: 500);

    await pumpScreen(
      tester,
      ApartmentReturnFormScreen(
        contracts: _contracts(primary: contract, duplicate: duplicate),
        bookings: [booking],
        returns: const [],
        customers: [testCustomer],
        buildings: [testBuilding],
        apartments: [testApartmentOccupied],
      ),
    );

    expect(find.byType(ApartmentReturnFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('early checkout with charges shows refund due in summary', (
    WidgetTester tester,
  ) async {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(const Duration(days: 20));
    final end = start.add(const Duration(days: 89));
    final contract = ContractModel(
      contractId: 4,
      customerId: testCustomer.customerId,
      apartmentId: testApartmentOccupied.apartmentId,
      startDate: start,
      endDate: end,
      totalAmount: 3000,
      status: 'Active',
      bookingId: 4,
      initialPayment: 3000,
    );
    final booking = bookingForContract(contract, rentalPrice: 3000);

    await pumpScreen(
      tester,
      ApartmentReturnFormScreen(
        contracts: [contract],
        bookings: [booking],
        returns: const [],
        customers: [testCustomer],
        buildings: [testBuilding],
        apartments: [testApartmentOccupied],
      ),
    );

    await tester.enterText(find.byType(TextField).at(1), '150');
    await tester.pumpAndSettle();

    expect(find.textContaining('Refund due'), findsOneWidget);
    expect(find.textContaining('Remaining:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows empty state when no active agreements remain', (
    WidgetTester tester,
  ) async {
    final returned = ApartmentReturnModel(
      returnId: 1,
      bookingId: 4,
      actualReturnDate: DateTime(2026, 3, 30),
      actualRentalDays: 30,
      additionalCharges: 0,
      actualTotalDueAmount: 1000,
    );
    final contract = activeContractForCustomer(bookingId: 4).copyWith(
      status: 'Terminated',
    );

    await pumpScreen(
      tester,
      ApartmentReturnFormScreen(
        contracts: [contract],
        bookings: [bookingForContract(contract)],
        returns: [returned],
        customers: [testCustomer],
        buildings: [testBuilding],
        apartments: [testApartmentOccupied],
      ),
    );

    expect(find.text('No active agreements'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
