import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/job_deadline.dart';

class NotificationsService {
  NotificationsService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<NotificationsService> create() async {
    final plugin = FlutterLocalNotificationsPlugin();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await plugin.initialize(initSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    return NotificationsService(plugin);
  }

  Future<void> requestPermissionsIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    try {
      final canExact = await android?.canScheduleExactNotifications();
      if (canExact == false) {
        await android?.requestExactAlarmsPermission();
      }
    } catch (_) {}

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelForDeadline(String deadlineId) async {
    final base = _stableBaseId(deadlineId);
    await _plugin.cancel(base + 1);
    await _plugin.cancel(base + 2);
    await _plugin.cancel(base + 3);
  }

  Future<void> scheduleForDeadline({
    required JobDeadline deadline,
    required bool enableD3,
    required bool enableD1,
    required bool enable3h,
  }) async {
    await cancelForDeadline(deadline.id);
    if (!deadline.notificationsEnabled) return;

    final base = _stableBaseId(deadline.id);
    final now = tz.TZDateTime.now(tz.local);

    Future<void> schedule(
      int id,
      tz.TZDateTime when,
      String title,
      String body,
    ) async {
      if (!when.isAfter(now)) return;

      const androidDetails = AndroidNotificationDetails(
        'deadline_note.default',
        '마감 알림',
        channelDescription: '채용 마감 알림을 제공합니다.',
        importance: Importance.high,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());

      AndroidScheduleMode mode = AndroidScheduleMode.exactAllowWhileIdle;
      try {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final canExact = await android?.canScheduleExactNotifications();
        if (canExact == false) {
          mode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      } catch (_) {
        mode = AndroidScheduleMode.inexactAllowWhileIdle;
      }

      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
        );
      } catch (e) {
        if (e is PlatformException && e.code == 'exact_alarms_not_permitted') {
          try {
            await _plugin.zonedSchedule(
              id,
              title,
              body,
              when,
              details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            );
          } catch (inner) {
            debugPrint('Failed to schedule fallback notification: $inner');
          }
        } else {
          debugPrint('Failed to schedule notification: $e');
        }
      }
    }

    final deadlineAt = tz.TZDateTime.from(deadline.deadlineAt, tz.local);
    final label = '${deadline.companyName} ${deadline.jobTitle}'.trim();
    final title = '채용 마감 알림';

    if (enableD3) {
      await schedule(
        base + 1,
        deadlineAt.subtract(const Duration(days: 3)),
        title,
        '$label 마감 3일 전입니다.',
      );
    }
    if (enableD1) {
      await schedule(
        base + 2,
        deadlineAt.subtract(const Duration(days: 1)),
        title,
        '$label 마감 1일 전입니다.',
      );
    }
    if (enable3h) {
      await schedule(
        base + 3,
        deadlineAt.subtract(const Duration(hours: 3)),
        title,
        '$label 마감 3시간 전입니다.',
      );
    }
  }

  int _stableBaseId(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return (hash % 600000) * 10;
  }
}
