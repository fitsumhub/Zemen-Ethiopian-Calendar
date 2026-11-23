import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/calendar/gregorian_date.dart';
import '../../core/export/ics_importer.dart';
import '../../core/holidays/holiday_engine.dart';
import '../../core/localization/app_language.dart';
import '../../core/notifications/notification_scheduler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/home_widget_sync.dart';
import '../../data/local/app_database.dart';
import '../../data/models/event_entity.dart';
import '../../data/preferences/user_preferences_repository.dart';

// -------------------------------------------------------------
// Core Services & Repositories Providers
// -------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final userPreferencesRepoProvider = Provider<UserPreferencesRepository>((ref) {
  return UserPreferencesRepository.instance;
});

// -------------------------------------------------------------
// User Settings State Management
// -------------------------------------------------------------

class UserSettingsNotifier extends Notifier<UserSettings> {
  late final UserPreferencesRepository _repo;

  @override
  UserSettings build() {
    try {
      _repo = ref.read(userPreferencesRepoProvider);
      return _repo.getSettings();
    } catch (_) {
      return const UserSettings();
    }
  }

  Future<void> setLanguage(String lang) async {
    final normalized = AppLanguage.normalizePreference(lang);
    await _repo.setLanguage(normalized);
    state = state.copyWith(language: normalized);
    NotificationScheduler.setLanguage(AppLanguage.fromString(normalized));
    try {
      await HomeWidgetSync.sync(
        styleIndex: _repo.getWidgetStyle(),
        lang: AppLanguage.fromString(normalized),
      );
    } catch (_) {
      // Widget channels unavailable in tests / unsupported platforms.
    }
  }

  Future<void> setNumeralType(String type) async {
    await _repo.setNumeralType(type);
    state = state.copyWith(numeralType: type);
  }

  Future<void> setCalendarFormat(String format) async {
    await _repo.setCalendarFormat(format);
    state = state.copyWith(calendarFormat: format);
  }

  Future<void> setThemeMode(String mode) async {
    await _repo.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAccentPalette(String palette) async {
    await _repo.setAccentPalette(palette);
    state = state.copyWith(accentPalette: palette);
  }

  Future<void> setFirstDayOfWeek(String firstDay) async {
    await _repo.setFirstDayOfWeek(firstDay);
    state = state.copyWith(firstDayOfWeek: firstDay);
    try {
      await HomeWidgetSync.sync(
        styleIndex: _repo.getWidgetStyle(),
        lang: AppLanguage.fromString(state.language),
      );
    } catch (_) {}
  }

  Future<void> setShowFasting(bool enabled) async {
    await _repo.setShowFasting(enabled);
    state = state.copyWith(showFasting: enabled);
  }

  Future<void> setShowMonthlySaints(bool enabled) async {
    await _repo.setShowMonthlySaints(enabled);
    state = state.copyWith(showMonthlySaints: enabled);
  }

  Future<void> setShowFootball(bool enabled) async {
    await _repo.setShowFootball(enabled);
    state = state.copyWith(showFootball: enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final allowed = await NotificationScheduler.requestPermissions();
      if (!allowed) {
        await _repo.setNotificationsEnabled(false);
        state = state.copyWith(notificationsEnabled: false);
        return;
      }
    }
    await _repo.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);

    final events = ref.read(eventsNotifierProvider).value ?? [];
    if (enabled) {
      await NotificationScheduler.rescheduleAll(events);
    } else {
      await NotificationScheduler.cancelAllReminders();
    }
  }

