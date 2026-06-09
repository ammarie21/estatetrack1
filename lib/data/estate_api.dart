import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/expense_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/models/rental_transaction_model.dart';
import 'package:estatetrack1/models/user_model.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      statusCode == null ? message : 'API $statusCode: $message';
}

class EstateSnapshot {
  const EstateSnapshot({
    required this.customers,
    required this.buildings,
    required this.apartments,
    required this.bookings,
    required this.contracts,
    required this.returns,
    required this.rentalTransactions,
    required this.expenses,
    required this.maintenance,
  });

  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
  final List<ExpenseModel> expenses;
  final List<MaintenanceModel> maintenance;
}

class EstateApi {
  EstateApi._()
    : _client = IOClient(
        HttpClient()
          ..badCertificateCallback = (certificate, host, port) {
            return host == 'localhost' || host == '127.0.0.1';
          },
      );

  static final EstateApi instance = EstateApi._();

  static const String baseUrl = 'https://localhost:7274';
  static const Duration _timeout = Duration(seconds: 25);

  final http.Client _client;
  AccountModel? currentUser;

  Future<AccountModel?> login({
    required int userId,
    required String password,
  }) async {
    final response = await _post(
      '/api/Users/Login',
      {'userID': userId, 'password': password.trim()},
      expected: const {200},
      allowAuthFailure: true,
    );

    if (response == null) return null;

    final body = _decodeMap(response.body);
    final account = AccountModel(
      id: _int(body['userID']).toString(),
      name: _string(body['name'], 'User $userId'),
      email: '',
      phone: '',
      password: '',
      role: userId == 1 ? 'Admin' : 'User',
    );
    currentUser = account;
    return account;
  }

  void logout() {
    currentUser = null;
  }

