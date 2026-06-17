import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  test('EstateIndexes resolves customer apartment and paid amount', () {
    final contract = activeContractForCustomer();
    final booking = bookingForContract(contract, rentalPrice: 250);
    final indexes = EstateIndexes.fromLists(
      customers: [testCustomer],
      buildings: [testBuilding],
      apartments: [testApartmentOccupied],
      bookings: [booking],
    );

    expect(indexes.customerName(1), 'Sara Al-Masri');
    expect(indexes.apartmentNumber(1), 'A-101');
    expect(indexes.apartmentLabel(1), contains('Tower A'));
    expect(indexes.paidForBooking(booking.bookingId), 250);
    expect(indexes.paidForBooking(null), 0);
  });

  test('BackendRecordCounts totals all categories', () {
    const counts = BackendRecordCounts(
      customers: 2,
      buildings: 1,
      apartments: 4,
      bookings: 3,
      returns: 1,
      maintenance: 2,
      staff: 2,
    );

    expect(counts.total, 15);
  });
}
