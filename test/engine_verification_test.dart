// Independent verification of the Ethiopian calendar engine.
//
// No expected value in this file is produced by the engine itself. They come
// from three sources that share no code with it:
//
//   1. Historical date pairs that are public record (section 1).
//   2. A day-by-day "odometer" that walks both calendars forward and backward
//      from one anchor using only month-length rules, never a Julian Day
//      Number formula; the Gregorian side is Dart's own DateTime (section 2).
//   3. The Meeus Julian-calendar Easter algorithm, the computus the Orthodox
//      churches share, as a cross-check on Bahire Hasab (section 4).
//
// The audited range is Gregorian 1900-2100 (about 73,400 consecutive days).

import 'package:ethiocal/core/calendar/bahire_hasab.dart';
import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/ethiopian_date_converter.dart';
import 'package:ethiocal/core/calendar/gregorian_date.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Eth = ({int y, int m, int d});

/// Ethiopian leap year: the year of Luke, whose Pagume has a sixth day.
bool _isEthLeap(int y) => y % 4 == 3;

int _lastDay(int y, int m) => m == 13 ? (_isEthLeap(y) ? 6 : 5) : 30;

_Eth _next(_Eth e) {
  if (e.d < _lastDay(e.y, e.m)) return (y: e.y, m: e.m, d: e.d + 1);
  if (e.m < 13) return (y: e.y, m: e.m + 1, d: 1);
  return (y: e.y + 1, m: 1, d: 1);
}

_Eth _prev(_Eth e) {
  if (e.d > 1) return (y: e.y, m: e.m, d: e.d - 1);
  if (e.m > 1) return (y: e.y, m: e.m - 1, d: 30);
  return (y: e.y - 1, m: 13, d: _lastDay(e.y - 1, 13));
}

GregorianDate _g(DateTime dt) => GregorianDate(dt.year, dt.month, dt.day);

/// Orthodox (Julian computus) Easter for a Gregorian year, returned as a
/// Gregorian date. Meeus' Julian algorithm gives the Julian-calendar date;
/// adding 13 days converts it for 1 March 1900 - 28 February 2100.
DateTime _orthodoxEaster(int gregorianYear) {
  final a = gregorianYear % 4;
  final b = gregorianYear % 7;
  final c = gregorianYear % 19;
  final d = (19 * c + 15) % 30;
  final e = (2 * a + 4 * b - d + 34) % 7;
  final julianMonth = (d + e + 114) ~/ 31;
  final julianDay = (d + e + 114) % 31 + 1;
  return DateTime.utc(gregorianYear, julianMonth, julianDay)
      .add(const Duration(days: 13));
}