  Future<void> resetAppearanceDefaults() async {
    await _repo.setThemeMode('LIGHT');
    await _repo.setAccentPalette(AppTheme.defaultPaletteId);
    await _repo.setNumeralType('ARABIC');
    await _repo.setCalendarFormat('ETHIOPIAN');
    await _repo.setFirstDayOfWeek('MONDAY');
    state = state.copyWith(
      themeMode: 'LIGHT',
      accentPalette: AppTheme.defaultPaletteId,
      numeralType: 'ARABIC',
      calendarFormat: 'ETHIOPIAN',
      firstDayOfWeek: 'MONDAY',
    );
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _repo.setOnboardingCompleted(completed);
    state = state.copyWith(onboardingCompleted: completed);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsNotifier, UserSettings>(UserSettingsNotifier.new);

final currentAppLanguageProvider = Provider<AppLanguage>((ref) {
  final settings = ref.watch(userSettingsProvider);
  return AppLanguage.fromString(settings.language);
});

// -------------------------------------------------------------
// Calendar Navigation & Selection Providers (Riverpod 3 Notifiers)
// -------------------------------------------------------------

class SelectedDateNotifier extends Notifier<EthiopianDate> {
  @override
  EthiopianDate build() => EthiopianCalendarEngine.todayEthiopian();

  @override
  set state(EthiopianDate value) => super.state = value;
  void set(EthiopianDate value) => state = value;
}

class ViewYearNotifier extends Notifier<int> {
  @override
  int build() {
    final format = ref.watch(userSettingsProvider).calendarFormat;
    if (format == 'GREGORIAN') {
      return EthiopianCalendarEngine.todayGregorian().year;
    }
    return EthiopianCalendarEngine.todayEthiopian().year;
  }

  @override
  set state(int value) => super.state = value;
  void set(int value) => state = value;
}

class ViewMonthNotifier extends Notifier<int> {
  @override
  int build() {
    final format = ref.watch(userSettingsProvider).calendarFormat;
    if (format == 'GREGORIAN') {
      return EthiopianCalendarEngine.todayGregorian().month;
    }
    return EthiopianCalendarEngine.todayEthiopian().month;
  }

  @override
  set state(int value) => super.state = value;
  void set(int value) => state = value;
}

class CalendarViewModeNotifier extends Notifier<String> {
  @override
  String build() => 'MONTH';

  @override
  set state(String value) => super.state = value;
  void set(String value) => state = value;
}

class EventSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
  void set(String value) => state = value;
}

class EventCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  @override
  set state(String value) => super.state = value;
  void set(String value) => state = value;
}

/// ALL | OPEN | DONE — keeps Events list easy to scan.
class EventStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  @override
  set state(String value) => super.state = value;
  void set(String value) => state = value;
}

final todayEthiopianProvider = Provider<EthiopianDate>((ref) {
  return EthiopianCalendarEngine.todayEthiopian();
});

final todayGregorianProvider = Provider<GregorianDate>((ref) {
  return EthiopianCalendarEngine.todayGregorian();
});

final selectedDateProvider =
    NotifierProvider<SelectedDateNotifier, EthiopianDate>(SelectedDateNotifier.new);

final viewYearProvider =
    NotifierProvider<ViewYearNotifier, int>(ViewYearNotifier.new);

final viewMonthProvider =
    NotifierProvider<ViewMonthNotifier, int>(ViewMonthNotifier.new);

final calendarViewModeProvider =
    NotifierProvider<CalendarViewModeNotifier, String>(CalendarViewModeNotifier.new);

// -------------------------------------------------------------
// Events State Management
// -------------------------------------------------------------

class EventsNotifier extends AsyncNotifier<List<EventEntity>> {
  late final AppDatabase _db;

  @override
  Future<List<EventEntity>> build() async {
    _db = ref.read(databaseProvider);
    return _db.getAllEvents();
  }

  Future<void> refresh() async {
    // Keep prior list visible while reloading so save/import doesn't flash empty.
    final previous = state.asData?.value;
    state = await AsyncValue.guard(() => _db.getAllEvents());
    if (state.hasError && previous != null) {
      state = AsyncValue.data(previous);
    }
  }

