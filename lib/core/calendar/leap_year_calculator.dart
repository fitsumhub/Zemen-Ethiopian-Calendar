/// Encapsulates leap year calculations and the 4-year Evangelist cycle for
/// the Ethiopian Calendar and Gregorian Calendar.
class LeapYearCalculator {
  /// In the Ethiopian calendar, a year is a leap year (ዘመነ ሉቃስ) if (year % 4 == 3).
  /// During an Ethiopian leap year, Pagume (the 13th month) has 6 days instead of 5,
  /// making the year 366 days long.
  static bool isEthiopianLeapYear(int year) {
    return (year % 4 + 4) % 4 == 3;
  }

  /// Determines whether a given Gregorian year is a leap year under the Gregorian calendar rules.
  static bool isGregorianLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Returns total days in an Ethiopian year (366 for leap year, 365 otherwise).
  static int getEthiopianYearDays(int year) {
    return isEthiopianLeapYear(year) ? 366 : 365;
  }

  /// Returns total days in a Gregorian year (366 for leap year, 365 otherwise).
  static int getGregorianYearDays(int year) {
    return isGregorianLeapYear(year) ? 366 : 365;
  }

  /// Returns the Evangelist presiding over the given Ethiopian year.
  static Evangelist getEvangelist(int year) {
    return Evangelist.fromEthiopianYear(year);
  }
}

/// Traditional 4-year cycle named after the Four Evangelists (አራቱ ወንጌላውያን).
/// The year of Luke (ሉቃስ) is always the Ethiopian leap year.
enum Evangelist {
  john('ዘመነ ዮሐንስ', 'Year of John', false),
  matthew('ዘመነ ማቴዎስ', 'Year of Matthew', false),
  mark('ዘመነ ማርቆስ', 'Year of Mark', false),
  luke('ዘመነ ሉቃስ', 'Year of Luke', true);

  final String amharicName;
  final String englishName;
  final bool isLeapYear;

  const Evangelist(
    this.amharicName,
    this.englishName,
    this.isLeapYear,
  );

  String get amharic => amharicName;
  String get english => englishName;

  /// Returns the Evangelist for the given Ethiopian year based on Amete Alem (ዓመተ ዓለም = year + 5500).
  static Evangelist fromEthiopianYear(int year) {
    final ameteAlem = year + 5500;
    switch ((ameteAlem % 4 + 4) % 4) {
      case 1:
        return Evangelist.matthew;
      case 2:
        return Evangelist.mark;
      case 3:
        return Evangelist.luke;
      default:
        return Evangelist.john;
    }
  }
}
