import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/screens/buildings/apartment_detail_screen.dart';
import 'test_fixtures.dart';
import 'test_helpers.dart';

void main() {
  testWidgets(
    'apartment detail shows occupied unit with tenant and maintenance',
    (WidgetTester tester) async {
      final contract = activeContractForCustomer(
        customerId: testTenant.customerId,
        apartmentId: testApartmentOccupied.apartmentId,
        bookingId: 20,
      );

      await pumpScreen(
        tester,
        ApartmentDetailScreen(
          apartment: testApartmentOccupied,
          building: testBuilding,
          maintenance: [testMaintenance],
          apartmentTypes: [testApartmentType],
          contracts: [contract],
          customers: [testTenant],
        ),
      );

      expect(find.text('A-101'), findsWidgets);
      expect(find.text('Occupied'), findsOneWidget);
      expect(find.text('Tower A'), findsOneWidget);
      expect(find.text('Current tenant: Omar Haddad'), findsOneWidget);
      expect(find.text('Balcony'), findsOneWidget);
      expect(find.text('Furnished'), findsOneWidget);

      await scrollTo(tester, find.text('Maintenance history'));
      expect(find.text('Fix AC unit'), findsOneWidget);
      expect(find.text('\$150'), findsOneWidget);
    },
  );

  testWidgets('apartment detail shows vacant unit without maintenance', (
    WidgetTester tester,
  ) async {
    await pumpScreen(
      tester,
      const ApartmentDetailScreen(
        apartment: testApartmentVacant,
        building: testBuilding,
        maintenance: [],
        apartmentTypes: [testApartmentType],
      ),
    );

    expect(find.text('Vacant'), findsOneWidget);

    await scrollTo(tester, find.text('No maintenance logged'));
    expect(find.text('No maintenance logged'), findsOneWidget);
    expect(find.text('Current tenant'), findsNothing);
  });
}
