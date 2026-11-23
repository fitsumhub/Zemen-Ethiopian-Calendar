import 'package:ethiocal/core/calendar/ethiopian_calendar_engine.dart';
import 'package:ethiocal/core/calendar/ethiopian_date.dart';
import 'package:ethiocal/core/holidays/holiday_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('single year includes new orthodox feasts', () {
    final list = HolidayEngine.getHolidaysForYear(2018);
    expect(list.any((h) => h.id.startsWith('hidar_tsion_')), isTrue);
    expect(list.any((h) => h.id.startsWith('kulubi_gabriel_')), isTrue);
    expect(list.any((h) => h.id.startsWith('buhe_')), isTrue);
    expect(list.any((h) => h.id.startsWith('filseta_feast_')), isTrue);
    expect(list.length, greaterThan(25));
  });

  test('year range spans inclusive years', () {
    final list = HolidayEngine.getHolidaysForYearRange(2018, 2020);
    final years = list.map((h) => h.ethiopianDate.year).toSet();
    expect(years.contains(2018), isTrue);
    expect(years.contains(2019), isTrue);
    expect(years.contains(2020), isTrue);
    expect(list.length, greaterThan(80));
  });

  test('upcoming horizon covers next 20 years', () {
    final today = EthiopianCalendarEngine.todayEthiopian();
    final list = HolidayEngine.getUpcomingHolidays(
      fromDate: today,
      yearsAhead: 20,
    );
    expect(list, isNotEmpty);
    expect(list.first.ethiopianDate >= today, isTrue);
    final maxYear = list.map((h) => h.ethiopianDate.year).reduce(
          (a, b) => a > b ? a : b,
        );
    expect(maxYear, greaterThanOrEqualTo(today.year + 19));
  });

  test('upcoming public-only filter', () {
    final list = HolidayEngine.getUpcomingHolidays(
      fromDate: EthiopianDate(2018, 1, 1),
      yearsAhead: 5,
      publicOnly: true,
    );
    expect(list.every((h) => h.isPublicHoliday), isTrue);
  });
}
