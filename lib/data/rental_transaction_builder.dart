import 'dart:math' as math;

import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

const double _moneyEpsilon = 0.009;

bool _isZero(double value) => value.abs() <= _moneyEpsilon;

bool _isPositive(double value) => value > _moneyEpsilon;

List<RentalTransactionModel> buildTransactionsFromBookings(
  List<RentalBookingModel> bookings,
  List<ApartmentReturnModel> returns,
) {
  return bookings.map((booking) {
    final relatedReturn = returns
        .where((r) => r.bookingId == booking.bookingId)
        .firstOrNull;
    final paid = paidAmountForBooking(booking);
    final total =
        relatedReturn?.actualTotalDueAmount ?? booking.initialTotalDueAmount;
    final remaining = relatedReturn != null
        ? relatedReturn.totalRemaining
        : math.max(0.0, total - paid);
    final refunded =
        relatedReturn != null && relatedReturn.totalRefundedAmount > 0
        ? relatedReturn.totalRefundedAmount
        : (paid > total ? paid - total : 0.0);

    return RentalTransactionModel(
      transactionId: booking.bookingId,
      bookingId: booking.bookingId,
      returnId: relatedReturn?.returnId,
      paidInitialTotalDueAmount: paid,
      actualTotalDueAmount: total,
      totalRemaining: remaining,
      totalRefundedAmount: refunded,
      transactionStatus: transactionStatusFor(
        paid: paid,
        total: total,
        remaining: remaining,
        refunded: refunded,
        checkedOut: relatedReturn != null,
      ),
      updatedTransactionDate:
          relatedReturn?.actualReturnDate ?? booking.startDate,
      paymentDetails: booking.paymentDetails ?? booking.initialCheckNotes,
    );
  }).toList()..sort(
    (a, b) => b.updatedTransactionDate.compareTo(a.updatedTransactionDate),
  );
}

double paidAmountForBooking(RentalBookingModel booking) {
  if (booking.rentalPrice > 0) return booking.rentalPrice;
  // Legacy rows saved before rentalPrice mapping stored paid amount on periodFee.
  if ((booking.paymentDetails ?? '').isNotEmpty &&
      booking.periodFee > 0 &&
      booking.periodFee <= booking.initialTotalDueAmount) {
    return booking.periodFee;
  }
  return 0;
}

String transactionStatusFor({
  required double paid,
  required double total,
  double remaining = 0,
  double refunded = 0,
  bool checkedOut = false,
}) {
  if (checkedOut) {
    if (_isPositive(refunded)) return 'Refunded';
    if (_isPositive(remaining)) return 'Partial';
    return 'Closed';
  }

  if (_isZero(paid)) return 'Pending';
  if (_isPositive(remaining) || paid + _moneyEpsilon < total) return 'Partial';
  return 'Paid';
}
