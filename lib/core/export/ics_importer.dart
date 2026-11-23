import '../calendar/ethiopian_calendar_engine.dart';
import '../calendar/gregorian_date.dart';
import '../../data/models/event_entity.dart';

/// Parsed iCalendar import batch.
class IcsImportResult {
  final List<EventEntity> events;
  final int skippedMalformed;
  final String? calendarName;

  const IcsImportResult({
    required this.events,
    this.skippedMalformed = 0,
    this.calendarName,
  });

  int get count => events.length;
}

/// Imports VEVENT entries from a standard iCalendar (.ics) document into
/// [EventEntity] rows (Gregorian → Ethiopian dual dates).
class IcsImporter {
  /// Marker stored in descriptions so re-imports can skip the same UID.
  static const uidMarkerPrefix = 'ICS-UID:';

  static IcsImportResult parse(
    String raw, {
    DateTime? createdAt,
    String defaultCategory = 'OTHER',
    String defaultColorHex = '#10B981',
  }) {
    final unfolded = _unfold(raw);
    final calendarName = _calendarProperty(unfolded, 'X-WR-CALNAME') ??
        _calendarProperty(unfolded, 'NAME');

    final events = <EventEntity>[];
    var skipped = 0;
    final nowMs = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;

    final blocks = _extractVEvents(unfolded);
    for (final block in blocks) {
      try {
        final event = _parseVEvent(
          block,
          createdAtMs: nowMs + events.length,
          defaultCategory: defaultCategory,
          defaultColorHex: defaultColorHex,
          calendarName: calendarName,
        );
        if (event == null) {
          skipped++;
          continue;
        }
        events.add(event);
      } catch (_) {
        skipped++;
      }
    }

    return IcsImportResult(
      events: events,
      skippedMalformed: skipped,
      calendarName: calendarName,
    );
  }

  static bool isLikelyDuplicate(EventEntity existing, EventEntity incoming) {
    final incomingUid = extractUid(incoming.description);
    if (incomingUid != null &&
        incomingUid.isNotEmpty &&
        existing.description.contains('$uidMarkerPrefix$incomingUid')) {
      return true;
    }
    return existing.title == incoming.title &&
        existing.gregorianYear == incoming.gregorianYear &&
        existing.gregorianMonth == incoming.gregorianMonth &&
        existing.gregorianDay == incoming.gregorianDay &&
        existing.hour == incoming.hour &&
        existing.minute == incoming.minute &&
        existing.isAllDay == incoming.isAllDay;
  }

