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

  test('buildTransactionsFromBookings includes all bookings', () {
    final unpaid = booking.copyWith(
      bookingId: 9,
      rentalPrice: 0,
      paymentDetails: '',
    );
    final rows = buildTransactionsFromBookings(
      [booking, unpaid],
      [relatedReturn],
    );

    expect(rows.length, 2);
    final paidRow = rows.firstWhere((row) => row.bookingId == 3);
    expect(paidRow.paidInitialTotalDueAmount, 20);
    expect(paidRow.totalRemaining, 40);
    expect(paidRow.returnId, 2);
    expect(paidRow.transactionStatus, 'Partial');

    final pendingRow = rows.firstWhere((row) => row.bookingId == 9);
    expect(pendingRow.transactionStatus, 'Pending');
  });

  test('transactionStatusFor handles paid partial pending closed and refunded', () {
    expect(transactionStatusFor(paid: 0, total: 60), 'Pending');
    expect(transactionStatusFor(paid: 20, total: 60), 'Partial');
    expect(transactionStatusFor(paid: 60, total: 60), 'Paid');
    expect(
      transactionStatusFor(
        paid: 60,
        total: 60,
        remaining: 0,
        checkedOut: true,
      ),
      'Closed',
    );
    expect(
      transactionStatusFor(
        paid: 3000,
        total: 1150,
        remaining: 0,
        refunded: 1850,
        checkedOut: true,
      ),
      'Refunded',
    );
    expect(
      transactionStatusFor(
        paid: 20,
        total: 60,
        remaining: 40,
        checkedOut: true,
      ),
      'Partial',
    );
  });

  test('buildTransactionsFromBookings marks refunded checkout', () {
    final refundReturn = relatedReturn.copyWith(
      actualTotalDueAmount: 1150,
      totalRemaining: 0,
      totalRefundedAmount: 1850,
    );
    final overpaidBooking = booking.copyWith(rentalPrice: 3000);
    final rows = buildTransactionsFromBookings(
      [overpaidBooking],
      [refundReturn],
    );

    expect(rows.single.transactionStatus, 'Refunded');
    expect(rows.single.totalRefundedAmount, 1850);
  });
}
