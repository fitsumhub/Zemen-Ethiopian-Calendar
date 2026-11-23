import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/local/app_database.dart';
import '../../data/models/event_entity.dart';
import '../../data/preferences/user_preferences_repository.dart';
import '../calendar/ethiopian_calendar_engine.dart';
import '../calendar/ethiopian_date.dart';
import '../localization/app_language.dart';
import '../localization/locale_strings.dart';

/// Schedules local reminders for Zemen events (Flutter port of Kotlin scheduler).
class NotificationScheduler {
  static const String channelId = 'ethiocal_reminders_channel';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static AppLanguage _language = AppLanguage.english;

  static void setLanguage(AppLanguage language) {
    _language = language;
  }

  static String _t(String key) => LocaleStrings.get(key, _language);

  static Future<void> initialize({AppLanguage? language}) async {
    if (language != null) _language = language;
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final location = tz.timeZoneDatabase.locations['Africa/Addis_Ababa'] ??
        tz.timeZoneDatabase.locations['Africa/Nairobi'] ??
        tz.local;
    tz.setLocalLocation(location);

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          _t('notif_channel_name'),
          description: _t('notif_channel_description'),
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      _initialized = true;
    } catch (e, stack) {
      debugPrint('NotificationScheduler.initialize failed gracefully: $e\n$stack');
    }
  }

  /// After a reminder fires (or is tapped), re-arm the next occurrence for
  /// Ethiopian recurrence rules that cannot use OS repeating components.
  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    final payload = response.payload;
    if (payload == null || !payload.startsWith('event:')) return;
    final id = int.tryParse(payload.substring(6));
    if (id == null || id <= 0) return;
    try {
      final prefs = UserPreferencesRepository.instance.getSettings();
      if (!prefs.notificationsEnabled) return;
      setLanguage(AppLanguage.fromString(prefs.language));
      final event = await AppDatabase.instance.getEventById(id);
      if (event == null) return;
      if (event.recurrence == 'NONE' || event.isCompleted) return;
      await scheduleEventReminder(event);
    } catch (e, st) {
      debugPrint('NotificationScheduler: response reschedule failed: $e\n$st');
    }
  }

  static Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final notif = await Permission.notification.request();
      // Best-effort; scheduling falls back to inexact if denied.
      await Permission.scheduleExactAlarm.request();
      return notif.isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return granted;
    }
    return true;
  }

  static int notificationIdFor(int eventId) {
    final id = eventId & 0x7FFFFFFF;
    return id == 0 ? 1001 : id;
  }

  /// Next trigger time for an event, or null if reminders are disabled / past.
  static DateTime? calculateNextTriggerTime(
    EventEntity event, {
    DateTime? now,
  }) {
    if (event.reminderMinutesBefore < 0 || event.isCompleted) return null;

    final nowLocal = now ?? DateTime.now();
    // All-day reminders fire at 08:00 local; timed events use their clock time.
    final hour = event.isAllDay ? 8 : event.hour.clamp(0, 23);
    final minute = event.isAllDay ? 0 : event.minute.clamp(0, 59);
    final offsetMins = event.reminderMinutesBefore;

    DateTime at(int y, int m, int d) {
      return DateTime(y, m, d, hour, minute).subtract(
        Duration(minutes: offsetMins),
      );
    }

    switch (event.recurrence) {
      case 'DAILY': {
        final lookahead = (offsetMins ~/ 1440) + 3;
        for (var dayShift = 0; dayShift <= lookahead; dayShift++) {
          final day = DateTime(
            nowLocal.year,
            nowLocal.month,
            nowLocal.day,
          ).add(Duration(days: dayShift));
          final candidate = at(day.year, day.month, day.day);
          if (candidate.isAfter(nowLocal)) return candidate;
        }
        return null;
      }
      case 'WEEKLY': {
        final anchor = DateTime(
          event.gregorianYear,
          event.gregorianMonth,
          event.gregorianDay,
        );
        final targetDow = anchor.weekday; // 1=Mon .. 7=Sun
        final base = DateTime(
          nowLocal.year,
          nowLocal.month,
          nowLocal.day,
          hour,
          minute,
        );
        final daysToAdd = (targetDow - base.weekday + 7) % 7;
        final first = base.add(Duration(days: daysToAdd));
        final lookahead = (offsetMins ~/ (1440 * 7)) + 4;
        for (var week = 0; week <= lookahead; week++) {
          final occurrence = first.add(Duration(days: week * 7));
          final candidate = occurrence.subtract(Duration(minutes: offsetMins));
          if (candidate.isAfter(nowLocal)) return candidate;
        }
        return null;
      }
      case 'MONTHLY_ETHIOPIAN': {
        final todayEth = EthiopianCalendarEngine.todayEthiopian();
        var testYear = todayEth.year;
        var testMonth = todayEth.month;
        for (var step = 0; step <= 24; step++) {
          final maxDays = EthiopianDate.daysInMonthFor(testYear, testMonth);
          final day = event.ethiopianDay.clamp(1, maxDays);
          final g = EthiopianCalendarEngine.toGregorian(
            EthiopianDate(testYear, testMonth, day),
          );
          final candidate = at(g.year, g.month, g.day);
          if (candidate.isAfter(nowLocal)) return candidate;
          testMonth++;
          if (testMonth > 13) {
            testMonth = 1;
            testYear++;
          }
        }
        return null;
      }
      case 'MONTHLY_GREGORIAN': {
        var year = nowLocal.year;
        var month = nowLocal.month;
        for (var step = 0; step <= 24; step++) {
          final maxDay = DateTime(year, month + 1, 0).day;
          final day = event.gregorianDay.clamp(1, maxDay);
          final candidate = at(year, month, day);
          if (candidate.isAfter(nowLocal)) return candidate;
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return null;
      }
      case 'YEARLY_ETHIOPIAN': {
        var testYear = EthiopianCalendarEngine.todayEthiopian().year;
        for (var step = 0; step <= 5; step++) {
          final maxDays =
              EthiopianDate.daysInMonthFor(testYear, event.ethiopianMonth);
          final day = event.ethiopianDay.clamp(1, maxDays);
          final g = EthiopianCalendarEngine.toGregorian(
            EthiopianDate(testYear, event.ethiopianMonth, day),
          );
          final candidate = at(g.year, g.month, g.day);
          if (candidate.isAfter(nowLocal)) return candidate;
          testYear++;
        }
        return null;
      }
      case 'YEARLY_GREGORIAN': {
        var testYear = nowLocal.year;
        for (var step = 0; step <= 5; step++) {
          final maxDay = DateTime(testYear, event.gregorianMonth + 1, 0).day;
          final day = event.gregorianDay.clamp(1, maxDay);
          final candidate = at(testYear, event.gregorianMonth, day);
          if (candidate.isAfter(nowLocal)) return candidate;
          testYear++;
        }
        return null;
      }
      default: {
        final candidate = at(
          event.gregorianYear,
          event.gregorianMonth,
          event.gregorianDay,
        );
        if (!candidate.isAfter(nowLocal)) return null;
        return candidate;
      }
    }
  }

  static DateTimeComponents? _matchComponents(String recurrence) {
    switch (recurrence) {
      case 'DAILY':
        return DateTimeComponents.time;
      case 'WEEKLY':
        return DateTimeComponents.dayOfWeekAndTime;
      case 'MONTHLY_GREGORIAN':
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        // Ethiopian monthly/yearly need app-driven reschedule.
        return null;
    }
  }

  static Future<void> scheduleEventReminder(EventEntity event) async {
    if (!_initialized) await initialize();
    if (event.id <= 0) return;

    final trigger = calculateNextTriggerTime(event);
    if (trigger == null) {
      await cancelEventReminder(event.id);
      return;
    }

    final tzTrigger = tz.TZDateTime.from(trigger, tz.local);
    final body = event.description.isEmpty
        ? _t('notif_body_fallback')
        : event.description;
    final channelName = _t('notif_channel_name');
    final channelDesc = _t('notif_channel_description');
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFE6A817),
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: event.title,
        ),
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final match = _matchComponents(event.recurrence);

    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id: notificationIdFor(event.id),
        title: event.title,
        body: body,
        scheduledDate: tzTrigger,
        notificationDetails: details,
        androidScheduleMode: mode,
        payload: 'event:${event.id}',
        matchDateTimeComponents: match,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      try {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (e, st) {
        debugPrint(
          'NotificationScheduler: could not schedule reminder: $e\n$st',
        );
      }
    }
  }

  static Future<void> cancelEventReminder(int eventId) async {
    if (!_initialized) await initialize();
    await _plugin.cancel(id: notificationIdFor(eventId));
  }

  static Future<void> cancelAllReminders() async {
    if (!_initialized) await initialize();
    await _plugin.cancelAll();
  }

  static Future<void> rescheduleAll(List<EventEntity> events) async {
    if (!_initialized) await initialize();
    await cancelAllReminders();
    for (final event in events) {
      if (event.reminderMinutesBefore < 0 || event.isCompleted) continue;
      await scheduleEventReminder(event);
    }
  }

  /// Rebuild from DB after boot / cold start when reminders are enabled.
  static Future<void> rescheduleFromDatabaseIfEnabled() async {
    try {
      final prefs = UserPreferencesRepository.instance.getSettings();
      setLanguage(AppLanguage.fromString(prefs.language));
      if (!prefs.notificationsEnabled) return;
      if (!_initialized) await initialize();
      final events = await AppDatabase.instance.getAllEvents();
      await rescheduleAll(events);
    } catch (e, st) {
      debugPrint('NotificationScheduler: startup reschedule failed: $e\n$st');
    }
  }

  /// Immediate smoke-test notification (does not require a saved event).
  static Future<bool> showTestNotification({AppLanguage? language}) async {
    if (language != null) setLanguage(language);
    if (!_initialized) await initialize();
    final allowed = await requestPermissions();
    if (!allowed) return false;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _t('notif_channel_name'),
        channelDescription: _t('notif_channel_description'),
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFFE6A817),
      ),
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 900001,
      title: _t('notif_test_title'),
      body: _t('notif_test_body'),
      notificationDetails: details,
      payload: 'test',
    );
    return true;
  }
}
