import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createApiHttpClient() {
  return IOClient(
    HttpClient()
      ..badCertificateCallback = (certificate, host, port) {
        return host == 'localhost' || host == '127.0.0.1';
      },
  );
}
