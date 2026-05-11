class ApartmentTypeModel {
  const ApartmentTypeModel({
    required this.typeId,
    required this.apartmentType,
  });

  final int typeId;
  final String apartmentType;

  ApartmentTypeModel copyWith({
    int? typeId,
    String? apartmentType,
  }) {
    return ApartmentTypeModel(
      typeId: typeId ?? this.typeId,
      apartmentType: apartmentType ?? this.apartmentType,
    );
  }
}