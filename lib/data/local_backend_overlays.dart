import 'package:shared_preferences/shared_preferences.dart';

/// Persists client-side corrections when the backend cannot store them
/// (maintenance completion, booking inactive after checkout).
class LocalBackendOverlays {
  LocalBackendOverlays._();

  static final LocalBackendOverlays instance = LocalBackendOverlays._();

  static const _completedMaintenanceKey = 'completed_maintenance_ids';
  static const _inactiveBookingsKey = 'inactive_booking_ids';

  Set<int> _completedMaintenance = {};
  Set<int> _inactiveBookings = {};
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  bool isMaintenanceCompleted(int id) => _completedMaintenance.contains(id);

  bool isBookingInactive(int bookingId) =>
      _inactiveBookings.contains(bookingId);

  Future<void> markMaintenanceCompleted(int id) async {
    await ensureLoaded();
    if (!_completedMaintenance.add(id)) return;
    await _persist(_completedMaintenanceKey, _completedMaintenance);
  }

  Future<void> unmarkMaintenanceCompleted(int id) async {
    await ensureLoaded();
    if (!_completedMaintenance.remove(id)) return;
    await _persist(_completedMaintenanceKey, _completedMaintenance);
  }

  Future<void> markBookingInactive(int bookingId) async {
    await ensureLoaded();
    if (bookingId < 1 || !_inactiveBookings.add(bookingId)) return;
    await _persist(_inactiveBookingsKey, _inactiveBookings);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _completedMaintenance = _readIntSet(
      prefs.getStringList(_completedMaintenanceKey),
    );
    _inactiveBookings = _readIntSet(prefs.getStringList(_inactiveBookingsKey));
  }

  Future<void> _persist(String key, Set<int> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      values.map((id) => id.toString()).toList()..sort(),
    );
  }

  Set<int> _readIntSet(List<String>? raw) {
    if (raw == null || raw.isEmpty) return {};
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  /// Clears in-memory state (tests only).
  void resetForTest() {
    _completedMaintenance = {};
    _inactiveBookings = {};
    _loadFuture = null;
  }
}
