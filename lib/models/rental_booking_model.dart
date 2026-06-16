/// BookingType values: 0 = monthly, 1 = daily (matches ERD short type)
class RentalBookingModel {
  const RentalBookingModel({
    required this.bookingId,
    required this.userId,
    required this.customerId,
    required this.apartmentId,
    required this.startDate,
    required this.endDate,
    required this.initialTotalDueAmount,
    required this.bookingType,
    required this.periodFee,
    this.rentalPrice = 0,
    this.paymentDetails,
    this.isActive = true,
    this.initialCheckNotes,
  });

  final int bookingId;
  final int userId;
  final int customerId;
  final int apartmentId;
  final DateTime startDate;
  final DateTime endDate;
  final double initialTotalDueAmount;
  final int bookingType; // 0 = monthly, 1 = daily
  final double periodFee;
  final double rentalPrice;
  final String? paymentDetails;
  final bool isActive;
  final String? initialCheckNotes;

  RentalBookingModel copyWith({
    int? bookingId,
    int? userId,
    int? customerId,
    int? apartmentId,
    DateTime? startDate,
    DateTime? endDate,
    double? initialTotalDueAmount,
    int? bookingType,
    double? periodFee,
    double? rentalPrice,
    String? paymentDetails,
    bool? isActive,
    String? initialCheckNotes,
  }) {
    return RentalBookingModel(
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      apartmentId: apartmentId ?? this.apartmentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      initialTotalDueAmount:
          initialTotalDueAmount ?? this.initialTotalDueAmount,
      bookingType: bookingType ?? this.bookingType,
      periodFee: periodFee ?? this.periodFee,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      paymentDetails: paymentDetails ?? this.paymentDetails,
      isActive: isActive ?? this.isActive,
      initialCheckNotes: initialCheckNotes ?? this.initialCheckNotes,
    );
  }
}
