import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/screens/customers/customer_detail_screen.dart';
import 'test_fixtures.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('customer detail shows profile and rental activity', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer();
    final booking = bookingForContract(contract);
    final transaction = transactionForBooking(booking);

    await pumpScreen(
      tester,
      CustomerDetailScreen(
        customer: testCustomer,
        contracts: [contract],
        bookings: [booking],
        rentalTransactions: [transaction],
        apartments: [testApartmentOccupied],
        buildings: [testBuilding],
      ),
    );

    expect(find.text('Sara Al-Masri'), findsWidgets);
    expect(find.text('Total paid'), findsOneWidget);
    expect(find.text('\$300'), findsWidgets);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('\$200'), findsWidgets);

    await scrollTo(tester, find.text('Active agreement'));
    expect(find.text('Active agreement'), findsOneWidget);
    expect(find.text('Payment history'), findsOneWidget);
    expect(find.text('Partial'), findsOneWidget);
    expect(find.textContaining('Tower A - A-101'), findsWidgets);
  });

  testWidgets('customer detail shows empty state without rental activity', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const CustomerDetailScreen(
        customer: testCustomer,
        contracts: [],
        bookings: [],
        rentalTransactions: [],
        apartments: [],
        buildings: [],
      ),
    );

    await scrollTo(tester, find.text('No rental activity yet'));
    expect(find.text('No rental activity yet'), findsOneWidget);
    expect(find.text('Active agreement'), findsNothing);
  });

  testWidgets('customer detail shows expired badge for past lease', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer(
      endDate: DateTime.now().subtract(const Duration(days: 5)),
    );

    await pumpScreen(
      tester,
      CustomerDetailScreen(
        customer: testCustomer,
        contracts: [contract],
        bookings: const [],
        rentalTransactions: const [],
        apartments: [testApartmentOccupied],
        buildings: [testBuilding],
      ),
    );

    await scrollTo(tester, find.text('Expired'));
    expect(find.text('Expired'), findsOneWidget);
  });

  testWidgets('customer detail shows checkout records from returns', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer();
    final booking = bookingForContract(contract);
    final checkout = ApartmentReturnModel(
      returnId: 3,
      bookingId: booking.bookingId,
      actualReturnDate: DateTime(2026, 4, 1),
      actualRentalDays: 30,
      additionalCharges: 50,
      actualTotalDueAmount: 550,
      totalRemaining: 100,
      finalCheckNotes: 'Left keys at desk',
    );

    await pumpScreen(
      tester,
      CustomerDetailScreen(
        customer: testCustomer,
        contracts: [contract.copyWith(status: 'Terminated')],
        bookings: [booking],
        rentalTransactions: const [],
        apartments: [testApartmentOccupied],
        buildings: [testBuilding],
        returns: [checkout],
      ),
    );

    await scrollTo(tester, find.text('Check-out records'));
    expect(find.text('Check-out records'), findsOneWidget);
    expect(find.textContaining('Left keys at desk'), findsOneWidget);
    expect(find.text('\$550'), findsOneWidget);
  });
}