  Future<EstateSnapshot> loadSnapshot() async {
    final results = await Future.wait([
      _getList('/api/Customers/All', _customerFromJson),
      _getList('/api/Buildings/All', _buildingFromJson),
      _getList('/api/Apartments/All', _apartmentFromJson),
      _getList('/api/RentalBookings/All', _bookingFromJson),
      _getList('/api/ApartmentReturns/All', _returnFromJson),
      _getList('/api/Maintenances/All', _maintenanceFromJson),
    ]);

    final customers = results[0] as List<CustomerModel>;
    final buildings = results[1] as List<BuildingModel>;
    final apartments = results[2] as List<ApartmentModel>;
    final bookings = results[3] as List<RentalBookingModel>;
    final returns = results[4] as List<ApartmentReturnModel>;
    final maintenance = results[5] as List<MaintenanceModel>;
    final contracts = bookings.map(_contractFromBooking).toList();

    return EstateSnapshot(
      customers: _decorateCustomers(customers, bookings, apartments),
      buildings: buildings,
      apartments: apartments,
      bookings: bookings,
      contracts: contracts,
      returns: returns,
      rentalTransactions: _transactionsFromBookings(bookings, returns),
      expenses: const [],
      maintenance: maintenance,
    );
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final response = await _post('/api/Customers', _customerToJson(customer));
    final saved = _customerFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.customerId, 'Customer');
    return saved;
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final response = await _put(
      '/api/Customers/${customer.customerId}',
      _customerToJson(customer),
    );
    return _customerFromJson(_decodeMap(response.body));
  }

  Future<void> deleteCustomer(int id) async {
    await _delete('/api/Customers/$id');
  }

  Future<BuildingModel> createBuilding(BuildingModel building) async {
    final response = await _post('/api/Buildings', _buildingToJson(building));
    final saved = _buildingFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.buildingId, 'Building');
    return saved;
  }

  Future<BuildingModel> updateBuilding(BuildingModel building) async {
    final response = await _put(
      '/api/Buildings/${building.buildingId}',
      _buildingToJson(building),
    );
    return _buildingFromJson(_decodeMap(response.body));
  }

  Future<void> deleteBuilding(int id) async {
    await _delete('/api/Buildings/$id');
  }

  Future<ApartmentModel> createApartment(ApartmentModel apartment) async {
    final response = await _post(
      '/api/Apartments',
      _apartmentToJson(apartment),
    );
    final saved = _apartmentFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.apartmentId, 'Apartment');
    return saved;
  }

  Future<ApartmentModel> updateApartment(ApartmentModel apartment) async {
    final response = await _put(
      '/api/Apartments/${apartment.apartmentId}',
      _apartmentToJson(apartment),
    );
    return _apartmentFromJson(
      _decodeMap(response.body),
    ).copyWith(number: apartment.number, location: apartment.location);
  }

  Future<void> deleteApartment(int id) async {
    await _delete('/api/Apartments/$id');
  }

  Future<List<UserModel>> getUsers() =>
      _getList('/api/Users/All', _userFromJson);

  Future<UserModel> createUser(UserModel user) async {
    final response = await _post('/api/Users', _userToJson(user));
    final saved = _userFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.userId, 'User');
    return saved;
  }

  Future<UserModel> updateUser(UserModel user) async {
    final response = await _put('/api/Users/${user.userId}', _userToJson(user));
    return _userFromJson(_decodeMap(response.body));
  }

  Future<void> deleteUser(int id) async {
    await _delete('/api/Users/$id');
  }

  Future<RentalBookingModel> createBooking(RentalBookingModel booking) async {
    final response = await _post(
      '/api/RentalBookings',
      _bookingToJson(booking),
    );
    final saved = _bookingFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.bookingId, 'Rental booking');
    return saved;
  }

  Future<RentalBookingModel> updateBooking(RentalBookingModel booking) async {
    final response = await _put(
      '/api/RentalBookings/${booking.bookingId}',
      _bookingToJson(booking),
    );
    return _bookingFromJson(_decodeMap(response.body));
  }

  Future<void> deleteBooking(int id) async {
    await _delete('/api/RentalBookings/$id');
  }

  Future<ApartmentReturnModel> createReturn(
    ApartmentReturnModel model, {
    required int userId,
  }) async {
    final response = await _post(
      '/api/ApartmentReturns',
      _returnToJson(model, userId: userId),
    );
    final saved = _returnFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.returnId, 'Apartment return');
    return saved;
  }

  Future<ApartmentReturnModel> updateReturn(
    ApartmentReturnModel model, {
    required int userId,
  }) async {
    final response = await _put(
      '/api/ApartmentReturns/${model.returnId}',
      _returnToJson(model, userId: userId),
    );
    return _returnFromJson(_decodeMap(response.body));
  }

  Future<void> deleteReturn(int id) async {
    await _delete('/api/ApartmentReturns/$id');
  }

  Future<MaintenanceModel> createMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final response = await _post(
      '/api/Maintenances',
      _maintenanceToJson(maintenance),
    );
    final saved = _maintenanceFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.id, 'Maintenance');
    return saved;
  }

  Future<MaintenanceModel> updateMaintenance(
    MaintenanceModel maintenance,
  ) async {
    final response = await _put(
      '/api/Maintenances/${maintenance.id}',
      _maintenanceToJson(maintenance),
    );
    return _maintenanceFromJson(_decodeMap(response.body));
  }

  Future<void> deleteMaintenance(int id) async {
    await _delete('/api/Maintenances/$id');
  }

  Future<http.Response?> _post(
    String path,
    Map<String, dynamic> body, {
    Set<int> expected = const {200, 201},
    bool allowAuthFailure = false,
  }) async {
    final response = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    if (allowAuthFailure &&
        (response.statusCode == 401 || response.statusCode == 404)) {
      return null;
    }
    _ensureStatus(response, expected);
    return response;
  }

  Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    final response = await _client
        .put(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return response;
  }

  Future<void> _delete(String path) async {
    final response = await _client
        .delete(_uri(path), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
  }

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _client
        .get(_uri(path), headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 404) return [];
    _ensureStatus(response, const {200});

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw ApiException('Expected list response from $path');
    }
    return decoded
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _headers => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  void _ensureStatus(http.Response response, Set<int> expected) {
    if (expected.contains(response.statusCode)) return;
    throw ApiException(
      _errorMessage(response.body),
      statusCode: response.statusCode,
    );
  }

  void _requirePositiveId(int id, String resourceName) {
    if (id > 0) return;
    throw ApiException('$resourceName was not saved by the backend.');
  }

  static Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return Map<String, dynamic>.from(decoded as Map);
  }

  static String _errorMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Request failed';
    if (!trimmed.startsWith('{')) return trimmed.replaceAll('"', '');
    try {
      final map = _decodeMap(trimmed);
      return _string(map['detail'], _string(map['title'], 'Request failed'));
    } catch (_) {
      return trimmed;
    }
  }
}

UserModel _userFromJson(Map<String, dynamic> json) {
  return UserModel(
    userId: _int(json['userID']),
    name: _string(json['name']),
    phone: _string(json['phone']),
    password: _string(json['password']),
  );
}

Map<String, dynamic> _userToJson(UserModel user) {
  return {
    'userID': user.userId,
    'name': user.name,
    'phone': user.phone,
    'password': user.password,
  };
}

