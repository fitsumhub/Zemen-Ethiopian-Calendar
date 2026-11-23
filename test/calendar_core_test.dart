import 'package:flutter_test/flutter_test.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/gregorian_date.dart';
import 'package:ethiocal/core/calendar/ethiopian_month.dart';
import 'package:ethiocal/core/calendar/leap_year_calculator.dart';
import 'package:ethiocal/core/calendar/ethiopian_date_converter.dart';
import 'package:ethiocal/core/calendar/bahire_hasab.dart';
import 'package:ethiocal/core/calendar/geez_numeral.dart';
import 'package:ethiocal/core/calendar/ethiopian_time_converter.dart';

void main() {
  group('1. MONTH DEFINITIONS TEST', () {
    test('testAllThirteenMonthsDefinitions', () {
      final months = EthiopianMonth.values;
      expect(months.length, 13);

      expect(EthiopianMonth.meskerem.amharicName, 'መስከረም');
      expect(EthiopianMonth.meskerem.englishName, 'Meskerem');
      expect(EthiopianMonth.meskerem.number, 1);
      expect(EthiopianMonth.meskerem.daysInMonth(false), 30);
      expect(EthiopianMonth.meskerem.daysInMonth(true), 30);

      expect(EthiopianMonth.pagume.amharicName, 'ጳጉሜ');
      expect(EthiopianMonth.pagume.englishName, 'Pagume');
      expect(EthiopianMonth.pagume.number, 13);
      expect(EthiopianMonth.pagume.daysInMonth(false), 5);
      expect(EthiopianMonth.pagume.daysInMonth(true), 6);

      for (int m = 1; m <= 12; m++) {
        final month = EthiopianMonth.fromNumber(m);
        expect(month.daysInMonth(false), 30);
        expect(month.daysInMonth(true), 30);
      }
    });
  });

  group('2. LEAP YEAR CALCULATIONS TEST', () {
    test('testEthiopianLeapYearCycle', () {
      // Ethiopian leap years have year % 4 == 3 (Luke year)
      expect(LeapYearCalculator.isEthiopianLeapYear(1999), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2003), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2007), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2011), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2015), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2019), isTrue);
      expect(LeapYearCalculator.isEthiopianLeapYear(2023), isTrue);

      // Non-leap years
      expect(LeapYearCalculator.isEthiopianLeapYear(2016), isFalse);
      expect(LeapYearCalculator.isEthiopianLeapYear(2017), isFalse);
      expect(LeapYearCalculator.isEthiopianLeapYear(2018), isFalse);

      // Evangelist verification
      expect(LeapYearCalculator.getEvangelist(2015), Evangelist.luke);
      expect(LeapYearCalculator.getEvangelist(2015).isLeapYear, isTrue);
      expect(LeapYearCalculator.getEvangelist(2016), Evangelist.john);
      expect(LeapYearCalculator.getEvangelist(2017), Evangelist.matthew);
      expect(LeapYearCalculator.getEvangelist(2018), Evangelist.mark);
      expect(LeapYearCalculator.getEvangelist(2019), Evangelist.luke);

      // Year days
      expect(LeapYearCalculator.getEthiopianYearDays(2015), 366);
      expect(LeapYearCalculator.getEthiopianYearDays(2016), 365);
      expect(LeapYearCalculator.getEthiopianYearDays(2017), 365);
    });
  });

  group('3. DATE CONVERSION ALGORITHMS TEST', () {
    test('testKnownCanonicalDateConversions', () {
      // Enkutatash 2017 E.C. -> Sept 11, 2024 G.C.
      final enk2017 = EthiopianDate(2017, 1, 1);
      final gregEnk2017 = EthiopianDateConverter.toGregorian(enk2017);
      expect(gregEnk2017, GregorianDate(2024, 9, 11));

      // Round-trip back to Ethiopian
      final roundTrip2017 = EthiopianDateConverter.toEthiopian(gregEnk2017);
      expect(roundTrip2017, enk2017);

      // Pagume 6 in 2015 leap year -> Sept 11, 2023 G.C.
      final pagume6 = EthiopianDate(2015, 13, 6);
      final gregPagume6 = EthiopianDateConverter.toGregorian(pagume6);
      expect(gregPagume6, GregorianDate(2023, 9, 11));
      expect(EthiopianDateConverter.toEthiopian(gregPagume6), pagume6);

      // Meskerem 1 after Pagume 6 -> Sept 12, 2023 G.C.
      final enk2016 = EthiopianDate(2016, 1, 1);
      final gregEnk2016 = EthiopianDateConverter.toGregorian(enk2016);
      expect(gregEnk2016, GregorianDate(2023, 9, 12));
      expect(EthiopianDateConverter.toEthiopian(gregEnk2016), enk2016);

      // Genna 2016 E.C. (Tahsas 29) -> Jan 8, 2024 G.C. (following 2015 leap year)
      final genna2016 = EthiopianDate(2016, 4, 29);
      final gregGenna = EthiopianDateConverter.toGregorian(genna2016);
      expect(gregGenna, GregorianDate(2024, 1, 8));
      expect(EthiopianDateConverter.toEthiopian(gregGenna), genna2016);
    });

    test('testContinuousRoundTripConversionsAcross100Years', () {
      for (int year = 2010; year <= 2040; year++) {
        final maxPagume = LeapYearCalculator.isEthiopianLeapYear(year) ? 6 : 5;
        for (int month = 1; month <= 13; month++) {
          final sampleDays = month == 13
              ? List.generate(maxPagume, (i) => i + 1)
              : [1, 15, 30];
          for (final day in sampleDays) {
            final original = EthiopianDate(year, month, day);
            final gregorian = EthiopianDateConverter.toGregorian(original);
            final reconstructed = EthiopianDateConverter.toEthiopian(gregorian);
            expect(reconstructed, original, reason: 'Round-trip failed for $original');
          }
        }
      }
    });
  });

  group('4. GE\'EZ NUMERAL SUPPORT TEST', () {
    test('testGeezNumeralEncodingAndDecoding', () {
      final testPairs = <int, String>{
        1: '፩',
        2: '፪',
        5: '፭',
        9: '፱',
        10: '፲',
        11: '፲፩',
        20: '፳',
        25: '፳፭',
        30: '፴',
        100: '፻',
        200: '፪፻',
        2017: '፳፻፲፯',
      };

      for (final entry in testPairs.entries) {
        expect(GeezNumeral.toGeez(entry.key), entry.value,
            reason: 'toGeez failed for ${entry.key}');
        expect(GeezNumeral.isGeez(entry.value), isTrue,
            reason: 'isGeez failed for ${entry.value}');
        expect(GeezNumeral.fromGeez(entry.value), entry.key,
            reason: 'fromGeez failed for ${entry.value}');
      }

      expect(GeezNumeral.isGeez('123'), isFalse);
      expect(GeezNumeral.isGeez('ABC'), isFalse);
    });
  });

  group('5. BAHIRE HASAB COMPUTUS TEST', () {
    test('testBahireHasabCalculation', () {
      final result2017 = BahireHasab.calculate(2017);
      expect(result2017.ethiopianYear, 2017);
      expect(result2017.ameteAlem, 7517);
      expect(result2017.evangelist, Evangelist.matthew);
      expect(result2017.movableFeasts.isNotEmpty, isTrue);

      final result2018 = BahireHasab.calculate(2018);
      expect(result2018.ethiopianYear, 2018);
      expect(result2018.evangelist, Evangelist.mark);
    });
  });

  group('6. ETHIOPIAN TIMEKEEPING TEST', () {
    test('testEthiopianTimeConverter', () {
      // 6:00 AM Gregorian -> 12:00 morning Ethiopian (ቀን)
      final t6am = EthiopianTimeConverter.gregorianToEthiopian(6, 0);
      expect(t6am.hour, 12);
      expect(t6am.isDaytime, isTrue);

      // 12:00 PM Gregorian -> 6:00 midday Ethiopian (ቀን)
      final t12pm = EthiopianTimeConverter.gregorianToEthiopian(12, 0);
      expect(t12pm.hour, 6);
      expect(t12pm.isDaytime, isTrue);

      // 6:00 PM Gregorian -> 12:00 evening Ethiopian (ሌሊት)
      final t6pm = EthiopianTimeConverter.gregorianToEthiopian(18, 0);
      expect(t6pm.hour, 12);
      expect(t6pm.isDaytime, isFalse);

      // Round-trip back to Gregorian
      final gTimeBack = EthiopianTimeConverter.ethiopianToGregorian(6, 0, isDaytime: true);
      expect(gTimeBack.hour24, 12);
      expect(gTimeBack.minute, 0);
    });
  });
}
