class BuildingModel {
  const BuildingModel({
    required this.buildingId,
    required this.name,
    required this.floorsCount,
    required this.constructionYear,
    required this.totalApartments,
    required this.location,
  });

  final int buildingId;
  final String name;
  final int floorsCount;
  final int constructionYear;
  final int totalApartments;
  final String location;

  BuildingModel copyWith({
    int? buildingId,
    String? name,
    int? floorsCount,
    int? constructionYear,
    int? totalApartments,
    String? location,
  }) {
    return BuildingModel(
      buildingId: buildingId ?? this.buildingId,
      name: name ?? this.name,
      floorsCount: floorsCount ?? this.floorsCount,
      constructionYear: constructionYear ?? this.constructionYear,
      totalApartments: totalApartments ?? this.totalApartments,
      location: location ?? this.location,
    );
  }
}