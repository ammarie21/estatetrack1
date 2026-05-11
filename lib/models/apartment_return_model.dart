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
    this.finalCheckNotes,
  });

  final int returnId;
  final int? bookingId;
  final DateTime actualReturnDate;
  final int actualRentalDays;
  final double additionalCharges;
  final double actualTotalDueAmount;
  final String? finalCheckNotes;

  ApartmentReturnModel copyWith({
    int? returnId,
    int? bookingId,
    DateTime? actualReturnDate,
    int? actualRentalDays,
    double? additionalCharges,
    double? actualTotalDueAmount,
    String? finalCheckNotes,
    bool clearBookingId = false,
  }) {
    return ApartmentReturnModel(
      returnId: returnId ?? this.returnId,
      bookingId: clearBookingId ? null : (bookingId ?? this.bookingId),
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      actualRentalDays: actualRentalDays ?? this.actualRentalDays,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      actualTotalDueAmount: actualTotalDueAmount ?? this.actualTotalDueAmount,
      finalCheckNotes: finalCheckNotes ?? this.finalCheckNotes,
    );
  }
}