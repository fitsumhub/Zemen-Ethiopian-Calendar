import 'ethiopian_date.dart';
import 'ethiopian_date_converter.dart';
import 'gregorian_date.dart';

class DateDifference {
  final int totalDays;
  final int totalWeeks;
  final int remainingDays;
  final int ethiopianYears;
  final int ethiopianMonths;
  final int ethiopianDays;
  final int gregorianYears;
  final int gregorianMonths;
  final int gregorianDays;

  const DateDifference({
    required this.totalDays,
    required this.totalWeeks,
    required this.remainingDays,
    required this.ethiopianYears,
    required this.ethiopianMonths,
    required this.ethiopianDays,
    required this.gregorianYears,
    required this.gregorianMonths,
    required this.gregorianDays,
  });
}

/// High precision Ethiopian <-> Gregorian calendar conversion engine.
class EthiopianCalendarEngine {
  static const int ethiopianEpochJdn = EthiopianDateConverter.ethiopianEpochJdn;

  static int ethiopianToJdn(EthiopianDate date) {
    return EthiopianDateConverter.ethiopianDateToJulianDay(date);
  }

  static int ethiopianToJdnYMD(int year, int month, int day) {
    return EthiopianDateConverter.ethiopianToJulianDay(year, month, day);
  }

  static EthiopianDate jdnToEthiopian(int jdn) {
    return EthiopianDateConverter.julianDayToEthiopian(jdn);
  }

  static int gregorianToJdn(GregorianDate date) {
    return EthiopianDateConverter.gregorianDateToJulianDay(date);
  }

  static int gregorianToJdnYMD(int year, int month, int day) {
    return EthiopianDateConverter.gregorianToJulianDay(year, month, day);
  }

  static GregorianDate jdnToGregorian(int jdn) {
    return EthiopianDateConverter.julianDayToGregorian(jdn);
  }

  static GregorianDate toGregorian(EthiopianDate ethiopianDate) {
    return EthiopianDateConverter.toGregorian(ethiopianDate);
  }

  static EthiopianDate toEthiopian(GregorianDate gregorianDate) {
    return EthiopianDateConverter.toEthiopian(gregorianDate);
  }

  static EthiopianDate todayEthiopian() {
    final now = DateTime.now();
    final gDate = GregorianDate(now.year, now.month, now.day);
    return toEthiopian(gDate);
  }

  static GregorianDate todayGregorian() {
    final now = DateTime.now();
    return GregorianDate(now.year, now.month, now.day);
  }

  /// Returns the day of the week for an Ethiopian date:
  /// 1 = Monday (ሰኞ), 2 = Tuesday (ማክሰኞ), ..., 6 = Saturday (ቅዳሜ), 7 = Sunday (እሑድ).
  static int getDayOfWeek(EthiopianDate ethiopianDate) {
    return EthiopianDateConverter.getDayOfWeek(ethiopianDate);
  }

  /// Returns the day of the week for a Gregorian date (1 = Monday .. 7 = Sunday).
  static int getDayOfWeekGregorian(GregorianDate gregorianDate) {
    final jdn = gregorianToJdn(gregorianDate);
    final dow0 = (jdn % 7);
    return dow0 + 1;
  }

  static int daysBetween(EthiopianDate from, EthiopianDate to) {
    return ethiopianToJdn(to) - ethiopianToJdn(from);
  }

  static int daysBetweenGregorian(GregorianDate from, GregorianDate to) {
    return gregorianToJdn(to) - gregorianToJdn(from);
  }

  /// Returns the Ethiopian evangelist of the year:
  /// 1 = Matthew (ማቴዎስ)
  /// 2 = Mark (ማርቆስ)
  /// 3 = Luke (ሉቃስ - Leap Year!)
  /// 0 = John (ዮሐንስ)
  static int getEvangelist(int year) {
    final ameteAlem = year + 5500;
    return ameteAlem % 4;
  }

  static DateDifference calculateDifference(EthiopianDate from, EthiopianDate to) {
    final diffDays = daysBetween(from, to);
    final absDays = diffDays.abs();
    final weeks = absDays ~/ 7;
    final remDays = absDays % 7;

    final earlier = from <= to ? from : to;
    final later = from <= to ? to : from;

    var eYears = later.year - earlier.year;
    var eMonths = later.month - earlier.month;
    var eDays = later.day - earlier.day;

    if (eDays < 0) {
      eMonths -= 1;
      // Borrow from the previous Ethiopian month of [later] (Pagume is 5/6 days).
      final prevMonth = later.month == 1 ? 13 : later.month - 1;
      final prevYear = later.month == 1 ? later.year - 1 : later.year;
      eDays += EthiopianDate.daysInMonthFor(prevYear, prevMonth);
    }
    if (eMonths < 0) {
      eYears -= 1;
      // Ethiopian years have 13 months (Meskerem … Pagume).
      eMonths += 13;
    }

    final gFrom = toGregorian(earlier);
    final gTo = toGregorian(later);
    var gYears = gTo.year - gFrom.year;
    var gMonths = gTo.month - gFrom.month;
    var gDays = gTo.day - gFrom.day;

    if (gDays < 0) {
      gMonths -= 1;
      final prevMonth = gTo.month == 1 ? 12 : gTo.month - 1;
      final prevYear = gTo.month == 1 ? gTo.year - 1 : gTo.year;
      gDays += GregorianDate.daysInMonthFor(prevYear, prevMonth);
    }
    if (gMonths < 0) {
      gYears -= 1;
      gMonths += 12;
    }

    return DateDifference(
      totalDays: absDays,
      totalWeeks: weeks,
      remainingDays: remDays,
      ethiopianYears: eYears < 0 ? 0 : eYears,
      ethiopianMonths: eMonths < 0 ? 0 : eMonths,
      ethiopianDays: eDays < 0 ? 0 : eDays,
      gregorianYears: gYears < 0 ? 0 : gYears,
      gregorianMonths: gMonths < 0 ? 0 : gMonths,
      gregorianDays: gDays < 0 ? 0 : gDays,
    );
  }
}

