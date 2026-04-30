class ApartmentModel {
  const ApartmentModel({
    required this.apartmentId,
    required this.buildingId,
    required this.typeId,
    required this.sizeM2,
    required this.rentPricePerMonth,
    required this.rentPricePerDay,
    required this.isAvailable,
    required this.bedrooms,
    required this.bathrooms,
    required this.hasBalcony,
    required this.furnished,
    required this.hasInternet,
    required this.parking,
    required this.elevator,
    this.notes,
    this.description,
    this.number,
    this.location,
  });

  final int apartmentId;
  final int buildingId;
  final int typeId;
  final int sizeM2;
  final double rentPricePerMonth;
  final double rentPricePerDay;
  final bool isAvailable;
  final int bedrooms;
  final int bathrooms;
  final bool hasBalcony;
  final bool furnished;
  final bool hasInternet;
  final bool parking;
  final bool elevator;
  final String? notes;
  final String? description;
  final String? number;
  final String? location;

  // Getters for compatibility
  int get id => apartmentId;
  double get rent => rentPricePerMonth;
  bool get isOccupied => !isAvailable;

  ApartmentModel copyWith({
    int? apartmentId,
    int? buildingId,
    int? typeId,
    int? sizeM2,
    double? rentPricePerMonth,
    double? rentPricePerDay,
    bool? isAvailable,
    int? bedrooms,
    int? bathrooms,
    bool? hasBalcony,
    bool? furnished,
    bool? hasInternet,
    bool? parking,
    bool? elevator,
    String? notes,
    String? description,
    String? number,
    String? location,
  }) {
    return ApartmentModel(
      apartmentId: apartmentId ?? this.apartmentId,
      buildingId: buildingId ?? this.buildingId,
      typeId: typeId ?? this.typeId,
      sizeM2: sizeM2 ?? this.sizeM2,
      rentPricePerMonth: rentPricePerMonth ?? this.rentPricePerMonth,
      rentPricePerDay: rentPricePerDay ?? this.rentPricePerDay,
      isAvailable: isAvailable ?? this.isAvailable,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      furnished: furnished ?? this.furnished,
      hasInternet: hasInternet ?? this.hasInternet,
      parking: parking ?? this.parking,
      elevator: elevator ?? this.elevator,
      notes: notes ?? this.notes,
      description: description ?? this.description,
      number: number ?? this.number,
      location: location ?? this.location,
    );
  }
}
