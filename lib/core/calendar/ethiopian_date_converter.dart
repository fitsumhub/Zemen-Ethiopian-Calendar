import 'ethiopian_date.dart';
import 'gregorian_date.dart';

/// Astronomical and algorithmic bidirectional converter between the Ethiopian Calendar
/// and the International Gregorian Calendar using Julian Day Number (JDN) equations.
///
/// Provides mathematically proven, lossless conversions across past, present, and future centuries.
class EthiopianDateConverter {
  /// Astronomical epoch of the Ethiopian Calendar in Julian Day Numbers.
  /// Corresponds to Meskerem 1, 1 E.C. (August 29, 8 C.E. Julian / August 27, 8 C.E. proleptic Gregorian).
  static const int ethiopianEpochJdn = 1724221;

  /// Validates whether the given year, month, and day constitute a valid Ethiopian date.
  static bool isValidEthiopianDate(int year, int month, int day) {
    if (month < 1 || month > 13) return false;
    final maxDays = EthiopianDate.daysInMonthFor(year, month);
    return day >= 1 && day <= maxDays;
  }

  /// Validates whether the given year, month, and day constitute a valid Gregorian date.
  static bool isValidGregorianDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    final maxDays = GregorianDate.daysInMonthFor(year, month);
    return day >= 1 && day <= maxDays;
  }

  /// Converts an Ethiopian date to its Julian Day Number (JDN).
  static int ethiopianToJulianDay(int year, int month, int day) {
    if (!isValidEthiopianDate(year, month, day)) {
      throw ArgumentError('Invalid Ethiopian date: $year-$month-$day');
    }
    return ethiopianEpochJdn +
        365 * (year - 1) +
        (year ~/ 4) +
        30 * (month - 1) +
        (day - 1);
  }

  static int ethiopianDateToJulianDay(EthiopianDate date) {
    return ethiopianToJulianDay(date.year, date.month, date.day);
  }

  /// Converts a Julian Day Number (JDN) to its corresponding Ethiopian date.
  static EthiopianDate julianDayToEthiopian(int jdn) {
    final totalDays = jdn - ethiopianEpochJdn;
    final cycle = totalDays ~/ 1461;
    var rem = totalDays % 1461;
    if (rem < 0) rem += 1461;
    final adjustedCycle = (totalDays < 0 && rem != 0) ? cycle - 1 : cycle;

    final int yearOffset;
    final int dayInYear;
    if (rem < 365) {
      yearOffset = 0;
      dayInYear = rem;
    } else if (rem < 730) {
      yearOffset = 1;
      dayInYear = rem - 365;
    } else if (rem < 1096) {
      yearOffset = 2;
      dayInYear = rem - 730;
    } else {
      yearOffset = 3;
      dayInYear = rem - 1096;
    }

    final year = adjustedCycle * 4 + yearOffset + 1;
    final month = (dayInYear ~/ 30) + 1;
    final day = (dayInYear % 30) + 1;
    return EthiopianDate(year, month, day);
  }

  /// Converts a Gregorian calendar date to its Julian Day Number (JDN).
  static int gregorianToJulianDay(int year, int month, int day) {
    if (!isValidGregorianDate(year, month, day)) {
      throw ArgumentError('Invalid Gregorian date: $year-$month-$day');
    }
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + ((153 * m + 2) ~/ 5) + 365 * y + (y ~/ 4) - (y ~/ 100) + (y ~/ 400) - 32045;
  }

  static int gregorianDateToJulianDay(GregorianDate date) {
    return gregorianToJulianDay(date.year, date.month, date.day);
  }

  /// Converts a Julian Day Number (JDN) to its corresponding Gregorian date.
  static GregorianDate julianDayToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - ((146097 * b) ~/ 4);
    final d = (4 * c + 3) ~/ 1461;
    final e = c - ((1461 * d) ~/ 4);
    final m = (5 * e + 2) ~/ 153;
    final day = e - ((153 * m + 2) ~/ 5) + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + (m ~/ 10);
    return GregorianDate(year, month, day);
  }

  /// Converts an Ethiopian date to a Gregorian date.
  static GregorianDate toGregorian(EthiopianDate ethiopianDate) {
    final jdn = ethiopianDateToJulianDay(ethiopianDate);
    return julianDayToGregorian(jdn);
  }

  static GregorianDate toGregorianFromYMD(int year, int month, int day) {
    final jdn = ethiopianToJulianDay(year, month, day);
    return julianDayToGregorian(jdn);
  }

  /// Converts a Gregorian date to an Ethiopian date.
  static EthiopianDate toEthiopian(GregorianDate gregorianDate) {
    final jdn = gregorianDateToJulianDay(gregorianDate);
    return julianDayToEthiopian(jdn);
  }

  static EthiopianDate toEthiopianFromYMD(int year, int month, int day) {
    final jdn = gregorianToJulianDay(year, month, day);
    return julianDayToEthiopian(jdn);
  }

  /// Returns the ISO-8601 day of the week for an Ethiopian date:
  /// 1 = Monday (ሰኞ), 2 = Tuesday (ማክሰኞ), ..., 6 = Saturday (ቅዳሜ), 7 = Sunday (እሑድ).
  static int getDayOfWeek(EthiopianDate date) {
    final jdn = ethiopianDateToJulianDay(date);
    final dow0 = (jdn % 7);
    return dow0 + 1;
  }

  /// Adds days to an Ethiopian date.
  static EthiopianDate addDays(EthiopianDate date, int days) {
    final currentJdn = ethiopianDateToJulianDay(date);
    return julianDayToEthiopian(currentJdn + days);
  }

  /// Subtracts days from an Ethiopian date.
  static EthiopianDate subtractDays(EthiopianDate date, int days) {
    return addDays(date, -days);
  }

  /// Calculates the number of days between two Ethiopian dates (to - from).
  static int daysBetween(EthiopianDate from, EthiopianDate to) {
    return ethiopianDateToJulianDay(to) - ethiopianDateToJulianDay(from);
  }
}
