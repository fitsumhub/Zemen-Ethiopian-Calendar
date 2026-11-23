import 'dart:io';

import 'package:ethiocal/core/export/ics_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IcsImporter', () {
    test('parses timed UTC VEVENT into dual-calendar EventEntity', () {
      const raw = '''
BEGIN:VCALENDAR
VERSION:2.0
X-WR-CALNAME:World Cup
BEGIN:VEVENT
SUMMARY:🇲🇽 Mexico - 🇿🇦 South Africa
DESCRIPTION:https://www.fotmob.com/match/4667751\\nWorld Cup 2026
DTSTART:20260611T190000Z
DTEND:20260611T204500Z
UID:4667751@fotmob.com
URL:https://www.fotmob.com/match/4667751
END:VEVENT
END:VCALENDAR
''';
      final result = IcsImporter.parse(
        raw,
        createdAt: DateTime.utc(2026, 1, 1),
      );

      expect(result.calendarName, 'World Cup');
      expect(result.count, 1);
      expect(result.skippedMalformed, 0);

      final event = result.events.single;
      expect(event.title, contains('Mexico'));
      expect(event.isAllDay, isFalse);
      expect(event.gregorianYear, 2026);
      expect(event.gregorianMonth, 6);
      expect(event.description, contains('ICS-UID:4667751@fotmob.com'));
      expect(event.ethiopianYear, greaterThan(2010));
    });

    test('parses all-day VALUE=DATE events', () {
      const raw = '''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Enkutatash
DTSTART;VALUE=DATE:20260911
UID:enk@test
END:VEVENT
END:VCALENDAR
''';
      final result = IcsImporter.parse(raw);
      expect(result.count, 1);
      expect(result.events.single.isAllDay, isTrue);
      expect(result.events.single.gregorianDay, 11);
      expect(result.events.single.hour, 8);
    });

    test('duplicate detection matches by UID marker', () {
      final parsed = IcsImporter.parse('''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Test Match
DTSTART:20260611T190000Z
UID:dup@test
END:VEVENT
END:VCALENDAR
''');
      final a = parsed.events.single;
      final b = a.copyWith(id: 9);
      expect(IcsImporter.isLikelyDuplicate(a, b), isTrue);
    });

    test('imports World Cup.ics fixture from Downloads when present', () {
      final path =
          r'c:\Users\ROG\Downloads\Telegram Desktop\World Cup.ics';
      final file = File(path);
      if (!file.existsSync()) {
        // Skip quietly on machines without the Telegram download.
        return;
      }
      final raw = file.readAsStringSync();
      final result = IcsImporter.parse(raw);
      expect(result.calendarName, 'World Cup');
      expect(result.count, greaterThanOrEqualTo(100));
      expect(result.events.first.title, isNotEmpty);
      expect(
        result.events.every((e) => e.gregorianYear >= 2026),
        isTrue,
      );
    });
  });
}