CustomerModel _customerFromJson(Map<String, dynamic> json) {
  return CustomerModel(
    customerId: _int(json['customerID']),
    name: _string(json['name']),
    phone: _string(json['phone']),
    nationalNum: _string(json['nationalNum']),
    numberOfRentedApartments: _int(json['numberOfRentedApartments']),
    idNumber: _string(json['nationalNum']).isEmpty
        ? null
        : _string(json['nationalNum']),
  );
}

Map<String, dynamic> _customerToJson(CustomerModel customer) {
  return {
    'customerID': customer.customerId,
    'name': customer.name,
    'phone': customer.phone,
    'nationalNum': customer.nationalNum,
    'numberOfRentedApartments': customer.numberOfRentedApartments,
  };
}

BuildingModel _buildingFromJson(Map<String, dynamic> json) {
  return BuildingModel(
    buildingId: _int(json['buildingID']),
    name: _string(json['name']),
    floorsCount: _int(json['floorsCount']),
    constructionYear: _int(json['constructionYear']),
    totalApartments: _int(json['totalApartments']),
    location: _string(json['location']),
  );
}

Map<String, dynamic> _buildingToJson(BuildingModel building) {
  return {
    'buildingID': building.buildingId,
    'name': building.name,
    'floorsCount': building.floorsCount,
    'constructionYear': building.constructionYear,
    'totalApartments': building.totalApartments,
    'location': building.location,
  };
}

ApartmentModel _apartmentFromJson(Map<String, dynamic> json) {
  final id = _int(json['apartmentID']);
  return ApartmentModel(
    apartmentId: id,
    buildingId: _int(json['buildingID']),
    typeId: _int(json['typeID']),
    sizeM2: _int(json['sizeM2']),
    rentPricePerMonth: _double(json['rentPricePerMonth']),
    rentPricePerDay: _double(json['rentPricePerDay']),
    isAvailable: _bool(json['isAvailable']),
    bedrooms: _int(json['bedrooms']),
    bathrooms: _int(json['bathrooms']),
    hasBalcony: _bool(json['hasBalcony']),
    furnished: _bool(json['furnished']),
    hasInternet: _bool(json['hasInternet']),
    parking: _bool(json['parking']),
    elevator: _bool(json['elevator']),
    notes: _nullableString(json['notes']),
    description: _nullableString(json['description']),
    number: '#$id',
  );
}

Map<String, dynamic> _apartmentToJson(ApartmentModel apartment) {
  return {
    'apartmentID': apartment.apartmentId,
    'buildingID': apartment.buildingId,
    'typeID': apartment.typeId,
    'sizeM2': apartment.sizeM2,
    'rentPricePerMonth': apartment.rentPricePerMonth,
    'rentPricePerDay': apartment.rentPricePerDay,
    'isAvailable': apartment.isAvailable,
    'bedrooms': apartment.bedrooms,
    'bathrooms': apartment.bathrooms,
    'hasBalcony': apartment.hasBalcony,
    'furnished': apartment.furnished,
    'hasInternet': apartment.hasInternet,
    'parking': apartment.parking,
    'elevator': apartment.elevator,
    'notes': apartment.notes ?? apartment.number ?? '',
    'description': apartment.description ?? apartment.location ?? '',
  };
}

RentalBookingModel _bookingFromJson(Map<String, dynamic> json) {
  return RentalBookingModel(
    bookingId: _int(json['bookingID']),
    userId: _int(json['userID']),
    customerId: _int(json['customerID']),
    apartmentId: _int(json['apartmentID']),
    startDate: _date(json['startDate']),
    endDate: _date(json['endDate']),
    initialTotalDueAmount: _double(json['initialTotalDueAmount']),
    bookingType: _int(json['bookingType']),
    periodFee: _double(json['periodFee']),
    initialCheckNotes: _nullableString(json['initialCheckNotes']),
  );
}

Map<String, dynamic> _bookingToJson(RentalBookingModel booking) {
  return {
    'bookingID': booking.bookingId,
    'userID': booking.userId,
    'customerID': booking.customerId,
    'apartmentID': booking.apartmentId,
    'startDate': booking.startDate.toIso8601String(),
    'endDate': booking.endDate.toIso8601String(),
    'initialTotalDueAmount': booking.initialTotalDueAmount,
    'initialCheckNotes': booking.initialCheckNotes ?? '',
    'bookingType': booking.bookingType,
    'periodFee': booking.periodFee,
    'rentalPrice': booking.periodFee,
    'paymentDetails': booking.initialCheckNotes ?? '',
    'isActive': true,
  };
}

