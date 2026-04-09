class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.idNumber,
    required this.apartment,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final String name;
  final String phone;
  final String idNumber;
  final String apartment;
  final String startDate;
  final String endDate;

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? idNumber,
    String? apartment,
    String? startDate,
    String? endDate,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      idNumber: idNumber ?? this.idNumber,
      apartment: apartment ?? this.apartment,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
