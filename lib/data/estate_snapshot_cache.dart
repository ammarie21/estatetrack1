import 'package:estatetrack1/data/estate_api.dart';

/// In-memory stale-while-revalidate cache for the last successful API snapshot.
class EstateSnapshotCache {
  EstateSnapshotCache._();

  static final EstateSnapshotCache instance = EstateSnapshotCache._();

  EstateSnapshot? _snapshot;
  DateTime? _savedAt;

  EstateSnapshot? get snapshot => _snapshot;

  DateTime? get savedAt => _savedAt;

  bool get hasData => _snapshot != null;

  void save(EstateSnapshot snapshot) {
    _snapshot = snapshot;
    _savedAt = DateTime.now();
  }

  void clear() {
    _snapshot = null;
    _savedAt = null;
  }
}