  Future<int> saveEvent(EventEntity event) async {
    final int id;
    if (event.id == 0) {
      id = await _db.insertEvent(event);
    } else {
      await _db.updateEvent(event);
      id = event.id;
    }
    final saved = event.copyWith(id: id);

    // Reminders must never block persistence — exact-alarm / TZ failures are common.
    try {
      final settings = ref.read(userSettingsProvider);
      if (settings.notificationsEnabled && saved.reminderMinutesBefore >= 0) {
        NotificationScheduler.setLanguage(
          AppLanguage.fromString(settings.language),
        );
        final allowed = await NotificationScheduler.requestPermissions();
        if (allowed) {
          await NotificationScheduler.scheduleEventReminder(saved);
        }
      } else if (saved.reminderMinutesBefore < 0) {
        await NotificationScheduler.cancelEventReminder(saved.id);
      }
    } catch (_) {
      // Keep the saved event even if scheduling fails.
    }

    await refresh();
    return id;
  }

  /// Bulk-import events from an .ics parse. Skips likely duplicates (UID / title+time).
  Future<({int imported, int skipped})> importEvents(
    List<EventEntity> incoming,
  ) async {
    if (incoming.isEmpty) return (imported: 0, skipped: 0);
    final existing = state.value ?? await _db.getAllEvents();
    final known = List<EventEntity>.from(existing);
    var imported = 0;
    var skipped = 0;
    final settings = ref.read(userSettingsProvider);

    for (final event in incoming) {
      final duplicate = known.any(
        (e) => IcsImporter.isLikelyDuplicate(e, event),
      );
      if (duplicate) {
        skipped++;
        continue;
      }
      final id = await _db.insertEvent(event);
      final saved = event.copyWith(id: id);
      known.add(saved);
      if (settings.notificationsEnabled) {
        try {
          await NotificationScheduler.scheduleEventReminder(saved);
        } catch (_) {}
      }
      imported++;
    }

    await refresh();
    return (imported: imported, skipped: skipped);
  }

  Future<void> deleteEvent(int id) async {
    await NotificationScheduler.cancelEventReminder(id);
    await _db.deleteEventById(id);
    await refresh();
  }

  Future<void> toggleEventCompletion(EventEntity event) async {
    if (event.id == 0) return;
    final updated = event.copyWith(isCompleted: !event.isCompleted);
    await _db.updateEvent(updated);
    if (updated.isCompleted) {
      await NotificationScheduler.cancelEventReminder(updated.id);
    } else if (ref.read(userSettingsProvider).notificationsEnabled) {
      await NotificationScheduler.scheduleEventReminder(updated);
    }
    await refresh();
  }

  Future<int> scheduleAllAnnualHolidays({
    required int year,
    int alertHour = 8,
    int alertMinute = 0,
    int reminderMinutesBefore = 0,
  }) async {
    final holidays = HolidayEngine.getHolidaysForYear(year).filterHolidayReminders();
    final currentEvents = state.value ?? [];
    int count = 0;

    for (final holiday in holidays) {
      final existing = currentEvents.firstWhere(
        (e) =>
            (e.ethiopianYear == holiday.ethiopianDate.year ||
                e.recurrence == 'YEARLY_ETHIOPIAN') &&
            e.ethiopianMonth == holiday.ethiopianDate.month &&
            e.ethiopianDay == holiday.ethiopianDate.day &&
            (e.title.contains(holiday.titleEnglish) ||
                e.title.contains(holiday.titleAmharic)),
        orElse: EventEntity.empty,
      );

      final gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate);
      final event = EventEntity(
        id: existing.id != 0 ? existing.id : 0,
        title: '${holiday.titleAmharic} (${holiday.titleEnglish})',
        description: holiday.description,
        category: 'HOLIDAY',
        ethiopianYear: holiday.ethiopianDate.year,
        ethiopianMonth: holiday.ethiopianDate.month,
        ethiopianDay: holiday.ethiopianDate.day,
        gregorianYear: gDate.year,
        gregorianMonth: gDate.month,
        gregorianDay: gDate.day,
        hour: alertHour,
        minute: alertMinute,
        isAllDay: true,
        recurrence: 'NONE',
        reminderMinutesBefore: reminderMinutesBefore,
        colorHex: holiday.isPublicHoliday ? '#EF4444' : '#F59E0B',
        createdAt: existing.id != 0
            ? existing.createdAt
            : DateTime.now().millisecondsSinceEpoch,
      );

      final int id;
      if (event.id == 0) {
        id = await _db.insertEvent(event);
      } else {
        await _db.updateEvent(event);
        id = event.id;
      }
      final saved = event.copyWith(id: id);
      if (ref.read(userSettingsProvider).notificationsEnabled) {
        await NotificationScheduler.scheduleEventReminder(saved);
      }
      count++;
    }

