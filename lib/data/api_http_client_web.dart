import 'package:http/http.dart' as http;

/// Browsers enforce TLS and CORS; self-signed localhost certs cannot be bypassed.
http.Client createApiHttpClient() => http.Client();
