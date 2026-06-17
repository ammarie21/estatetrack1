import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final activeBooking = RentalBookingModel(
    bookingId: 5,
    userId: 1,
    customerId: 1,
    apartmentId: 1,
    startDate: DateTime.now().add(const Duration(days: 1)),
    endDate: DateTime.now().add(const Duration(days: 30)),
    initialTotalDueAmount: 500,
    bookingType: 0,
    periodFee: 500,
    isActive: true,
  );

  final returnedBooking = activeBooking.copyWith(bookingId: 6, isActive: false);

  final apartmentReturn = ApartmentReturnModel(
    returnId: 1,
    bookingId: 6,
    actualReturnDate: DateTime.now(),
    actualRentalDays: 10,
    additionalCharges: 0,
    actualTotalDueAmount: 200,
    totalRemaining: 0,
    totalRefundedAmount: 0,
  );

  test('contract status is Active for future active booking', () {
    expect(
      contractStatusFor(booking: activeBooking, returns: const []),
      'Active',
    );
  });

  test('contract status is Terminated when return exists', () {
    expect(
      contractStatusFor(booking: returnedBooking, returns: [apartmentReturn]),
      'Terminated',
    );
  });

  test('contractsFromBookings maps booking totals', () {
    final contracts = contractsFromBookings([activeBooking], const []);

    expect(contracts.length, 1);
    expect(contracts.first.bookingId, 5);
    expect(contracts.first.totalAmount, 500);
    expect(contracts.first.status, 'Active');
    expect(contracts.first.bookingType, 0);
    expect(contracts.first.initialPayment, 0);
  });

  test('contractsFromBookings maps initial payment from rentalPrice', () {
    final paidBooking = activeBooking.copyWith(rentalPrice: 200);

    final contracts = contractsFromBookings([paidBooking], const []);

    expect(contracts.single.initialPayment, 200);
  });

  test('contractsFromBookings preserves daily booking type', () {
    final dailyBooking = activeBooking.copyWith(bookingType: 1);

    final contracts = contractsFromBookings([dailyBooking], const []);

    expect(contracts.single.bookingType, 1);
  });
}