    await refresh();
    return count;
  }

  Future<int> clearAllEvents() async {
    final events = state.value ?? await _db.getAllEvents();
    for (final event in events) {
      await NotificationScheduler.cancelEventReminder(event.id);
      await _db.deleteEventById(event.id);
    }
    await refresh();
    return events.length;
  }

  Future<void> rescheduleAllReminders() async {
    final settings = ref.read(userSettingsProvider);
    NotificationScheduler.setLanguage(
      AppLanguage.fromString(settings.language),
    );
    if (!settings.notificationsEnabled) {
      await NotificationScheduler.cancelAllReminders();
      return;
    }
    final allowed = await NotificationScheduler.requestPermissions();
    if (!allowed) return;
    final events = state.value ?? await _db.getAllEvents();
    await NotificationScheduler.rescheduleAll(events);
  }
}

extension HolidayFilterExtension on List<Holiday> {
  List<Holiday> filterHolidayReminders() {
    return where(
      (h) =>
          h.isPublicHoliday ||
          h.type == HolidayType.nationalPublic ||
          h.type == HolidayType.orthodoxMajor ||
          h.type == HolidayType.islamic,
    ).toList();
  }
}

final eventsNotifierProvider =
    AsyncNotifierProvider<EventsNotifier, List<EventEntity>>(EventsNotifier.new);

final eventSearchQueryProvider =
    NotifierProvider<EventSearchQueryNotifier, String>(EventSearchQueryNotifier.new);

final eventCategoryFilterProvider =
    NotifierProvider<EventCategoryFilterNotifier, String>(
        EventCategoryFilterNotifier.new);

final eventStatusFilterProvider =
    NotifierProvider<EventStatusFilterNotifier, String>(
        EventStatusFilterNotifier.new);

