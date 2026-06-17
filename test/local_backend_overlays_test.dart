import 'package:estatetrack1/data/local_backend_overlays.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalBackendOverlays.instance.resetForTest();
  });

  test('persists completed maintenance ids', () async {
    final overlays = LocalBackendOverlays.instance;

    await overlays.markMaintenanceCompleted(4);
    overlays.resetForTest();
    await overlays.ensureLoaded();

    expect(overlays.isMaintenanceCompleted(4), isTrue);
    expect(overlays.isMaintenanceCompleted(5), isFalse);
  });

  test('persists inactive booking ids', () async {
    final overlays = LocalBackendOverlays.instance;

    await overlays.markBookingInactive(12);
    overlays.resetForTest();
    await overlays.ensureLoaded();

    expect(overlays.isBookingInactive(12), isTrue);
  });
}
