import 'package:estatetrack1/data/rental_transaction_builder.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';

/// O(1) lookup maps built once per snapshot refresh.
class EstateIndexes {
  EstateIndexes._({
    required Map<int, CustomerModel> customersById,
    required Map<int, BuildingModel> buildingsById,
    required Map<int, ApartmentModel> apartmentsById,
    required Map<int, ApartmentTypeModel> typesById,
    required Map<int, RentalBookingModel> bookingsById,
    required Map<int, ApartmentReturnModel> returnsByBookingId,
    required Map<int, RentalTransactionModel> transactionsByBookingId,
  }) : _customersById = customersById,
       _buildingsById = buildingsById,
       _apartmentsById = apartmentsById,
       _typesById = typesById,
       _bookingsById = bookingsById,
       _returnsByBookingId = returnsByBookingId,
       _transactionsByBookingId = transactionsByBookingId;

  final Map<int, CustomerModel> _customersById;
  final Map<int, BuildingModel> _buildingsById;
  final Map<int, ApartmentModel> _apartmentsById;
  final Map<int, ApartmentTypeModel> _typesById;
  final Map<int, RentalBookingModel> _bookingsById;
  final Map<int, ApartmentReturnModel> _returnsByBookingId;
  final Map<int, RentalTransactionModel> _transactionsByBookingId;

  factory EstateIndexes.fromLists({
    required List<CustomerModel> customers,
    required List<BuildingModel> buildings,
    required List<ApartmentModel> apartments,
    List<ApartmentTypeModel> apartmentTypes = const [],
    required List<RentalBookingModel> bookings,
    List<ApartmentReturnModel> returns = const [],
    List<RentalTransactionModel> transactions = const [],
  }) {
    return EstateIndexes._(
      customersById: {for (final c in customers) c.customerId: c},
      buildingsById: {for (final b in buildings) b.buildingId: b},
      apartmentsById: {for (final a in apartments) a.apartmentId: a},
      typesById: {for (final t in apartmentTypes) t.typeId: t},
      bookingsById: {for (final b in bookings) b.bookingId: b},
      returnsByBookingId: {
        for (final r in returns)
          if (r.bookingId != null) r.bookingId!: r,
      },
      transactionsByBookingId: {for (final t in transactions) t.bookingId: t},
    );
  }

  CustomerModel? customer(int id) => _customersById[id];

  BuildingModel? building(int id) => _buildingsById[id];

  ApartmentModel? apartment(int id) => _apartmentsById[id];

  ApartmentTypeModel? apartmentType(int id) => _typesById[id];

  RentalBookingModel? booking(int id) => _bookingsById[id];

  ApartmentReturnModel? returnForBooking(int bookingId) =>
      _returnsByBookingId[bookingId];

  RentalTransactionModel? transactionForBooking(int bookingId) =>
      _transactionsByBookingId[bookingId];

  String customerName(int customerId) =>
      customer(customerId)?.name ?? 'Customer #$customerId';

  String apartmentLabel(int apartmentId) {
    final apt = apartment(apartmentId);
    if (apt == null) return 'Apartment #$apartmentId';
    final buildingName =
        building(apt.buildingId)?.name ?? 'Building #${apt.buildingId}';
    final apartmentNumber = apt.number?.trim().isNotEmpty == true
        ? apt.number!.trim()
        : 'Apartment #${apt.apartmentId}';
    final location = apt.location?.trim();
    final availability = apt.isAvailable ? 'Vacant' : 'Occupied';
    return [
      '$buildingName - $apartmentNumber',
      if (location != null && location.isNotEmpty) location,
      availability,
    ].join(' - ');
  }

  String apartmentNumber(int apartmentId) =>
      apartment(apartmentId)?.number ?? '#$apartmentId';

  double paidForBooking(int? bookingId) {
    if (bookingId == null) return 0;
    final row = booking(bookingId);
    if (row == null) return 0;
    return paidAmountForBooking(row);
  }

  Iterable<CustomerModel> get allCustomers => _customersById.values;

  Iterable<ApartmentModel> get allApartments => _apartmentsById.values;

  Iterable<RentalBookingModel> get allBookings => _bookingsById.values;
}

class BackendRecordCounts {
  const BackendRecordCounts({
    required this.customers,
    required this.buildings,
    required this.apartments,
    required this.bookings,
    required this.returns,
    required this.maintenance,
    required this.staff,
  });

  final int customers;
  final int buildings;
  final int apartments;
  final int bookings;
  final int returns;
  final int maintenance;
  final int staff;

  int get total =>
      customers +
      buildings +
      apartments +
      bookings +
      returns +
      maintenance +
      staff;
}
