import 'package:flutter_test/flutter_test.dart';

import 'package:estatetrack1/config/api_config.dart';
import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/screens/settings/settings_screen.dart';
import 'test_fixtures.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('settings shows account, backend url, and version', (
    WidgetTester tester,
  ) async {
    final refreshed = DateTime(2025, 6, 17, 14, 30);

    await pumpBody(
      tester,
      SettingsScreen(
        account: testAccount(admin: true),
        isLoadingFromApi: false,
        lastRefreshed: refreshed,
        onRefresh: () async {},
        onLogout: () {},
      ),
    );

    expect(find.text('Main Admin'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('admin@estate.test'), findsOneWidget);
    expect(find.text(ApiConfig.defaultBaseUrl), findsOneWidget);
    expect(find.text(SettingsScreen.appVersion), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);

    await scrollTo(tester, find.text('Sign out'));
    expect(find.text('Refresh data now'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('settings shows api error when sync failed', (
    WidgetTester tester,
  ) async {
    await pumpBody(
      tester,
      SettingsScreen(
        account: testAccount(),
        isLoadingFromApi: false,
        apiError: 'Connection refused',
      ),
    );

    expect(find.text('Connection refused'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('settings refresh button calls callback', (
    WidgetTester tester,
  ) async {
    var refreshCount = 0;

    await pumpBody(
      tester,
      SettingsScreen(
        account: testAccount(),
        isLoadingFromApi: false,
        onRefresh: () async => refreshCount++,
      ),
    );

    await scrollTo(tester, find.text('Refresh data now'));
    await tester.tap(find.text('Refresh data now'));
    await tester.pump();

    expect(refreshCount, 1);
  });

  testWidgets('settings shows synced record counts', (
    WidgetTester tester,
  ) async {
    await pumpBody(
      tester,
      SettingsScreen(
        account: testAccount(),
        isLoadingFromApi: false,
        recordCounts: const BackendRecordCounts(
          customers: 5,
          buildings: 2,
          apartments: 12,
          bookings: 8,
          returns: 3,
          maintenance: 4,
          staff: 2,
        ),
      ),
    );

    await scrollTo(tester, find.text('Synced records'));
    expect(find.text('Synced records'), findsOneWidget);
    expect(find.text('Customers: 5'), findsOneWidget);
    expect(find.text('36 total rows loaded from backend'), findsOneWidget);
  });
}
