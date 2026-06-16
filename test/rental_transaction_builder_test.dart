import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final booking = RentalBookingModel(
    bookingId: 3,
    userId: 1,
    customerId: 1,
    apartmentId: 1,
    startDate: DateTime(2026, 5, 16),
    endDate: DateTime(2026, 5, 20),
    initialTotalDueAmount: 60,
    bookingType: 2,
    periodFee: 80,
    rentalPrice: 20,
    paymentDetails: 'cash',
  );

  final relatedReturn = ApartmentReturnModel(
    returnId: 2,
    bookingId: 3,
    actualReturnDate: DateTime(2026, 5, 20),
    actualRentalDays: 4,
    additionalCharges: 0,
    actualTotalDueAmount: 60,
    totalRemaining: 40,
    totalRefundedAmount: 0,
  );

  test('paidAmountForBooking prefers rentalPrice', () {
    expect(paidAmountForBooking(booking), 20);
  });

  test('buildTransactionsFromBookings includes paid bookings only', () {
    final unpaid = booking.copyWith(bookingId: 9, rentalPrice: 0, paymentDetails: '');
    final rows = buildTransactionsFromBookings([booking, unpaid], [relatedReturn]);

    expect(rows.length, 1);
    expect(rows.first.bookingId, 3);
    expect(rows.first.paidInitialTotalDueAmount, 20);
    expect(rows.first.totalRemaining, 40);
    expect(rows.first.returnId, 2);
    expect(rows.first.transactionStatus, 'Partial');
  });

  test('transactionStatusFor handles paid partial and pending', () {
    expect(transactionStatusFor(paid: 0, total: 60), 'Pending');
    expect(transactionStatusFor(paid: 20, total: 60), 'Partial');
    expect(transactionStatusFor(paid: 60, total: 60), 'Paid');
  });
}
