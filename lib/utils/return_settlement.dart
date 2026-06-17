class ReturnSettlement {
  const ReturnSettlement({
    required this.totalDueAmount,
    required this.paidOnBooking,
    required this.finalPaymentCollected,
    required this.totalPaid,
    required this.remaining,
    required this.refunded,
  });

  final double totalDueAmount;
  final double paidOnBooking;
  final double finalPaymentCollected;
  final double totalPaid;
  final double remaining;
  final double refunded;

  factory ReturnSettlement.compute({
    required double totalDueAmount,
    required double paidOnBooking,
    double finalPaymentCollected = 0,
  }) {
    final totalPaid = paidOnBooking + finalPaymentCollected;
    final remaining = (totalDueAmount - totalPaid).clamp(0.0, double.infinity);
    final refunded = (totalPaid - totalDueAmount).clamp(0.0, double.infinity);
    return ReturnSettlement(
      totalDueAmount: totalDueAmount,
      paidOnBooking: paidOnBooking,
      finalPaymentCollected: finalPaymentCollected,
      totalPaid: totalPaid,
      remaining: remaining,
      refunded: refunded,
    );
  }
}

int inclusiveDaysBetween(DateTime start, DateTime end) {
  final startDay = DateTime(start.year, start.month, start.day);
  final endDay = DateTime(end.year, end.month, end.day);
  return endDay.difference(startDay).inDays + 1;
}

double proratedAgreementAmount({
  required double agreementTotal,
  required int agreementDays,
  required int actualRentalDays,
}) {
  if (agreementDays <= 0 || actualRentalDays <= 0) {
    return agreementTotal;
  }
  if (actualRentalDays >= agreementDays) {
    return agreementTotal;
  }
  return agreementTotal * (actualRentalDays / agreementDays);
}
