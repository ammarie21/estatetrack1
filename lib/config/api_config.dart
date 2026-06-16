/// Central API configuration for EstateTrack backend integration.
class ApiConfig {
  ApiConfig._();

  /// Default local HTTPS URL from RentalApartment_API launchSettings.
  static const String baseUrl = 'https://localhost:7274';

  static const Duration requestTimeout = Duration(seconds: 25);
}
