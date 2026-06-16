import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/building_model.dart';

String apartmentDisplayLabel(
  ApartmentModel apartment,
  List<BuildingModel> buildings,
) {
  final building = buildings
      .where((item) => item.buildingId == apartment.buildingId)
      .firstOrNull;
  final buildingName = building?.name ?? 'Building #${apartment.buildingId}';
  final apartmentNumber = apartment.number?.trim().isNotEmpty == true
      ? apartment.number!.trim()
      : 'Apartment #${apartment.apartmentId}';
  final location = apartment.location?.trim();
  final availability = apartment.isAvailable ? 'Vacant' : 'Occupied';

  return [
    '$buildingName - $apartmentNumber',
    if (location != null && location.isNotEmpty) location,
    availability,
  ].join(' - ');
}

String apartmentDisplayLabelById(
  int apartmentId,
  List<ApartmentModel> apartments,
  List<BuildingModel> buildings,
) {
  final apartment = apartments
      .where((item) => item.apartmentId == apartmentId)
      .firstOrNull;
  if (apartment == null) return 'Apartment #$apartmentId';
  return apartmentDisplayLabel(apartment, buildings);
}
