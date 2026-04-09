class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
  });

  final int id;
  final String category;
  final double amount;
  final String date;

  ExpenseModel copyWith({
    int? id,
    String? category,
    double? amount,
    String? date,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
