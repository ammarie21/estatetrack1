class ApartmentReturnModel {
  const ApartmentReturnModel({
    required this.returnId,
    required this.actualReturnDate,
    required this.actualRentalDays,
    required this.additionalCharges,
    required this.actualTotalDueAmount,
    this.finalCheckNotes,
  });

  final int returnId;
  final DateTime actualReturnDate;
  final int actualRentalDays;
  final double additionalCharges;
  final double actualTotalDueAmount;
  final String? finalCheckNotes;

  ApartmentReturnModel copyWith({
    int? returnId,
    DateTime? actualReturnDate,
    int? actualRentalDays,
    double? additionalCharges,
    double? actualTotalDueAmount,
    String? finalCheckNotes,
  }) {
    return ApartmentReturnModel(
      returnId: returnId ?? this.returnId,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      actualRentalDays: actualRentalDays ?? this.actualRentalDays,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      actualTotalDueAmount: actualTotalDueAmount ?? this.actualTotalDueAmount,
      finalCheckNotes: finalCheckNotes ?? this.finalCheckNotes,
    );
  }
}