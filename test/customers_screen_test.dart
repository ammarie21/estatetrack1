import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/screens/customers/customers_screen.dart';
import 'test_fixtures.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('customers list shows lease expiry badge for active contract', (
    WidgetTester tester,
  ) async {
    final contract = activeContractForCustomer(
      endDate: DateTime.now().add(const Duration(days: 14)),
    );

    await pumpScreen(
      tester,
      CustomersScreen(
        customers: [
          testCustomer.copyWith(
            apartment: 'A-101',
            startDate: '2025-01-01',
            endDate: '2025-12-31',
          ),
        ],
        contracts: [contract],
        onCustomersChanged: (_) {},
      ),
    );

    expect(find.text('Sara Al-Masri'), findsOneWidget);
    expect(find.textContaining('Expiring in'), findsOneWidget);
    expect(find.text('1 customer'), findsOneWidget);
  });

  testWidgets('customers screen opens detail on row tap', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      CustomersScreen(customers: [testCustomer], onCustomersChanged: (_) {}),
    );

    await tester.tap(find.text('Sara Al-Masri'));
    await tester.pumpAndSettle();

    expect(find.text('No rental activity yet'), findsOneWidget);
  });
}
