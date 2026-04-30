class RentalTransactionModel {
  const RentalTransactionModel({
    required this.transactionId,
    required this.bookingId,
    required this.returnId,
    required this.paidInitialTotalDueAmount,
    required this.actualTotalDueAmount,
    required this.totalRemaining,
    required this.totalRefundedAmount,
    required this.transactionStatus,
    required this.updatedTransactionDate,
    this.paymentDetails,
  });

  final int transactionId;
  final int bookingId;
  final int returnId;
  final double paidInitialTotalDueAmount;
  final double actualTotalDueAmount;
  final double totalRemaining;
  final double totalRefundedAmount;
  final String transactionStatus; // e.g. 'Paid', 'Partial', 'Refunded', 'Pending'
  final DateTime updatedTransactionDate;
  final String? paymentDetails;

  RentalTransactionModel copyWith({
    int? transactionId,
    int? bookingId,
    int? returnId,
    double? paidInitialTotalDueAmount,
    double? actualTotalDueAmount,
    double? totalRemaining,
    double? totalRefundedAmount,
    String? transactionStatus,
    DateTime? updatedTransactionDate,
    String? paymentDetails,
  }) {
    return RentalTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      bookingId: bookingId ?? this.bookingId,
      returnId: returnId ?? this.returnId,
      paidInitialTotalDueAmount:
          paidInitialTotalDueAmount ?? this.paidInitialTotalDueAmount,
      actualTotalDueAmount: actualTotalDueAmount ?? this.actualTotalDueAmount,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      totalRefundedAmount: totalRefundedAmount ?? this.totalRefundedAmount,
      transactionStatus: transactionStatus ?? this.transactionStatus,
      updatedTransactionDate:
          updatedTransactionDate ?? this.updatedTransactionDate,
      paymentDetails: paymentDetails ?? this.paymentDetails,
    );
  }
}
