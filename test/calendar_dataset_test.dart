import 'dart:convert';
import 'dart:io';

import 'package:ethiocal/core/calendar/ethiopian_date_converter.dart';
import 'package:ethiocal/core/calendar/geez_numeral.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final dataDir = Directory('$root/assets/data/ethiopian_calendar');
  final fixturesDir = Directory('$root/test/fixtures');

  test('all required calendar JSON datasets exist and parse', () {
    const required = [
      'months.json',
      'weekdays.json',
      'geez_numerals.json',
      'fixed_holidays.json',
      'movable_feasts.json',
      'fasting_periods.json',
      'orthodox_saints.json',
      'national_holidays.json',
      'regional_festivals.json',
      'islamic_events.json',
      'historical_events.json',
      'sources.json',
    ];
    for (final name in required) {
      final file = File('${dataDir.path}/$name');
      expect(file.existsSync(), isTrue, reason: '$name missing');
      final json = jsonDecode(file.readAsStringSync());
      expect(json, isA<Map>());
      expect((json as Map)['version'], isNotNull);
    }
    // Conversion vectors stay in test/fixtures (not shipped in the APK).
    expect(
      File('${fixturesDir.path}/calendar_test_vectors.json').existsSync(),
      isTrue,
    );
  });

  test('EOTC-derived conversion vectors match EthioCal JDN engine', () {
    final file = File('${fixturesDir.path}/calendar_test_vectors.json');
    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final vectors = json['vectors'] as List<dynamic>;
    expect(vectors.length, greaterThan(50));
    expect(json['ethiopian_epoch_jdn'], EthiopianDateConverter.ethiopianEpochJdn);

    for (final raw in vectors) {
      final v = raw as Map<String, dynamic>;
      final jdn = v['jdn'] as int;
      final e = (v['ethiopic'] as List).cast<int>();
      final g = (v['gregorian'] as List).cast<int>();
      expect(
        EthiopianDateConverter.ethiopianToJulianDay(e[0], e[1], e[2]),
        jdn,
        reason: 'eth $e',
      );
      expect(
        EthiopianDateConverter.gregorianToJulianDay(g[0], g[1], g[2]),
        jdn,
        reason: 'greg $g',
      );
      final backE = EthiopianDateConverter.julianDayToEthiopian(jdn);
      final backG = EthiopianDateConverter.julianDayToGregorian(jdn);
      expect([backE.year, backE.month, backE.day], e);
      expect([backG.year, backG.month, backG.day], g);
    }
  });

  test('Geez examples in dataset match GeezNumeral', () {
    final json = jsonDecode(
      File('${dataDir.path}/geez_numerals.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final raw in json['examples'] as List) {
      final e = raw as Map<String, dynamic>;
      expect(GeezNumeral.toGeez(e['n'] as int), e['geez']);
    }
  });

  test('fixed holiday dataset ids appear in HolidayEngine year list', () {
    final json = jsonDecode(
      File('${dataDir.path}/fixed_holidays.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final holidays = HolidayEngine.getHolidaysForYear(2017);
    final ids = holidays.map((h) => h.id.split('_').first).toSet();
    for (final raw in json['holidays'] as List) {
      final id = (raw as Map)['id'] as String;
      // genna rule uses prefix genna_
      expect(
        holidays.any((h) => h.id.startsWith('${id}_') || h.id.startsWith(id)),
        isTrue,
        reason: 'missing holiday $id (seen prefixes $ids)',
      );
    }
  });

  test('no duplicate holiday ids for a sample year', () {
    final holidays = HolidayEngine.getHolidaysForYear(2017);
    final ids = holidays.map((h) => h.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
