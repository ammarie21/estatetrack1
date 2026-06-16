/// Links a physical checkout to a [RentalBookingModel] (bookingId) for workflow.
/// Final settlement rows live in [RentalTransactionModel].
class ApartmentReturnModel {
  const ApartmentReturnModel({
    required this.returnId,
    this.bookingId,
    required this.actualReturnDate,
    required this.actualRentalDays,
    required this.additionalCharges,
    required this.actualTotalDueAmount,
    this.totalRemaining = 0,
    this.totalRefundedAmount = 0,
    this.finalCheckNotes,
    this.finalPaymentCollected = 0,
  });

  final int returnId;
  final int? bookingId;
  final DateTime actualReturnDate;
  final int actualRentalDays;
  final double additionalCharges;
  final double actualTotalDueAmount;
  final double totalRemaining;
  final double totalRefundedAmount;
  final String? finalCheckNotes;
  final double finalPaymentCollected;

  ApartmentReturnModel copyWith({
    int? returnId,
    int? bookingId,
    DateTime? actualReturnDate,
    int? actualRentalDays,
    double? additionalCharges,
    double? actualTotalDueAmount,
    double? totalRemaining,
    double? totalRefundedAmount,
    String? finalCheckNotes,
    double? finalPaymentCollected,
    bool clearBookingId = false,
  }) {
    return ApartmentReturnModel(
      returnId: returnId ?? this.returnId,
      bookingId: clearBookingId ? null : (bookingId ?? this.bookingId),
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      actualRentalDays: actualRentalDays ?? this.actualRentalDays,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      actualTotalDueAmount: actualTotalDueAmount ?? this.actualTotalDueAmount,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      totalRefundedAmount: totalRefundedAmount ?? this.totalRefundedAmount,
      finalCheckNotes: finalCheckNotes ?? this.finalCheckNotes,
      finalPaymentCollected:
          finalPaymentCollected ?? this.finalPaymentCollected,
    );
  }
}