ApartmentReturnModel _returnFromJson(Map<String, dynamic> json) {
  final totalDue = _double(json['actualTotalDueAmount']);
  return ApartmentReturnModel(
    returnId: _int(json['returnID']),
    bookingId: _int(json['bookingID'], fallback: 0) == 0
        ? null
        : _int(json['bookingID']),
    actualReturnDate: _date(json['actualReturnDate']),
    actualRentalDays: 0,
    additionalCharges: _double(json['additionalCharges']),
    actualTotalDueAmount: totalDue,
    finalCheckNotes: _nullableString(json['finalCheckNotes']),
  );
}

Map<String, dynamic> _returnToJson(
  ApartmentReturnModel model, {
  required int userId,
}) {
  return {
    'returnID': model.returnId,
    'bookingID': model.bookingId ?? 0,
    'actualReturnDate': model.actualReturnDate.toIso8601String(),
    'finalCheckNotes': model.finalCheckNotes ?? '',
    'additionalCharges': model.additionalCharges,
    'actualTotalDueAmount': model.actualTotalDueAmount,
    'totalRemaining': math.max(
      0,
      model.actualTotalDueAmount - model.additionalCharges,
    ),
    'totalRefundedAmount': 0,
    'userID': userId,
  };
}

MaintenanceModel _maintenanceFromJson(Map<String, dynamic> json) {
  return MaintenanceModel(
    id: _int(json['maintenanceID']),
    apartmentId: _int(json['apartmentID']).toString(),
    description: _string(json['description']),
    cost: _double(json['cost']),
    date: _date(json['maintenanceDate']).toIso8601String().split('T').first,
  );
}

Map<String, dynamic> _maintenanceToJson(MaintenanceModel maintenance) {
  return {
    'maintenanceID': maintenance.id,
    'apartmentID': _int(maintenance.apartmentId),
    'description': maintenance.description,
    'maintenanceDate': maintenance.date.contains('T')
        ? maintenance.date
        : '${maintenance.date}T00:00:00',
    'cost': maintenance.cost,
  };
}

ContractModel _contractFromBooking(RentalBookingModel booking) {
  return ContractModel(
    contractId: booking.bookingId,
    customerId: booking.customerId,
    apartmentId: booking.apartmentId,
    startDate: booking.startDate,
    endDate: booking.endDate,
    totalAmount: booking.initialTotalDueAmount,
    status: 'Active',
    bookingId: booking.bookingId,
    notes: booking.initialCheckNotes,
  );
}

List<CustomerModel> _decorateCustomers(
  List<CustomerModel> customers,
  List<RentalBookingModel> bookings,
  List<ApartmentModel> apartments,
) {
  return customers.map((customer) {
    final booking = bookings.where((b) => b.customerId == customer.customerId);
    if (booking.isEmpty) return customer;

    final firstBooking = booking.first;
    final apartment = apartments
        .where((a) => a.apartmentId == firstBooking.apartmentId)
        .firstOrNull;

    return customer.copyWith(
      numberOfRentedApartments: math.max(
        customer.numberOfRentedApartments,
        booking.length,
      ),
      apartment: apartment?.number ?? '#${firstBooking.apartmentId}',
      startDate: firstBooking.startDate.toIso8601String().split('T').first,
      endDate: firstBooking.endDate.toIso8601String().split('T').first,
    );
  }).toList();
}

List<RentalTransactionModel> _transactionsFromBookings(
  List<RentalBookingModel> bookings,
  List<ApartmentReturnModel> returns,
) {
  return bookings.map((booking) {
    final relatedReturn = returns
        .where((r) => r.bookingId == booking.bookingId)
        .firstOrNull;
    final paid = booking.periodFee;
    final total =
        relatedReturn?.actualTotalDueAmount ?? booking.initialTotalDueAmount;
    return RentalTransactionModel(
      transactionId: booking.bookingId,
      bookingId: booking.bookingId,
      returnId: relatedReturn?.returnId,
      paidInitialTotalDueAmount: paid,
      actualTotalDueAmount: total,
      totalRemaining: math.max(0, total - paid),
      totalRefundedAmount: 0,
      transactionStatus: paid >= total ? 'Paid' : 'Partial',
      updatedTransactionDate: booking.startDate,
      paymentDetails: booking.initialCheckNotes,
    );
  }).toList();
}

int _int(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _double(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  if (text == 'true') return true;
  if (text == 'false') return false;
  return fallback;
}

String _string(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

DateTime _date(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
}
