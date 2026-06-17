import 'package:estatetrack1/data/derived_estate_state.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_fixtures.dart';

void main() {
  test('deriveEstateState builds contracts and transactions together', () {
    final contract = activeContractForCustomer();
    final booking = bookingForContract(contract, rentalPrice: 120);
    final checkout = ApartmentReturnModel(
      returnId: 1,
      bookingId: booking.bookingId,
      actualReturnDate: DateTime(2026, 4, 1),
      actualRentalDays: 30,
      additionalCharges: 0,
      actualTotalDueAmount: 500,
      totalRemaining: 0,
      totalRefundedAmount: 0,
    );

    final derived = deriveEstateState(bookings: [booking], returns: [checkout]);

    expect(derived.contracts.length, 1);
    expect(derived.contracts.first.status, 'Terminated');
    expect(derived.rentalTransactions.length, 1);
    expect(derived.rentalTransactions.first.transactionStatus, 'Closed');
  });
}
