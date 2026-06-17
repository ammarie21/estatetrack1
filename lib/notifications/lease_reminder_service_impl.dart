import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:estatetrack1/data/estate_indexes.dart';
import 'package:estatetrack1/models/contract_model.dart';
import 'package:estatetrack1/models/customer_model.dart';
import 'package:estatetrack1/settings/app_settings.dart';

/// Schedules local notifications for active leases ending within 7 days.
class LeaseReminderService {
  LeaseReminderService._();

  static final LeaseReminderService instance = LeaseReminderService._();

  static const _idBase = 5000;
  static const _idSpan = 500;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        // Scheduling falls back to UTC if the platform timezone is unavailable.
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      const windows = WindowsInitializationSettings(
        appName: 'EstateTrack',
        appUserModelId: 'EstateTrack.LeaseReminders',
        guid: 'a4f2c8e1-9b3d-4e7a-b6c1-2d8f9e0a1b2c',
      );

      await _plugin.initialize(
        const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
          windows: windows,
        ),
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Lease reminders unavailable on this platform: $e');
      }
    }
  }

  Future<void> clearReminders() => _cancelAll();

  Future<void> syncLeaseReminders({
    required List<ContractModel> contracts,
    required List<CustomerModel> customers,
    EstateIndexes? indexes,
  }) async {
    if (!_initialized || !AppSettings.instance.leaseRemindersEnabled) {
      await _cancelAll();
      return;
    }

    final lookup = indexes ??
        EstateIndexes.fromLists(
          customers: customers,
          buildings: const [],
          apartments: const [],
          bookings: const [],
        );

    await _cancelAll();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var slot = 0;

    for (final contract in contracts) {
      if (contract.status != 'Active') continue;

      final endDay = DateTime(
        contract.endDate.year,
        contract.endDate.month,
        contract.endDate.day,
      );
      final daysLeft = endDay.difference(today).inDays;
      if (daysLeft < 0 || daysLeft > 7) continue;
      if (slot >= _idSpan) break;

      final customerName = lookup.customerName(contract.customerId);
      final apartmentLabel = lookup.apartmentLabel(contract.apartmentId);
      final when = _scheduleTime(endDay, now);
      final id = _idBase + slot;
      slot++;

      final title = daysLeft == 0
          ? 'Lease ends today'
          : 'Lease ending in $daysLeft day${daysLeft == 1 ? '' : 's'}';
      final body = '$customerName · $apartmentLabel';

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(when, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'lease_expiry',
              'Lease reminders',
              channelDescription:
                  'Alerts when rental agreements are about to expire',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
            macOS: DarwinNotificationDetails(),
            windows: WindowsNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Lease reminder schedule failed: $e');
        }
      }
    }
  }

  DateTime _scheduleTime(DateTime endDay, DateTime now) {
    var at = DateTime(endDay.year, endDay.month, endDay.day, 9);
    if (!at.isAfter(now)) {
      at = now.add(const Duration(minutes: 1));
    }
    return at;
  }

  Future<void> _cancelAll() async {
    for (var i = 0; i < _idSpan; i++) {
      await _plugin.cancel(_idBase + i);
    }
  }
}
