class CustomerModel {
  const CustomerModel({
    required this.customerId,
    required this.name,
    required this.phone,
    required this.nationalNum,
    required this.numberOfRentedApartments,
    this.idNumber,
    this.apartment,
    this.startDate,
    this.endDate,
  });

  final int customerId;
  final String name;
  final String phone;
  final String nationalNum;
  final int numberOfRentedApartments;
  final String? idNumber;
  final String? apartment;
  final String? startDate;
  final String? endDate;

  // Getter for compatibility
  int get id => customerId;

  CustomerModel copyWith({
    int? customerId,
    String? name,
    String? phone,
    String? nationalNum,
    int? numberOfRentedApartments,
    String? idNumber,
    String? apartment,
    String? startDate,
    String? endDate,
  }) {
    return CustomerModel(
      customerId: customerId ?? this.customerId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      nationalNum: nationalNum ?? this.nationalNum,
      numberOfRentedApartments:
          numberOfRentedApartments ?? this.numberOfRentedApartments,
      idNumber: idNumber ?? this.idNumber,
      apartment: apartment ?? this.apartment,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