void main() {
  group('1. Historical anchor dates (public record)', () {
    // (Ethiopian y, m, d) <-> (Gregorian y, m, d), ISO weekday or null.
    const anchors = <(String, int, int, int, int, int, int, int?)>[
      ('Battle of Adwa', 1888, 6, 23, 1896, 3, 1, DateTime.sunday),
      ('Liberation of Addis Ababa', 1933, 8, 27, 1941, 5, 5, null),
      ('Deposition of Haile Selassie', 1967, 1, 2, 1974, 9, 12, null),
      ('Fall of the Derg (Ginbot 20)', 1983, 9, 20, 1991, 5, 28, null),
      ('Ethiopian Millennium', 2000, 1, 1, 2007, 9, 12, DateTime.wednesday),
      ('Pagume 6 of leap year 2015', 2015, 13, 6, 2023, 9, 11, null),
      ('New Year 2016 (after leap year)', 2016, 1, 1, 2023, 9, 12, null),
      ('New Year 2017', 2017, 1, 1, 2024, 9, 11, null),
      ('Genna 2015', 2015, 4, 29, 2023, 1, 7, null),
      ('Genna 2016 (year of John)', 2016, 4, 28, 2024, 1, 7, null),
      ('Genna 2017', 2017, 4, 29, 2025, 1, 7, null),
      ('Timket 2016 (year of John)', 2016, 5, 11, 2024, 1, 20, null),
      ('Timket 2017', 2017, 5, 11, 2025, 1, 19, null),
    ];

    for (final (name, ey, em, ed, gy, gm, gd, weekday) in anchors) {
      test(name, () {
        final eth = EthiopianDate(ey, em, ed);
        final greg = GregorianDate(gy, gm, gd);
        expect(EthiopianCalendarEngine.toGregorian(eth), greg);
        expect(EthiopianCalendarEngine.toEthiopian(greg), eth);
        expect(
          EthiopianCalendarEngine.getDayOfWeek(eth),
          DateTime.utc(gy, gm, gd).weekday,
        );
        if (weekday != null) {
          expect(EthiopianCalendarEngine.getDayOfWeek(eth), weekday);
        }
      });
    }
  });

  group('2. Day-by-day odometer, 1 Jan 1900 - 31 Dec 2100', () {
    test('every day converts both ways and has the right weekday', () {
      // Anchor: Meskerem 1, 2000 = 12 September 2007.
      final anchor = DateTime.utc(2007, 9, 12);
      const _Eth anchorEth = (y: 2000, m: 1, d: 1);

      final failures = <String>[];
      var checked = 0;

      void check(DateTime g, _Eth e) {
        checked++;
        final greg = _g(g);
        final eth = EthiopianDate(e.y, e.m, e.d);
        if (EthiopianCalendarEngine.toEthiopian(greg) != eth) {
          failures.add('toEthiopian($greg) != $eth');
        }
        if (EthiopianCalendarEngine.toGregorian(eth) != greg) {
          failures.add('toGregorian($eth) != $greg');
        }
        if (EthiopianCalendarEngine.getDayOfWeek(eth) != g.weekday) {
          failures.add('weekday($eth) != ${g.weekday}');
        }
        if (EthiopianCalendarEngine.getDayOfWeekGregorian(greg) != g.weekday) {
          failures.add('weekdayGregorian($greg) != ${g.weekday}');
        }
      }

      // Forward to the end of 2100.
      var g = anchor;
      var e = anchorEth;
      final end = DateTime.utc(2100, 12, 31);
      while (!g.isAfter(end)) {
        check(g, e);
        g = g.add(const Duration(days: 1));
        e = _next(e);
      }

      // Backward to the start of 1900.
      g = anchor.subtract(const Duration(days: 1));
      e = _prev(anchorEth);
      final start = DateTime.utc(1900, 1, 1);
      while (!g.isBefore(start)) {
        check(g, e);
        g = g.subtract(const Duration(days: 1));
        e = _prev(e);
      }

      expect(checked, greaterThan(73000));
      expect(failures.take(10).toList(), isEmpty,
          reason: '${failures.length} mismatches in $checked days');
    });
  });

  group('3. Year boundaries, Pagume and leap years', () {
    test('Pagume has 6 days only in the year of Luke (year % 4 == 3)', () {
      for (var y = 1890; y <= 2100; y++) {
        expect(EthiopianDate.daysInMonthFor(y, 13), _isEthLeap(y) ? 6 : 5);
        if (_isEthLeap(y)) {
          expect(() => EthiopianDate(y, 13, 6), returnsNormally);
        } else {
          expect(() => EthiopianDate(y, 13, 6), throwsArgumentError);
        }
        expect(() => EthiopianDate(y, 13, 7), throwsArgumentError);
        expect(() => EthiopianDate(y, 12, 31), throwsArgumentError);
      }
    });

    test('a year is 365 days, or 366 in a leap year', () {
      for (var y = 1890; y <= 2100; y++) {
        final days = EthiopianCalendarEngine.daysBetween(
          EthiopianDate(y, 1, 1),
          EthiopianDate(y + 1, 1, 1),
        );
        expect(days, _isEthLeap(y) ? 366 : 365, reason: 'year $y');
      }
    });

    test('the day after the last day of Pagume is Meskerem 1', () {
      for (var y = 1890; y <= 2100; y++) {
        final last = EthiopianDate(y, 13, _isEthLeap(y) ? 6 : 5);
        expect(
          EthiopianDateConverter.addDays(last, 1),
          EthiopianDate(y + 1, 1, 1),
        );
        expect(
          EthiopianDateConverter.subtractDays(EthiopianDate(y + 1, 1, 1), 1),
          last,
        );
      }
    });

    test('New Year is 11 September, or 12 September after a leap year', () {
      // Holds for Gregorian 1901-2099, i.e. Ethiopian years 1894-2092.
      for (var y = 1894; y <= 2092; y++) {
        final expectedDay = _isEthLeap(y - 1) ? 12 : 11;
        expect(
          EthiopianCalendarEngine.toGregorian(EthiopianDate(y, 1, 1)),
          GregorianDate(y + 7, 9, expectedDay),
          reason: 'Meskerem 1, $y',
        );
      }
    });

    test('every month from Meskerem to Nehase has exactly 30 days', () {
      for (var m = 1; m <= 12; m++) {
        expect(EthiopianDate.daysInMonthFor(2017, m), 30);
        expect(
          EthiopianDateConverter.addDays(EthiopianDate(2017, m, 30), 1),
          EthiopianDate(2017, m + 1, 1),
        );
      }
    });
  });

  group('4. Bahire Hasab against the independent Julian computus', () {
    test('Fasika matches published Orthodox Easter dates', () {
      const published = <int, (int, int, int)>{
        2012: (2020, 4, 19),
        2013: (2021, 5, 2),
        2014: (2022, 4, 24),
        2015: (2023, 4, 16),
        2016: (2024, 5, 5),
        2017: (2025, 4, 20),
        2018: (2026, 4, 12),
        2019: (2027, 5, 2),
        2020: (2028, 4, 16),
      };
      published.forEach((ethYear, greg) {
        expect(
          EthiopianCalendarEngine.toGregorian(BahireHasab.fasika(ethYear)),
          GregorianDate(greg.$1, greg.$2, greg.$3),
          reason: 'Fasika $ethYear',
        );
      });
    });

    test('Fasika equals Julian-computus Easter for Ethiopian 1894-2091', () {
      for (var y = 1894; y <= 2091; y++) {
        final expected = _orthodoxEaster(y + 8);
        expect(
          EthiopianCalendarEngine.toGregorian(BahireHasab.fasika(y)),
          _g(expected),
          reason: 'Fasika $y',
        );
      }
    });

    test('movable feasts keep their weekdays and distances from Fasika', () {
      for (var y = 1894; y <= 2091; y++) {
        final fasika = BahireHasab.fasika(y);
        int dow(EthiopianDate d) => EthiopianCalendarEngine.getDayOfWeek(d);
        int fromFasika(EthiopianDate d) =>
            EthiopianCalendarEngine.daysBetween(fasika, d);

        expect(dow(fasika), DateTime.sunday, reason: 'Fasika $y');
        expect(dow(BahireHasab.nenewe(y)), DateTime.monday);
        expect(dow(BahireHasab.abiyTsom(y)), DateTime.monday);
        expect(dow(BahireHasab.debreZeit(y)), DateTime.sunday);
        expect(dow(BahireHasab.hosanna(y)), DateTime.sunday);
        expect(dow(BahireHasab.siklet(y)), DateTime.friday);
        expect(dow(BahireHasab.rikbeKahnat(y)), DateTime.wednesday);
        expect(dow(BahireHasab.erget(y)), DateTime.thursday);
        expect(dow(BahireHasab.paraclete(y)), DateTime.sunday);
        expect(dow(BahireHasab.tsomeHawaryat(y)), DateTime.monday);
        expect(dow(BahireHasab.tsomeDihnet(y)), DateTime.wednesday);

        expect(fromFasika(BahireHasab.nenewe(y)), -69);
        expect(fromFasika(BahireHasab.abiyTsom(y)), -55);
        expect(fromFasika(BahireHasab.debreZeit(y)), -28);
        expect(fromFasika(BahireHasab.hosanna(y)), -7);
        expect(fromFasika(BahireHasab.siklet(y)), -2);
        expect(fromFasika(BahireHasab.rikbeKahnat(y)), 24);
        expect(fromFasika(BahireHasab.erget(y)), 39);
        expect(fromFasika(BahireHasab.paraclete(y)), 49);
      }
    });

    test('computus terms stay within their defined ranges', () {
      for (var y = 1894; y <= 2091; y++) {
        expect(BahireHasab.wenber(y), inInclusiveRange(0, 18));
        expect(BahireHasab.abeqte(y), inInclusiveRange(0, 29));
        expect(BahireHasab.metqi(y), inInclusiveRange(1, 30));
        // Abeqte and Metqi always sum to 30 (a Metqi of 30 pairs with 0).
        expect((BahireHasab.abeqte(y) + BahireHasab.metqi(y)) % 30, 0);
        expect(BahireHasab.medeb(y), (y + 5500) % 19);
      }
    });
  });

  group('5. Genna, Timket and their fasting status', () {
    test('Genna is Tahsas 28 only in the year after a leap year', () {
      expect(HolidayEngine.gennaDay(2015), 29); // Luke, the leap year itself
      expect(HolidayEngine.gennaDay(2016), 28); // John, the year after
      expect(HolidayEngine.gennaDay(2017), 29); // Matthew
      expect(HolidayEngine.gennaDay(2018), 29); // Mark
      expect(HolidayEngine.gennaDay(2019), 29); // Luke
      expect(HolidayEngine.gennaDay(2020), 28); // John
    });

    test('Genna falls on 7 January for Gregorian 1902-2099', () {
      for (var y = 1894; y <= 2091; y++) {
        final genna = HolidayEngine.getHolidaysForYear(y)
            .firstWhere((h) => h.id.startsWith('genna'));
        expect(
          EthiopianCalendarEngine.toGregorian(genna.ethiopianDate),
          GregorianDate(y + 8, 1, 7),
          reason: 'Genna $y',
        );
      }
    });

    test('Timket (Tir 11) is 19 January, or 20 January in the year of John',
        () {
      for (var y = 1894; y <= 2091; y++) {
        expect(
          EthiopianCalendarEngine.toGregorian(EthiopianDate(y, 5, 11)),
          GregorianDate(y + 8, 1, y % 4 == 0 ? 20 : 19),
          reason: 'Timket $y',
        );
      }
    });

    test('Genna and Timket are never fast days, whatever the weekday', () {
      final weekdaysSeen = <int>{};
      for (var y = 2000; y <= 2040; y++) {
        final genna = EthiopianDate(y, 4, HolidayEngine.gennaDay(y));
        final timket = EthiopianDate(y, 5, 11);
        weekdaysSeen.add(EthiopianCalendarEngine.getDayOfWeek(genna));
        expect(HolidayEngine.isFastingDay(genna).isFasting, isFalse,
            reason: 'Genna $y');
        expect(HolidayEngine.isFastingDay(timket).isFasting, isFalse,
            reason: 'Timket $y');
      }
      // The sample really does include Wednesdays and Fridays.
      expect(weekdaysSeen, containsAll([DateTime.wednesday, DateTime.friday]));
    });

    test('the eve of Genna is still inside the Fast of the Prophets', () {
      for (var y = 2010; y <= 2030; y++) {
        final eve = EthiopianDate(y, 4, HolidayEngine.gennaDay(y) - 1);
        expect(HolidayEngine.isFastingDay(eve).isFasting, isTrue,
            reason: 'eve of Genna $y');
      }
    });
  });
}
