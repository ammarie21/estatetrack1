class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.customer,
    required this.apartment,
    required this.amount,
    required this.date,
  });

  final int id;
  final String customer;
  final String apartment;
  final double amount;
  final String date;

  PaymentModel copyWith({
    int? id,
    String? customer,
    String? apartment,
    double? amount,
    String? date,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      apartment: apartment ?? this.apartment,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}