import 'package:flutter_test/flutter_test.dart';
import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/calendar/gregorian_date.dart';
import 'package:ethiocal/core/heritage/daily_heritage_engine.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:ethiocal/core/world/world_country_engine.dart';

void main() {
  group('DailyHeritageEngine Tests', () {
    test('testDailyProverbsDefinitions', () {
      expect(DailyHeritageEngine.proverbsByDay.length, 30);
      expect(DailyHeritageEngine.pagumeProverbs.length, 6);

      // Verify Day 1
      final d1 = DailyHeritageEngine.proverbsByDay[0];
      expect(d1.amharic, 'ድር ቢያብር አንበሳ ያስር።');
      expect(d1.englishTranslation.contains('spider webs'), isTrue);

      // Verify Pagume Day 6
      final p6 = DailyHeritageEngine.pagumeProverbs[5];
      expect(p6.amharic.contains('ዘመነ ሉቃስ'), isTrue);
    });

    test('testGetHeritageForDate', () {
      final date = EthiopianDate(2017, 1, 1);
      final heritage = DailyHeritageEngine.getHeritageForDate(date);
      expect(heritage.date, date);
      expect(heritage.saint?.day, 1);
      expect(heritage.proverb.amharic, 'ድር ቢያብር አንበሳ ያስር።');
      expect(heritage.evangelist, 'ዘመነ ማቴዎስ');
      expect(heritage.solarPhase.contains('መከር'), isTrue);
    });
  });

  group('HolidayEngine Tests', () {
    test('testHolidaysForYear2017', () {
      final holidays = HolidayEngine.getHolidaysForYear(2017);
      expect(holidays.isNotEmpty, isTrue);

      final enkutatash = holidays.firstWhere((h) => h.id.startsWith('enkutatash'));
      expect(enkutatash.ethiopianDate, EthiopianDate(2017, 1, 1));
      expect(enkutatash.isPublicHoliday, isTrue);

      final meskel = holidays.firstWhere((h) => h.id.startsWith('meskel'));
      expect(meskel.ethiopianDate, EthiopianDate(2017, 1, 17));
      expect(meskel.isPublicHoliday, isTrue);

      final genna = holidays.firstWhere((h) => h.id.startsWith('genna'));
      // 2017 is not leap year, so Genna is Tahsas 29
      expect(genna.ethiopianDate, EthiopianDate(2017, 4, 29));

      final timket = holidays.firstWhere((h) => h.id.startsWith('timket'));
      expect(timket.ethiopianDate, EthiopianDate(2017, 5, 11));

      final adwa = holidays.firstWhere((h) => h.id.startsWith('adwa'));
      expect(adwa.ethiopianDate, EthiopianDate(2017, 6, 23));
    });

    test('testGennaLeapYearDate', () {
      // Corrected from the Kotlin original, which expected Tahsas 28 in the
      // leap year itself. Genna moves to Tahsas 28 only in the year AFTER a
      // leap year (ዘመነ ዮሐንስ); both cases fall on 7 January Gregorian.
      Holiday gennaOf(int year) => HolidayEngine.getHolidaysForYear(year)
          .firstWhere((h) => h.id.startsWith('genna'));

      // 2015 E.C. is the leap year (Luke): Genna stays on Tahsas 29 = 7 Jan 2023.
      expect(gennaOf(2015).ethiopianDate, EthiopianDate(2015, 4, 29));
      // 2016 E.C. follows it (John): Genna is Tahsas 28 = 7 Jan 2024.
      expect(gennaOf(2016).ethiopianDate, EthiopianDate(2016, 4, 28));
    });

    test('testFastingRulesAndCanonicalFasts', () {
      final fasts = HolidayEngine.getCanonicalFastsForYear(2017);
      expect(fasts.length, 7);

      final greatLent = fasts.firstWhere((f) => f.id.startsWith('fast_great_lent'));
      expect(greatLent.durationDays, 55);

      final nineveh = fasts.firstWhere((f) => f.id.startsWith('fast_nineveh'));
      expect(nineveh.durationDays, 3);
    });
  });

  group('WorldCountryEngine Tests', () {
    test('testConvertAddisAbabaTimeToWorldCities', () {
      final results = WorldCountryEngine.convertAddisAbabaTimeToWorldCities(12, 0);
      expect(results.isNotEmpty, isTrue);

      // Addis 12:00 (UTC+3) -> London (UTC+0) = 9:00 AM
      final london = results.firstWhere((r) => r.city.id == 'lon');
      expect(london.hour24, 9);
      expect(london.minute, 0);

      // Addis 12:00 (UTC+3) -> New York (UTC-5) = 4:00 AM
      final nyc = results.firstWhere((r) => r.city.id == 'nyc');
      expect(nyc.hour24, 4);
      expect(nyc.minute, 0);

      // Addis 12:00 (UTC+3) -> Tokyo (UTC+9) = 18:00 (6:00 PM)
      final tokyo = results.firstWhere((r) => r.city.id == 'tyo');
      expect(tokyo.hour24, 18);
      expect(tokyo.minute, 0);
    });

    test('testEuropeanCalendarDetails', () {
      final eth = EthiopianDate(2017, 1, 1);
      final greg = GregorianDate(2024, 9, 11);
      final jdn = EthiopianCalendarEngine.ethiopianToJdn(eth);

      final details = WorldCountryEngine.computeEuropeanAndWorldCalendarDetails(eth, greg, jdn);
      expect(details.iso8601, '2024-09-11');
      expect(details.gregorianFormattedEu, '11.09.2024');
      expect(details.yearOffsetExplanation.contains('7 years ahead'), isTrue);
      expect(details.copticYear, 1741);
    });
  });

  group('Date Difference Tests', () {
    test('testCalculateDifference', () {
      final from = EthiopianDate(2017, 1, 1);
      final to = EthiopianDate(2017, 1, 15);
      final diff = EthiopianCalendarEngine.calculateDifference(from, to);
      expect(diff.totalDays, 14);
      expect(diff.totalWeeks, 2);
      expect(diff.remainingDays, 0);
    });
  });
}
