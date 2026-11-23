import 'package:flutter_test/flutter_test.dart';

import 'package:ethiocal/core/calendar/bahire_hasab.dart';
import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/ethiopian_time_converter.dart';
import 'package:ethiocal/core/calendar/geez_numeral.dart';
import 'package:ethiocal/core/calendar/gregorian_date.dart';
import 'package:ethiocal/core/localization/locale_strings.dart';
import 'package:ethiocal/core/world/world_country_engine.dart';

/// Converter-section calculation verification — mirrors what the UI tabs compute.
void main() {
  group('Date Convert — known Eth ↔ Greg pairs', () {
    final cases = <(EthiopianDate, GregorianDate, String)>[
      // New Year / Enkutatash
      (EthiopianDate(2017, 1, 1), GregorianDate(2024, 9, 11), 'Enkutatash 2017'),
      (EthiopianDate(2016, 1, 1), GregorianDate(2023, 9, 12), 'Enkutatash after leap'),
      // Genna / Timket
      (EthiopianDate(2017, 4, 29), GregorianDate(2025, 1, 7), 'Genna 2017'),
      (EthiopianDate(2016, 4, 28), GregorianDate(2024, 1, 7), 'Genna after leap'),
      (EthiopianDate(2017, 5, 11), GregorianDate(2025, 1, 19), 'Timket 2017'),
      // Today's screenshot pair (Hidar 6 2019 ↔ 15 Nov 2026)
      (EthiopianDate(2019, 3, 6), GregorianDate(2026, 11, 15), 'Hidar 6 2019'),
      // Pagume edge
      (EthiopianDate(2015, 13, 6), GregorianDate(2023, 9, 11), 'Pagume 6 leap'),
      (EthiopianDate(2016, 13, 5), GregorianDate(2024, 9, 10), 'Pagume 5 non-leap'),
      // Adwa
      (EthiopianDate(2017, 6, 23), GregorianDate(2025, 3, 2), 'Adwa 2017'),
    ];

    for (final c in cases) {
      test('${c.$3}: Eth→Greg and Greg→Eth round-trip', () {
        final eth = c.$1;
        final greg = c.$2;
        expect(EthiopianCalendarEngine.toGregorian(eth), greg);
        expect(EthiopianCalendarEngine.toEthiopian(greg), eth);
      });
    }

    test('RESULT weekday for Hidar 6 2019 is Sunday (converter RESULT card)', () {
      final eth = EthiopianDate(2019, 3, 6);
      final dow = EthiopianCalendarEngine.getDayOfWeek(eth);
      expect(dow, 7); // 7 = Sunday
      expect(LocaleStrings.weekdaysEnglishLong[dow - 1], 'Sunday');
      final g = EthiopianCalendarEngine.toGregorian(eth);
      expect(g, GregorianDate(2026, 11, 15));
      // Dart DateTime weekday: 7 = Sunday
      expect(DateTime(g.year, g.month, g.day).weekday, DateTime.sunday);
    });
  });

  group('Age / Date Math calculations', () {
    test('same-month span: Meskerem 1 → 15 = 14 days / 2 weeks', () {
      final diff = EthiopianCalendarEngine.calculateDifference(
        EthiopianDate(2017, 1, 1),
        EthiopianDate(2017, 1, 15),
      );
      expect(diff.totalDays, 14);
      expect(diff.totalWeeks, 2);
      expect(diff.remainingDays, 0);
      expect(diff.ethiopianYears, 0);
      expect(diff.ethiopianMonths, 0);
      expect(diff.ethiopianDays, 14);
    });

    test('exact one Ethiopian year: Meskerem 1 2016 → Meskerem 1 2017', () {
      final diff = EthiopianCalendarEngine.calculateDifference(
        EthiopianDate(2016, 1, 1),
        EthiopianDate(2017, 1, 1),
      );
      expect(diff.ethiopianYears, 1);
      expect(diff.ethiopianMonths, 0);
      expect(diff.ethiopianDays, 0);
      expect(diff.totalDays, 365); // 2016 is not leap (John)
    });

    test('Ethiopian year uses 13 months when wrapping Pagume → Meskerem', () {
      final diff = EthiopianCalendarEngine.calculateDifference(
        EthiopianDate(2016, 13, 1),
        EthiopianDate(2017, 1, 1),
      );
      expect(diff.ethiopianYears, 0);
      expect(diff.ethiopianMonths, 1);
      expect(diff.ethiopianDays, 0);
      expect(diff.totalDays, 5); // Pagume 2016 has 5 days
    });

    test('borrow days across Pagume uses 5/6 day length not always 30', () {
      // Leap year 2015: Pagume has 6 days. From Pagume 4 to Meskerem 3 next year.
      final diff = EthiopianCalendarEngine.calculateDifference(
        EthiopianDate(2015, 13, 4),
        EthiopianDate(2016, 1, 3),
      );
      expect(diff.totalDays, 5); // 5,6 + 1,2,3
      expect(diff.ethiopianYears, 0);
      expect(diff.ethiopianMonths, 0);
      expect(diff.ethiopianDays, 5);
    });

    test('order-independent totalDays is absolute', () {
      final a = EthiopianDate(2017, 1, 1);
      final b = EthiopianDate(2017, 2, 1);
      final forward = EthiopianCalendarEngine.calculateDifference(a, b);
      final backward = EthiopianCalendarEngine.calculateDifference(b, a);
      expect(forward.totalDays, backward.totalDays);
      expect(forward.totalDays, 30);
    });

    test('WorldCountryEngine age alias matches engine', () {
      final birth = EthiopianDate(2010, 1, 1);
      final today = EthiopianDate(2017, 1, 1);
      final viaWorld = WorldCountryEngine.calculateDifference(birth, today);
      final viaEngine = EthiopianCalendarEngine.calculateDifference(birth, today);
      expect(viaWorld.ethiopianYears, viaEngine.ethiopianYears);
      expect(viaWorld.totalDays, viaEngine.totalDays);
      expect(viaWorld.ethiopianYears, 7);
    });
  });

  group('Time converter calculations', () {
    test('Gregorian → Ethiopian key hours', () {
      expect(EthiopianTimeConverter.gregorianToEthiopian(6, 0).hour, 12);
      expect(EthiopianTimeConverter.gregorianToEthiopian(6, 0).isDaytime, isTrue);
      expect(EthiopianTimeConverter.gregorianToEthiopian(12, 0).hour, 6);
      expect(EthiopianTimeConverter.gregorianToEthiopian(12, 0).period, TimePeriod.midday);
      expect(EthiopianTimeConverter.gregorianToEthiopian(18, 0).hour, 12);
      expect(EthiopianTimeConverter.gregorianToEthiopian(18, 0).isDaytime, isFalse);
      expect(EthiopianTimeConverter.gregorianToEthiopian(0, 0).hour, 6);
      expect(EthiopianTimeConverter.gregorianToEthiopian(0, 0).period, TimePeriod.midnight);
    });

    test('Ethiopian → Gregorian round-trip for daytime/night', () {
      final day = EthiopianTimeConverter.ethiopianToGregorian(6, 30, isDaytime: true);
      expect(day.hour24, 12);
      expect(day.minute, 30);
      final night = EthiopianTimeConverter.ethiopianToGregorian(6, 0, isDaytime: false);
      expect(night.hour24, 0);
    });

    test('World cities offsets from Addis 12:00', () {
      final results = WorldCountryEngine.convertTime(12, 0);
      expect(results.firstWhere((r) => r.city.id == 'lon').hour24, 9);
      expect(results.firstWhere((r) => r.city.id == 'nyc').hour24, 4);
      expect(results.firstWhere((r) => r.city.id == 'tyo').hour24, 18);
    });
  });

  group('Ge\'ez numerals (converter Ge\'ez tab)', () {
    test('common converter values encode/decode', () {
      final samples = {
        1: '፩',
        10: '፲',
        15: '፲፭',
        2017: '፳፻፲፯',
        2019: '፳፻፲፱',
      };
      for (final e in samples.entries) {
        expect(GeezNumeral.toGeez(e.key), e.value);
        expect(GeezNumeral.fromGeez(e.value), e.key);
      }
    });
  });

  group('Bahire Hasab (Computus tab)', () {
    test('Fasika 2017 is Miyazia 12 / Easter Sunday', () {
      final fasika = BahireHasab.fasika(2017);
      expect(fasika, EthiopianDate(2017, 8, 12));
      expect(EthiopianCalendarEngine.getDayOfWeek(fasika), 7); // Sunday
      expect(
        EthiopianCalendarEngine.toGregorian(fasika),
        GregorianDate(2025, 4, 20),
      );
    });

    test('movable feast distances from Fasika stay fixed', () {
      final y = 2017;
      final fasikaJdn = EthiopianCalendarEngine.ethiopianToJdn(BahireHasab.fasika(y));
      int fromFasika(EthiopianDate d) =>
          EthiopianCalendarEngine.ethiopianToJdn(d) - fasikaJdn;
      expect(fromFasika(BahireHasab.nenewe(y)), -69);
      expect(fromFasika(BahireHasab.abiyTsom(y)), -55);
      expect(fromFasika(BahireHasab.siklet(y)), -2);
      expect(fromFasika(BahireHasab.erget(y)), 39);
      expect(fromFasika(BahireHasab.paraclete(y)), 49);
    });
  });

  group('Pagume day bounds used by converter wheels', () {
    test('leap Luke year Pagume has 6 days; others 5', () {
      expect(EthiopianDate.daysInMonthFor(2015, 13), 6); // Luke leap
      expect(EthiopianDate.daysInMonthFor(2016, 13), 5);
      expect(EthiopianDate.daysInMonthFor(2017, 13), 5);
      expect(EthiopianDate.daysInMonthFor(2018, 13), 5);
      expect(EthiopianDate.daysInMonthFor(2019, 13), 6);
    });

    test('invalid Pagume day 30 must clamp before conversion', () {
      final max = EthiopianDate.daysInMonthFor(2017, 13);
      final clampedDay = 30 > max ? max : 30;
      expect(clampedDay, 5);
      final g = EthiopianCalendarEngine.toGregorian(
        EthiopianDate(2017, 13, clampedDay),
      );
      expect(g, isA<GregorianDate>());
    });
  });
}