  static String? extractUid(String description) {
    for (final line in description.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.startsWith(uidMarkerPrefix)) {
        return trimmed.substring(uidMarkerPrefix.length).trim();
      }
    }
    return null;
  }

  static String _unfold(String raw) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final out = StringBuffer();
    for (final line in normalized.split('\n')) {
      if (line.startsWith(' ') || line.startsWith('\t')) {
        out.write(line.substring(1));
      } else {
        if (out.isNotEmpty) out.write('\n');
        out.write(line);
      }
    }
    return out.toString();
  }

  static String? _calendarProperty(String text, String key) {
    final re = RegExp(
      '^${RegExp.escape(key)}[;:](.*)\$',
      multiLine: true,
      caseSensitive: false,
    );
    final match = re.firstMatch(text);
    if (match == null) return null;
    return _unescape(_stripParams(match.group(1) ?? '').trim());
  }

  static List<String> _extractVEvents(String text) {
    final blocks = <String>[];
    final re = RegExp(
      r'BEGIN:VEVENT\n(.*?)END:VEVENT',
      dotAll: true,
      caseSensitive: false,
    );
    for (final match in re.allMatches(text)) {
      blocks.add(match.group(1) ?? '');
    }
    return blocks;
  }

  static EventEntity? _parseVEvent(
    String block, {
    required int createdAtMs,
    required String defaultCategory,
    required String defaultColorHex,
    String? calendarName,
  }) {
    final summary = _property(block, 'SUMMARY');
    if (summary == null || summary.trim().isEmpty) return null;

    final dtStartRaw = _propertyRaw(block, 'DTSTART');
    if (dtStartRaw == null) return null;

    final parsedStart = _parseDateTime(dtStartRaw);
    if (parsedStart == null) return null;

    final local = parsedStart.dateTime.toLocal();
    final eth = EthiopianCalendarEngine.toEthiopian(
      GregorianDate(local.year, local.month, local.day),
    );

    final descriptionParts = <String>[];
    final uid = _property(block, 'UID');
    if (uid != null && uid.isNotEmpty) {
      descriptionParts.add('$uidMarkerPrefix$uid');
    }
    if (calendarName != null && calendarName.isNotEmpty) {
      descriptionParts.add('Calendar: $calendarName');
    }
    final description = _property(block, 'DESCRIPTION');
    if (description != null && description.trim().isNotEmpty) {
      descriptionParts.add(description.trim());
    }
    final url = _property(block, 'URL');
    if (url != null && url.trim().isNotEmpty) {
      descriptionParts.add(url.trim());
    }

    final categories = _property(block, 'CATEGORIES');
    final category = _mapCategory(categories) ?? defaultCategory;
    final recurrence = _mapRecurrence(_property(block, 'RRULE'));

    return EventEntity(
      id: 0,
      title: summary.trim(),
      description: descriptionParts.join('\n'),
      category: category,
      ethiopianYear: eth.year,
      ethiopianMonth: eth.month,
      ethiopianDay: eth.day,
      gregorianYear: local.year,
      gregorianMonth: local.month,
      gregorianDay: local.day,
      hour: parsedStart.allDay ? 8 : local.hour,
      minute: parsedStart.allDay ? 0 : local.minute,
      isAllDay: parsedStart.allDay,
      recurrence: recurrence,
      reminderMinutesBefore: parsedStart.allDay ? 0 : 15,
      colorHex: defaultColorHex,
      isCompleted: false,
      createdAt: createdAtMs,
    );
  }

  static String? _property(String block, String key) {
    final raw = _propertyRaw(block, key);
    if (raw == null) return null;
    return _unescape(_stripParams(raw).trim());
  }

  static String? _propertyRaw(String block, String key) {
    final re = RegExp(
      '^${RegExp.escape(key)}([;:].*)\$',
      multiLine: true,
      caseSensitive: false,
    );
    final match = re.firstMatch(block);
    return match?.group(1);
  }

  static String _stripParams(String raw) {
    // ";VALUE=DATE:20240101" or ":text"
    final idx = raw.indexOf(':');
    if (idx < 0) return raw;
    return raw.substring(idx + 1);
  }

  static ({DateTime dateTime, bool allDay})? _parseDateTime(String raw) {
    final upper = raw.toUpperCase();
    final allDay = upper.contains('VALUE=DATE');
    final value = _stripParams(raw).trim();
    if (value.isEmpty) return null;

    // YYYYMMDD
    if (RegExp(r'^\d{8}$').hasMatch(value)) {
      final y = int.parse(value.substring(0, 4));
      final m = int.parse(value.substring(4, 6));
      final d = int.parse(value.substring(6, 8));
      return (dateTime: DateTime(y, m, d), allDay: true);
    }

    // YYYYMMDDTHHMMSSZ or YYYYMMDDTHHMMSS
    final m = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z)?$',
    ).firstMatch(value);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      final h = int.parse(m.group(4)!);
      final mi = int.parse(m.group(5)!);
      final s = int.parse(m.group(6)!);
      final isUtc = m.group(7) == 'Z';
      final dt = isUtc
          ? DateTime.utc(y, mo, d, h, mi, s)
          : DateTime(y, mo, d, h, mi, s);
      return (dateTime: dt, allDay: allDay);
    }

    // YYYYMMDDTHHMM (no seconds)
    final m2 = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(Z)?$',
    ).firstMatch(value);
    if (m2 != null) {
      final y = int.parse(m2.group(1)!);
      final mo = int.parse(m2.group(2)!);
      final d = int.parse(m2.group(3)!);
      final h = int.parse(m2.group(4)!);
      final mi = int.parse(m2.group(5)!);
      final isUtc = m2.group(6) == 'Z';
      final dt = isUtc
          ? DateTime.utc(y, mo, d, h, mi)
          : DateTime(y, mo, d, h, mi);
      return (dateTime: dt, allDay: allDay);
    }

    return null;
  }

  static String? _mapCategory(String? categories) {
    if (categories == null || categories.trim().isEmpty) return null;
    final first = categories.split(',').first.trim().toUpperCase();
    const known = {
      'TASK',
      'MEETING',
      'BIRTHDAY',
      'EXAM',
      'ANNIVERSARY',
      'RELIGIOUS',
      'CULTURAL',
      'OTHER',
    };
    if (known.contains(first)) return first;
    return 'OTHER';
  }

  static String _mapRecurrence(String? rrule) {
    if (rrule == null || rrule.isEmpty) return 'NONE';
    final upper = rrule.toUpperCase();
    if (upper.contains('FREQ=DAILY')) return 'DAILY';
    if (upper.contains('FREQ=WEEKLY')) return 'WEEKLY';
    if (upper.contains('FREQ=MONTHLY')) return 'MONTHLY_GREGORIAN';
    if (upper.contains('FREQ=YEARLY')) return 'YEARLY_GREGORIAN';
    return 'NONE';
  }

  static String _unescape(String value) {
    return value
        .replaceAll('\\n', '\n')
        .replaceAll('\\N', '\n')
        .replaceAll('\\,', ',')
        .replaceAll('\\;', ';')
        .replaceAll('\\\\', '\\');
  }
}
