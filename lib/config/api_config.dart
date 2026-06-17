import 'package:flutter/foundation.dart';

import 'package:estatetrack1/settings/app_settings.dart';

/// Central API configuration for EstateTrack backend integration.
class ApiConfig {
  ApiConfig._();

  /// Desktop uses HTTPS with a dev cert bypass; browsers need plain HTTP + CORS.
  static String get defaultBaseUrl =>
      kIsWeb ? 'http://localhost:5170' : 'https://localhost:7274';

  static String get baseUrl {
    final override = AppSettings.instance.apiBaseUrl?.trim();
    final resolved = (override != null && override.isNotEmpty)
        ? override
        : defaultBaseUrl;
    if (kIsWeb && _isLocalhostHttps(resolved)) {
      return defaultBaseUrl;
    }
    return resolved;
  }

  static bool _isLocalhostHttps(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
        uri.scheme == 'https' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  static const Duration requestTimeout = Duration(seconds: 25);

  static const int maxRetries = 2;
}
