import 'ethiopian_month.dart';
import 'leap_year_calculator.dart';

/// Represents a date in the Ethiopian Calendar (ዓውደ አኅዛብ).
///
/// [year] Ethiopian year (e.g., 2017 E.C.)
/// [month] Ethiopian month (1 = Meskerem ... 13 = Pagume)
/// [day] Ethiopian day of month (1..30 for regular months, 1..5/6 for Pagume)
class EthiopianDate implements Comparable<EthiopianDate> {
  final int year;
  final int month;
  final int day;

  EthiopianDate(this.year, this.month, this.day) {
    if (month < 1 || month > 13) {
      throw ArgumentError('Ethiopian month must be between 1 and 13, was $month');
    }
    final maxDays = daysInMonthFor(year, month);
    if (day < 1 || day > maxDays) {
      throw ArgumentError(
        'Day must be between 1 and $maxDays for month $month in year $year, was $day',
      );
    }
  }

  EthiopianMonth get monthEnum => EthiopianMonth.fromNumber(month);

  bool isLeapYear() => LeapYearCalculator.isEthiopianLeapYear(year);

  int daysInMonth() => daysInMonthFor(year, month);

  @override
  int compareTo(EthiopianDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  bool operator <(EthiopianDate other) => compareTo(other) < 0;
  bool operator <=(EthiopianDate other) => compareTo(other) <= 0;
  bool operator >(EthiopianDate other) => compareTo(other) > 0;
  bool operator >=(EthiopianDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EthiopianDate &&
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

  static bool isLeapYearFor(int year) => LeapYearCalculator.isEthiopianLeapYear(year);

  static int daysInMonthFor(int year, int month) {
    if (month < 1 || month > 13) {
      throw ArgumentError('Month must be between 1 and 13, received: $month');
    }
    if (month == 13) {
      return isLeapYearFor(year) ? 6 : 5;
    } else {
      return 30;
    }
  }
}

