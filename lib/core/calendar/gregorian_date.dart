import 'leap_year_calculator.dart';

/// Represents a standard date in the Gregorian calendar.
///
/// [year] Gregorian year (e.g., 2024, 2025)
/// [month] Gregorian month (1 = January ... 12 = December)
/// [day] Day of month (1..31 depending on month and leap year)
class GregorianDate implements Comparable<GregorianDate> {
  final int year;
  final int month;
  final int day;

  GregorianDate(this.year, this.month, this.day) {
    if (month < 1 || month > 12) {
      throw ArgumentError('Gregorian month must be between 1 and 12, was $month');
    }
    final maxDays = daysInMonthFor(year, month);
    if (day < 1 || day > maxDays) {
      throw ArgumentError(
        'Day must be between 1 and $maxDays for month $month in year $year, was $day',
      );
    }
  }

  bool isLeapYear() => LeapYearCalculator.isGregorianLeapYear(year);

  int daysInMonth() => daysInMonthFor(year, month);

  @override
  int compareTo(GregorianDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(GregorianDate other) => compareTo(other) < 0;
  bool operator <=(GregorianDate other) => compareTo(other) <= 0;
  bool operator >(GregorianDate other) => compareTo(other) > 0;
  bool operator >=(GregorianDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GregorianDate &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          month == other.month &&
          day == other.day;

  @override
  int get hashCode => year.hashCode ^ month.hashCode ^ day.hashCode;

  @override
  String toString() {
    final mStr = month.toString().padLeft(2, '0');
    final dStr = day.toString().padLeft(2, '0');
    return '$year-$mStr-$dStr';
  }

  static bool isLeapYearFor(int year) => LeapYearCalculator.isGregorianLeapYear(year);

  static int daysInMonthFor(int year, int month) {
    switch (month) {
      case 1:
      case 3:
      case 5:
      case 7:
      case 8:
      case 10:
      case 12:
        return 31;
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      case 2:
        return isLeapYearFor(year) ? 29 : 28;
      default:
        return 30;
    }
  }
}
