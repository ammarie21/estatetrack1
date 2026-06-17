import 'package:estatetrack1/settings/app_settings.dart';
/// Central API configuration for EstateTrack backend integration.
class ApiConfig {
  ApiConfig._();

  /// Default local HTTPS URL from RentalApartment_API launchSettings.
  static const String defaultBaseUrl = 'https://localhost:7274';

  static String get baseUrl {
    final override = AppSettings.instance.apiBaseUrl?.trim();
    if (override != null && override.isNotEmpty) return override;
    return defaultBaseUrl;
  }

  static const Duration requestTimeout = Duration(seconds: 25);

  static const int maxRetries = 2;
}
