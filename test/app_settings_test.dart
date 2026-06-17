import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:estatetrack1/settings/app_settings.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppSettings.instance.themeMode = ThemeMode.system;
  });

  test('load reads persisted theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});

    await AppSettings.instance.load();

    expect(AppSettings.instance.themeMode, ThemeMode.dark);
    expect(AppSettings.instance.isLoaded, isTrue);
  });

  test('setThemeMode persists choice', () async {
    await AppSettings.instance.setThemeMode(ThemeMode.light);

    expect(AppSettings.instance.themeMode, ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('setThemeMode skips work when mode unchanged', () async {
    AppSettings.instance.themeMode = ThemeMode.dark;

    await AppSettings.instance.setThemeMode(ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), isNull);
  });

  test('persists last user id and api base url', () async {
    await AppSettings.instance.setLastUserId('7');
    await AppSettings.instance.setApiBaseUrl('https://api.example.test');

    AppSettings.instance.themeMode = ThemeMode.system;
    await AppSettings.instance.load();

    expect(AppSettings.instance.lastUserId, '7');
    expect(AppSettings.instance.effectiveApiBaseUrl, 'https://api.example.test');
  });

  test('persists lease reminder preference', () async {
    await AppSettings.instance.setLeaseRemindersEnabled(false);
    await AppSettings.instance.load();
    expect(AppSettings.instance.leaseRemindersEnabled, isFalse);

    await AppSettings.instance.setLeaseRemindersEnabled(true);
    expect(AppSettings.instance.leaseRemindersEnabled, isTrue);
  });
}
