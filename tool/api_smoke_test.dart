import 'dart:convert';
import 'dart:io';

const _baseUrl = 'https://localhost:7274';

Future<void> main() async {
  final client = HttpClient()
    ..badCertificateCallback = (certificate, host, port) {
      return host == 'localhost' || host == '127.0.0.1';
    };

  final checks = <Future<void>>[
    _checkLoginValidation(client),
    _checkList(client, '/api/Users/All', requiredKeys: const ['userID', 'name']),
    _checkList(
      client,
      '/api/Customers/All',
      requiredKeys: const ['customerID', 'name', 'phone'],
    ),
    _checkList(
      client,
      '/api/Buildings/All',
      requiredKeys: const ['buildingID', 'name', 'floorsCount'],
    ),
    _checkList(
      client,
      '/api/Apartments/All',
      requiredKeys: const ['apartmentID', 'buildingID', 'typeID', 'sizeM2'],
    ),
    _checkList(
      client,
      '/api/ApartmentTypes/All',
      requiredKeys: const ['typeID', 'apartmentType'],
    ),
    _checkList(
      client,
      '/api/RentalBookings/All',
      requiredKeys: const [
        'bookingID',
        'customerID',
        'apartmentID',
        'rentalPrice',
      ],
    ),
    _checkList(
      client,
      '/api/ApartmentReturns/All',
      requiredKeys: const ['returnID', 'bookingID', 'actualReturnDate'],
    ),
    _checkList(
      client,
      '/api/Maintenances/All',
      allow404: true,
      requiredKeys: const ['maintenanceID', 'apartmentID', 'description'],
    ),
  ];

  var failed = 0;
  for (final check in checks) {
    try {
      await check;
    } catch (e) {
      failed++;
      stderr.writeln('FAIL: $e');
    }
  }

  client.close(force: true);
  if (failed > 0) {
    stderr.writeln('\n$failed endpoint check(s) failed.');
    exit(1);
  }

  stdout.writeln('\nAll backend smoke checks passed.');
}

Future<void> _checkLoginValidation(HttpClient client) async {
  final request = await client.postUrl(Uri.parse('$_baseUrl/api/Users/Login'));
  request.headers.set('Accept', 'application/json');
  request.headers.set('Content-Type', 'application/json');
  request.write(jsonEncode({'userID': 0, 'password': ''}));
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode != 400) {
    throw Exception(
      '/api/Users/Login invalid payload -> expected HTTP 400, got ${response.statusCode}: $body',
    );
  }

  stdout.writeln('OK  /api/Users/Login -> 400 for invalid payload');
}

Future<void> _checkList(
  HttpClient client,
  String path, {
  bool allow404 = false,
  List<String> requiredKeys = const [],
}) async {
  final request = await client.getUrl(Uri.parse('$_baseUrl$path'));
  request.headers.set('Accept', 'application/json');
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();

  if (response.statusCode == 404 && allow404) {
    stdout.writeln('OK  $path -> 404 (empty table)');
    return;
  }

  if (response.statusCode != 200) {
    throw Exception('$path -> HTTP ${response.statusCode}: $body');
  }

  final decoded = jsonDecode(body);
  if (decoded is! List) {
    throw Exception('$path -> expected JSON list');
  }

  if (decoded.isNotEmpty && requiredKeys.isNotEmpty) {
    final first = decoded.first;
    if (first is! Map) {
      throw Exception('$path -> first row is not an object');
    }
    final row = Map<String, dynamic>.from(first);
    for (final key in requiredKeys) {
      if (!row.containsKey(key)) {
        throw Exception('$path -> missing key "$key" in first row');
      }
    }
  }

  stdout.writeln('OK  $path -> ${decoded.length} row(s)');
}