final filteredEventsProvider = Provider<List<EventEntity>>((ref) {
  final eventsAsync = ref.watch(eventsNotifierProvider);
  final query = ref.watch(eventSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(eventCategoryFilterProvider);
  final status = ref.watch(eventStatusFilterProvider);

  return eventsAsync.maybeWhen(
    data: (events) {
      final filtered = events.where((event) {
        final matchesQuery = query.isEmpty ||
            event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.category.toLowerCase().contains(query);
        final matchesCategory = category == 'ALL' || event.category == category;
        final matchesStatus = status == 'ALL' ||
            (status == 'OPEN' && !event.isCompleted) ||
            (status == 'DONE' && event.isCompleted);
        return matchesQuery && matchesCategory && matchesStatus;
      }).toList();

      // Chronological by Ethiopian date/time; completed sink when status=ALL.
      filtered.sort((a, b) {
        if (status == 'ALL' && a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        final dateCmp = a.ethiopianYear != b.ethiopianYear
            ? a.ethiopianYear.compareTo(b.ethiopianYear)
            : a.ethiopianMonth != b.ethiopianMonth
                ? a.ethiopianMonth.compareTo(b.ethiopianMonth)
                : a.ethiopianDay.compareTo(b.ethiopianDay);
        if (dateCmp != 0) return dateCmp;
        if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
        final aMin = a.hour * 60 + a.minute;
        final bMin = b.hour * 60 + b.minute;
        return aMin.compareTo(bMin);
      });
      return filtered;
    },
    orElse: () => [],
  );
});

bool eventMatchesDate(EventEntity event, EthiopianDate date) {
  switch (event.recurrence) {
    case 'NONE':
      return event.ethiopianYear == date.year &&
          event.ethiopianMonth == date.month &&
          event.ethiopianDay == date.day;
    case 'DAILY':
      return true;
    case 'WEEKLY':
      final eventDow = EthiopianCalendarEngine.getDayOfWeek(
        EthiopianDate(event.ethiopianYear, event.ethiopianMonth, event.ethiopianDay),
      );
      final targetDow = EthiopianCalendarEngine.getDayOfWeek(date);
      return eventDow == targetDow;
    case 'MONTHLY_ETHIOPIAN':
      return event.ethiopianDay == date.day;
    case 'MONTHLY_GREGORIAN':
      final gDate = EthiopianCalendarEngine.toGregorian(date);
      return event.gregorianDay == gDate.day;
    case 'YEARLY_ETHIOPIAN':
      return event.ethiopianMonth == date.month && event.ethiopianDay == date.day;
    case 'YEARLY_GREGORIAN':
      final gDate = EthiopianCalendarEngine.toGregorian(date);
      return event.gregorianMonth == gDate.month && event.gregorianDay == gDate.day;
    default:
      return event.ethiopianYear == date.year &&
          event.ethiopianMonth == date.month &&
          event.ethiopianDay == date.day;
  }
}

String getRelativeDateLabel(EthiopianDate today, EthiopianDate target, bool isGreg) {
  final diff = EthiopianCalendarEngine.daysBetween(today, target);
  if (isGreg) {
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1) return 'In $diff days';
    return '${-diff} days ago';
  }
  if (diff == 0) return 'ዛሬ';
  if (diff == 1) return 'ነገ';
  if (diff == -1) return 'ትናንት';
  if (diff > 1) return 'ከ $diff ቀናት በኋላ';
  return 'ከ ${-diff} ቀናት በፊት';
}

final eventsForSelectedDateProvider = Provider<List<EventEntity>>((ref) {
  final eventsAsync = ref.watch(eventsNotifierProvider);
  final selected = ref.watch(selectedDateProvider);

  return eventsAsync.maybeWhen(
    data: (events) => events.where((e) => eventMatchesDate(e, selected)).toList(),
    orElse: () => [],
  );
});

final holidaysForViewYearProvider = Provider<List<Holiday>>((ref) {
  final year = ref.watch(viewYearProvider);
  final month = ref.watch(viewMonthProvider);
  final format = ref.watch(userSettingsProvider).calendarFormat;

  // In GC month view, [year]/[month] are Gregorian — load Ethiopian years
  // that the focused Gregorian month actually spans.
  if (format == 'GREGORIAN') {
    final gMonth = month.clamp(1, 12);
    final days = GregorianDate.daysInMonthFor(year, gMonth);
    final start = EthiopianCalendarEngine.toEthiopian(
      GregorianDate(year, gMonth, 1),
    );
    final end = EthiopianCalendarEngine.toEthiopian(
      GregorianDate(year, gMonth, days),
    );
    final years = <int>{start.year, end.year};
    return years.expand(HolidayEngine.getHolidaysForYear).toList();
  }

  return HolidayEngine.getHolidaysForYear(year);
});

final upcomingHolidayProvider = Provider<Holiday?>((ref) {
  final today = ref.watch(todayEthiopianProvider);
  final holidays = HolidayEngine.getHolidaysForYear(today.year);
  final upcoming = holidays.where((h) => h.ethiopianDate >= today).toList();
  if (upcoming.isNotEmpty) {
    return upcoming.first;
  }
  final nextYearHolidays = HolidayEngine.getHolidaysForYear(today.year + 1);
  return nextYearHolidays.isNotEmpty ? nextYearHolidays.first : null;
});
