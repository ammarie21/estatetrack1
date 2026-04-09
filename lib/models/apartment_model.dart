class ApartmentModel {
  const ApartmentModel({
    required this.id,
    required this.number,
    required this.location,
    required this.rent,
    required this.bedrooms,
    required this.bathrooms,
    required this.isOccupied,
  });

  final int id;
  final String number;
  final String location;
  final double rent;
  final int bedrooms;
  final int bathrooms;
  final bool isOccupied;

  ApartmentModel copyWith({
    int? id,
    String? number,
    String? location,
    double? rent,
    int? bedrooms,
    int? bathrooms,
    bool? isOccupied,
  }) {
    return ApartmentModel(
      id: id ?? this.id,
      number: number ?? this.number,
      location: location ?? this.location,
      rent: rent ?? this.rent,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      isOccupied: isOccupied ?? this.isOccupied,
    );
  }
}
