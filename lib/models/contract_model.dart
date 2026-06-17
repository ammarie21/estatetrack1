class ContractModel {
  const ContractModel({
    required this.contractId,
    required this.customerId,
    required this.apartmentId,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.status,
    required this.bookingId,
    this.bookingType = 0,
    this.notes,
    this.initialPayment = 0,
  });

  final int contractId;
  final int customerId;
  final int apartmentId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final String status; // e.g., 'Active', 'Expired', 'Terminated'
  final int bookingId; // Link to existing booking
  final int bookingType; // 0 = monthly, 1 = daily
  final String? notes;
  final double initialPayment;

  ContractModel copyWith({
    int? contractId,
    int? customerId,
    int? apartmentId,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    String? status,
    int? bookingId,
    int? bookingType,
    String? notes,
    double? initialPayment,
  }) {
    return ContractModel(
      contractId: contractId ?? this.contractId,
      customerId: customerId ?? this.customerId,
      apartmentId: apartmentId ?? this.apartmentId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      bookingType: bookingType ?? this.bookingType,
      notes: notes ?? this.notes,
      initialPayment: initialPayment ?? this.initialPayment,
    );
  }
}
