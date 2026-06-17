import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:estatetrack1/utils/return_settlement.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import 'package:estatetrack1/config/api_config.dart';
import 'package:estatetrack1/models/account_model.dart';
import 'package:estatetrack1/models/apartment_type_model.dart';
import 'package:estatetrack1/models/apartment_model.dart';
import 'package:estatetrack1/models/apartment_return_model.dart';
import 'package:estatetrack1/models/building_model.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/models/maintenance_model.dart';
import 'package:estatetrack1/models/rental_booking_model.dart';
import 'package:estatetrack1/data/contract_builder.dart';
import 'package:estatetrack1/data/estate_snapshot_cache.dart';
import 'package:estatetrack1/data/local_backend_overlays.dart';
import 'package:estatetrack1/data/rental_transaction_builder.dart';
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
    required this.apartmentTypes,
    required this.bookings,
    required this.contracts,
    required this.returns,
    required this.rentalTransactions,
    required this.maintenance,
  });

  final List<CustomerModel> customers;
  final List<BuildingModel> buildings;
  final List<ApartmentModel> apartments;
  final List<ApartmentTypeModel> apartmentTypes;
  final List<RentalBookingModel> bookings;
  final List<ContractModel> contracts;
  final List<ApartmentReturnModel> returns;
  final List<RentalTransactionModel> rentalTransactions;
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

  static const Duration _timeout = ApiConfig.requestTimeout;

  final http.Client _client;
  AccountModel? currentUser;
  List<UserModel> staffUsers = [];
  List<RentalBookingModel> _cachedBookings = const [];
  List<ApartmentReturnModel> _cachedReturns = const [];

  Future<UserModel> getUserById(int id) async {
    final response = await _client
        .get(_uri('/api/Users/GetUserById?id=$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _userFromJson(_decodeMap(response.body));
  }

  Future<UserModel?> getUserByName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final response = await _client
        .get(
          _uri('/api/Users/ByName/${Uri.encodeComponent(trimmed)}'),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 404) return null;
    _ensureStatus(response, const {200});
    return _userFromJson(_decodeMap(response.body));
  }

  Future<bool> userExists(int id) async {
    if (id < 1) return false;
    final response = await _client
        .get(_uri('/api/Users/IsUserExist?ID=$id'), headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    _ensureStatus(response, const {200, 404});
    return false;
  }

  Future<CustomerModel> getCustomerById(int id) async {
    final response = await _client
        .get(_uri('/api/Customers/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _customerFromJson(_decodeMap(response.body));
  }

  Future<BuildingModel> getBuildingById(int id) async {
    final response = await _client
        .get(_uri('/api/Buildings/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _buildingFromJson(_decodeMap(response.body));
  }

  Future<ApartmentModel> getApartmentById(int id) async {
    final response = await _client
        .get(_uri('/api/Apartments/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _apartmentFromJson(_decodeMap(response.body));
  }

  Future<ApartmentTypeModel> getApartmentTypeById(int id) async {
    final response = await _client
        .get(_uri('/api/ApartmentTypes/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _apartmentTypeFromJson(_decodeMap(response.body));
  }

  Future<RentalBookingModel> getBookingById(int id) async {
    final response = await _client
        .get(_uri('/api/RentalBookings/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    var booking = _bookingFromJson(_decodeMap(response.body));
    if (booking.isActive) {
      try {
        if (_returnsByBookingIdFromCache(id) != null ||
            await returnExistsForBooking(id)) {
          booking = booking.copyWith(isActive: false);
        }
      } on ApiException {
        // Keep booking as returned by the API.
      }
    }
    booking = _applyBookingOverlay(booking);
    _rememberBooking(booking);
    return booking;
  }

  ApartmentReturnModel? _returnsByBookingIdFromCache(int bookingId) {
    for (final item in _cachedReturns) {
      if (item.bookingId == bookingId) return item;
    }
    return null;
  }

  Future<MaintenanceModel> getMaintenanceById(int id) async {
    final response = await _client
        .get(_uri('/api/Maintenances/$id'), headers: _headers)
        .timeout(_timeout);
    _ensureStatus(response, const {200});
    return _decorateMaintenance([
      _maintenanceFromJson(_decodeMap(response.body)),
    ]).first;
  }

  Future<bool> returnExistsForBooking(int bookingId) async {
    final response = await _client
        .get(
          _uri(
            '/api/ApartmentReturns/IsReturnExistByBookingID?bookingID=$bookingId',
          ),
          headers: _headers,
        )
        .timeout(_timeout);
    if (response.statusCode == 200) return true;
    if (response.statusCode == 404) return false;
    _ensureStatus(response, const {200, 404});
    return false;
  }

  Future<ApartmentReturnModel?> getReturnById(int returnId) async {
    if (returnId < 1) return null;
    final response = await _client
        .get(_uri('/api/ApartmentReturns/$returnId'), headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 404) return null;
    _ensureStatus(response, const {200});
    return _returnFromJson(_decodeMap(response.body));
  }

  Future<void> endMaintenance(int id) async {
    await _put('/api/Maintenances/End/$id', const {});
    await LocalBackendOverlays.instance.markMaintenanceCompleted(id);
  }

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
    final loggedInId = _int(body['userID'], fallback: userId);
    var name = _string(body['name'], 'User $userId');
    var phone = '';
    var role = loggedInId == 1 ? 'Admin' : 'Staff';

    try {
      final profile = await getUserById(loggedInId);
      name = profile.name;
      phone = profile.phone;
    } on ApiException {
      // Login succeeded; profile fetch is optional enrichment.
    }

    try {
      staffUsers = await getUsers();
    } on ApiException {
      staffUsers = [];
    }

    final account = AccountModel(
      id: loggedInId.toString(),
      name: name,
      email: '',
      phone: phone,
      password: '',
      role: role,
    );
    currentUser = account;
    return account;
  }

  void logout() {
    currentUser = null;
    staffUsers = [];
    _cachedBookings = const [];
    _cachedReturns = const [];
  }

  Future<EstateSnapshot> loadSnapshot() async {
    await LocalBackendOverlays.instance.ensureLoaded();

    final results = await Future.wait([
      _getList('/api/Customers/All', _customerFromJson),
      _getList('/api/Buildings/All', _buildingFromJson),
      _getList('/api/Apartments/All', _apartmentFromJson),
      _getList('/api/ApartmentTypes/All', _apartmentTypeFromJson),
      _getList('/api/RentalBookings/All', _bookingFromJson),
      _getList('/api/ApartmentReturns/All', _returnFromJson),
      _getList('/api/Maintenances/All', _maintenanceFromJson),
      _getList('/api/Users/All', _userFromJson),
    ]);

    final customers = results[0] as List<CustomerModel>;
    final buildings = results[1] as List<BuildingModel>;
    final apartments = results[2] as List<ApartmentModel>;
    final apartmentTypes = results[3] as List<ApartmentTypeModel>;
    final rawBookings = results[4] as List<RentalBookingModel>;
    final rawReturns = results[5] as List<ApartmentReturnModel>;
    final rawMaintenance = results[6] as List<MaintenanceModel>;
    staffUsers = results[7] as List<UserModel>;
    final bookings = _decorateBookings(rawBookings, rawReturns);
    final returns = _decorateReturns(rawReturns, bookings);
    final maintenance = _decorateMaintenance(rawMaintenance);
    final contracts = contractsFromBookings(bookings, returns);

    _cachedBookings = bookings;
    _cachedReturns = returns;

    final snapshot = EstateSnapshot(
      customers: _decorateCustomers(customers, bookings, returns, apartments),
      buildings: buildings,
      apartments: apartments,
      apartmentTypes: apartmentTypes,
      bookings: bookings,
      contracts: contracts,
      returns: returns,
      rentalTransactions: buildTransactionsFromBookings(bookings, returns),
      maintenance: maintenance,
    );
    EstateSnapshotCache.instance.save(snapshot);
    return snapshot;
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
    return getBuildingById(saved.buildingId);
  }

  Future<BuildingModel> updateBuilding(BuildingModel building) async {
    await _put(
      '/api/Buildings/${building.buildingId}',
      _buildingToJson(building),
    );
    return getBuildingById(building.buildingId);
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
    final fresh = await getApartmentById(saved.apartmentId);
    return fresh.copyWith(
      number: apartment.number,
      location: apartment.location,
    );
  }

  Future<ApartmentModel> updateApartment(ApartmentModel apartment) async {
    await _put(
      '/api/Apartments/${apartment.apartmentId}',
      _apartmentToJson(apartment),
    );
    final fresh = await getApartmentById(apartment.apartmentId);
    return fresh.copyWith(
      number: apartment.number,
      location: apartment.location,
    );
  }

  Future<void> deleteApartment(int id) async {
    await _delete('/api/Apartments/$id');
  }

  Future<List<UserModel>> getUsers() =>
      _getList('/api/Users/All', _userFromJson);

  Future<List<ApartmentTypeModel>> getApartmentTypes() =>
      _getList('/api/ApartmentTypes/All', _apartmentTypeFromJson);

  Future<ApartmentTypeModel> createApartmentType(
    ApartmentTypeModel type,
  ) async {
    final response = await _post(
      '/api/ApartmentTypes',
      _apartmentTypeToJson(type.copyWith(typeId: 0)),
    );
    final saved = _apartmentTypeFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.typeId, 'Apartment type');
    return getApartmentTypeById(saved.typeId);
  }

  Future<ApartmentTypeModel> updateApartmentType(
    ApartmentTypeModel type,
  ) async {
    await _put(
      '/api/ApartmentTypes/${type.typeId}',
      _apartmentTypeToJson(type),
    );
    return getApartmentTypeById(type.typeId);
  }

  Future<void> deleteApartmentType(int id) async {
    await _delete('/api/ApartmentTypes/$id');
  }

  Future<UserModel> createUser(UserModel user) async {
    if (user.userId > 0 && await userExists(user.userId)) {
      throw ApiException(
        'User ID ${user.userId} already exists',
        statusCode: 409,
      );
    }
    final response = await _post('/api/Users', _userToJson(user));
    final saved = _userFromJson(_decodeMap(response!.body));
    _requirePositiveId(saved.userId, 'User');
    return getUserById(saved.userId);
  }

  Future<UserModel> updateUser(UserModel user) async {
    await _put('/api/Users/${user.userId}', _userToJson(user));
    return getUserById(user.userId);
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
    return getBookingById(saved.bookingId);
  }

  Future<RentalBookingModel> updateBooking(RentalBookingModel booking) async {
    await _put(
      '/api/RentalBookings/${booking.bookingId}',
      _bookingToJson(booking),
    );
    return getBookingById(booking.bookingId);
  }

  Future<void> deleteBooking(int id) async {
    await _delete('/api/RentalBookings/$id');
  }

  Future<ApartmentReturnModel> createReturn(
    ApartmentReturnModel model, {
    required int userId,
    double paidOnBooking = 0,
  }) async {
    final bookingId = model.bookingId;
    if (bookingId != null && bookingId > 0) {
      try {
        if (await returnExistsForBooking(bookingId)) {
          final existing = await _findReturnByBookingId(bookingId);
          if (existing != null) return existing;
        }
      } on ApiException {
        // Fall through to create attempt if the existence check fails.
      }
    }

    final payload = _returnToJson(
      model,
      userId: userId,
      paidOnBooking: paidOnBooking,
    );

    try {
      final response = await _post('/api/ApartmentReturns', payload);
      final saved = _returnFromJson(_decodeMap(response!.body));
      if (saved.returnId <= 0 && bookingId != null && bookingId > 0) {
        final recovered = await _findReturnByBookingId(bookingId);
        if (recovered != null) {
          await LocalBackendOverlays.instance.markBookingInactive(bookingId);
          return _refreshReturnFromApi(recovered);
        }
      }
      _requirePositiveId(saved.returnId, 'Apartment return');
      if (bookingId != null && bookingId > 0) {
        await LocalBackendOverlays.instance.markBookingInactive(bookingId);
      }
      return _refreshReturnFromApi(saved);
    } on ApiException catch (e) {
      if (e.statusCode != 500 || bookingId == null) rethrow;
      final recovered = await _findReturnByBookingId(bookingId);
      if (recovered != null) {
        await LocalBackendOverlays.instance.markBookingInactive(bookingId);
        return _refreshReturnFromApi(recovered);
      }
      rethrow;
    }
  }

  Future<ApartmentReturnModel?> _findReturnByBookingId(int bookingId) async {
    for (final item in _cachedReturns) {
      if (item.bookingId == bookingId) return item;
    }

    for (final item in await _getList(
      '/api/ApartmentReturns/All',
      _returnFromJson,
    )) {
      if (item.bookingId == bookingId) return item;
    }
    return null;
  }

  RentalBookingModel? _cachedBooking(int bookingId) {
    for (final booking in _cachedBookings) {
      if (booking.bookingId == bookingId) return booking;
    }
    return null;
  }

  void _rememberBooking(RentalBookingModel booking) {
    final next = List<RentalBookingModel>.from(_cachedBookings);
    final index = next.indexWhere((b) => b.bookingId == booking.bookingId);
    if (index >= 0) {
      next[index] = booking;
    } else {
      next.add(booking);
    }
    _cachedBookings = next;
  }

  Future<ApartmentReturnModel> updateReturn(
    ApartmentReturnModel model, {
    required int userId,
    double paidOnBooking = 0,
  }) async {
    if (model.returnId > 0) {
      try {
        final response = await _put(
          '/api/ApartmentReturns/${model.returnId}',
          _returnToJson(model, userId: userId, paidOnBooking: paidOnBooking),
        );
        final saved = _returnFromJson(_decodeMap(response.body));
        final bookingId = model.bookingId;
        if (bookingId != null && bookingId > 0) {
          await LocalBackendOverlays.instance.markBookingInactive(bookingId);
        }
        return _refreshReturnFromApi(saved);
      } on ApiException {
        // Backend UpdateReturn SQL may be unreliable; fall back below.
      }
    }
    return replaceReturn(model, userId: userId, paidOnBooking: paidOnBooking);
  }

  Future<ApartmentReturnModel> replaceReturn(
    ApartmentReturnModel model, {
    required int userId,
    double paidOnBooking = 0,
  }) async {
    if (model.returnId > 0) {
      await deleteReturn(model.returnId);
    }
    return createReturn(
      model.copyWith(returnId: 0),
      userId: userId,
      paidOnBooking: paidOnBooking,
    );
  }

  Future<void> deleteReturn(int id) async {
    await _delete('/api/ApartmentReturns/$id');
  }

  Future<RentalBookingModel> saveBookingPayment({
    required RentalBookingModel booking,
    required double paidAmount,
    String? paymentDetails,
  }) {
    return updateBooking(
      booking.copyWith(
        rentalPrice: paidAmount,
        paymentDetails: paymentDetails ?? booking.paymentDetails ?? '',
      ),
    );
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
    await _put(
      '/api/Maintenances/${maintenance.id}',
      _maintenanceToJson(maintenance),
    );
    return getMaintenanceById(maintenance.id);
  }

  Future<void> deleteMaintenance(int id) async {
    await _delete('/api/Maintenances/$id');
    await LocalBackendOverlays.instance.unmarkMaintenanceCompleted(id);
  }

  Future<ApartmentReturnModel> _refreshReturnFromApi(
    ApartmentReturnModel model,
  ) async {
    final fresh = await getReturnById(model.returnId);
    if (fresh == null) return model;

    final bookingId = fresh.bookingId;
    if (bookingId == null || fresh.actualRentalDays > 0) return fresh;

    try {
      final cached = _cachedBooking(bookingId);
      final booking = cached ?? await getBookingById(bookingId);
      final days = fresh.actualReturnDate.difference(booking.startDate).inDays;
      return fresh.copyWith(actualRentalDays: math.max(0, days));
    } on ApiException {
      return fresh;
    }
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
    ApiException? lastError;
    for (var attempt = 0; attempt <= ApiConfig.maxRetries; attempt++) {
      try {
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
      } on ApiException catch (e) {
        lastError = e;
        if (attempt >= ApiConfig.maxRetries) rethrow;
      }
    }
    throw lastError ?? ApiException('Request failed for $path');
  }

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

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

ApartmentTypeModel _apartmentTypeFromJson(Map<String, dynamic> json) {
  return ApartmentTypeModel(
    typeId: _int(json['typeID']),
    apartmentType: _string(json['apartmentType']),
  );
}

Map<String, dynamic> _apartmentTypeToJson(ApartmentTypeModel type) {
  return {'typeID': type.typeId, 'apartmentType': type.apartmentType};
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
  final notes = _nullableString(json['notes']);
  final description = _nullableString(json['description']);
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
    notes: notes,
    description: description,
    number: notes ?? '#$id',
    location: description,
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
    rentalPrice: _double(json['rentalPrice']),
    paymentDetails: _nullableString(json['paymentDetails']),
    isActive: _bool(json['isActive'], fallback: true),
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
    'rentalPrice': booking.rentalPrice,
    'paymentDetails': booking.paymentDetails ?? '',
    'isActive': booking.isActive,
  };
}

ApartmentReturnModel _returnFromJson(Map<String, dynamic> json) {
  return ApartmentReturnModel(
    returnId: _int(json['returnID']),
    bookingId: _int(json['bookingID'], fallback: 0) == 0
        ? null
        : _int(json['bookingID']),
    actualReturnDate: _date(json['actualReturnDate']),
    actualRentalDays: _int(json['actualRentalDays']),
    additionalCharges: _double(json['additionalCharges']),
    actualTotalDueAmount: _double(json['actualTotalDueAmount']),
    totalRemaining: _double(json['totalRemaining']),
    totalRefundedAmount: _double(json['totalRefundedAmount']),
    finalCheckNotes: _nullableString(json['finalCheckNotes']),
  );
}

Map<String, dynamic> _returnToJson(
  ApartmentReturnModel model, {
  required int userId,
  double paidOnBooking = 0,
}) {
  final totalDue = model.actualTotalDueAmount;
  final settlement = ReturnSettlement.compute(
    totalDueAmount: totalDue,
    paidOnBooking: paidOnBooking,
  );
  final useModelSettlement =
      model.totalRemaining > 0 || model.totalRefundedAmount > 0;

  return {
    'returnID': model.returnId,
    'bookingID': model.bookingId ?? 0,
    'actualReturnDate': model.actualReturnDate.toIso8601String(),
    'finalCheckNotes': model.finalCheckNotes ?? '',
    'additionalCharges': model.additionalCharges,
    'actualTotalDueAmount': totalDue,
    'totalRemaining': useModelSettlement
        ? model.totalRemaining
        : settlement.remaining,
    'totalRefundedAmount': useModelSettlement
        ? model.totalRefundedAmount
        : settlement.refunded,
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

List<CustomerModel> _decorateCustomers(
  List<CustomerModel> customers,
  List<RentalBookingModel> bookings,
  List<ApartmentReturnModel> returns,
  List<ApartmentModel> apartments,
) {
  return customers.map((customer) {
    final customerBookings = bookings
        .where((b) => b.customerId == customer.customerId)
        .toList();
    if (customerBookings.isEmpty) return customer;

    final activeBookings =
        customerBookings
            .where(
              (b) =>
                  contractStatusFor(booking: b, returns: returns) == 'Active',
            )
            .toList()
          ..sort((a, b) => b.startDate.compareTo(a.startDate));

    final sortedBookings = List<RentalBookingModel>.from(customerBookings)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    final reference = activeBookings.isNotEmpty
        ? activeBookings.first
        : sortedBookings.first;

    final apartment = apartments
        .where((a) => a.apartmentId == reference.apartmentId)
        .firstOrNull;

    return customer.copyWith(
      numberOfRentedApartments: math.max(
        customer.numberOfRentedApartments,
        activeBookings.length,
      ),
      apartment: apartment?.number ?? '#${reference.apartmentId}',
      startDate: reference.startDate.toIso8601String().split('T').first,
      endDate: reference.endDate.toIso8601String().split('T').first,
    );
  }).toList();
}

RentalBookingModel _applyBookingOverlay(RentalBookingModel booking) {
  if (LocalBackendOverlays.instance.isBookingInactive(booking.bookingId) &&
      booking.isActive) {
    return booking.copyWith(isActive: false);
  }
  return booking;
}

List<ApartmentReturnModel> _decorateReturns(
  List<ApartmentReturnModel> returns,
  List<RentalBookingModel> bookings,
) {
  return returns.map((item) {
    final bookingId = item.bookingId;
    if (bookingId == null || item.actualRentalDays > 0) return item;
    final booking = bookings.where((b) => b.bookingId == bookingId).firstOrNull;
    if (booking == null) return item;
    final days = item.actualReturnDate.difference(booking.startDate).inDays;
    return item.copyWith(actualRentalDays: math.max(0, days));
  }).toList();
}

List<RentalBookingModel> _decorateBookings(
  List<RentalBookingModel> bookings,
  List<ApartmentReturnModel> returns,
) {
  final returnedBookingIds = returns
      .map((item) => item.bookingId)
      .whereType<int>()
      .toSet();
  final overlays = LocalBackendOverlays.instance;

  return bookings.map((booking) {
    final inactive =
        returnedBookingIds.contains(booking.bookingId) ||
        overlays.isBookingInactive(booking.bookingId);
    if (inactive && booking.isActive) {
      return _applyBookingOverlay(booking.copyWith(isActive: false));
    }
    return _applyBookingOverlay(booking);
  }).toList();
}

List<MaintenanceModel> _decorateMaintenance(List<MaintenanceModel> items) {
  final overlays = LocalBackendOverlays.instance;
  return items
      .map(
        (item) => overlays.isMaintenanceCompleted(item.id)
            ? item.copyWith(status: 'Done')
            : item,
      )
      .toList();
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

// Test helpers keep JSON mapping covered without duplicating DTO rules.
@visibleForTesting
ApartmentTypeModel decodeApartmentTypeForTest(Map<String, dynamic> json) =>
    _apartmentTypeFromJson(json);

@visibleForTesting
Map<String, dynamic> encodeApartmentTypeForTest(ApartmentTypeModel type) =>
    _apartmentTypeToJson(type);

@visibleForTesting
CustomerModel decodeCustomerForTest(Map<String, dynamic> json) =>
    _customerFromJson(json);

@visibleForTesting
Map<String, dynamic> encodeCustomerForTest(CustomerModel customer) =>
    _customerToJson(customer);

@visibleForTesting
RentalBookingModel decodeBookingForTest(Map<String, dynamic> json) =>
    _bookingFromJson(json);

@visibleForTesting
Map<String, dynamic> encodeBookingForTest(RentalBookingModel booking) =>
    _bookingToJson(booking);

@visibleForTesting
ApartmentReturnModel decodeReturnForTest(Map<String, dynamic> json) =>
    _returnFromJson(json);

@visibleForTesting
Map<String, dynamic> encodeReturnForTest(
  ApartmentReturnModel model, {
  required int userId,
  double paidOnBooking = 0,
}) =>
    _returnToJson(model, userId: userId, paidOnBooking: paidOnBooking);

@visibleForTesting
UserModel decodeUserForTest(Map<String, dynamic> json) => _userFromJson(json);

@visibleForTesting
Map<String, dynamic> encodeUserForTest(UserModel user) => _userToJson(user);
