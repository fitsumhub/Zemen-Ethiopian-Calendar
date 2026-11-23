import 'dart:math' as math;
import '../localization/app_language.dart';
import '../localization/locale_strings.dart';
import 'ethiopian_date.dart';
import 'ethiopian_date_converter.dart';
import 'leap_year_calculator.dart';

/// Represents a calculated movable Orthodox fast or feast.
class OrthodoxFeast {
  final String nameAmharic;
  final String nameEnglish;
  final String nameOromo;
  final String nameTigrinya;
  final EthiopianDate ethiopianDate;
  final String description;
  final bool isFast;

  const OrthodoxFeast({
    required this.nameAmharic,
    required this.nameEnglish,
    required this.nameOromo,
    required this.nameTigrinya,
    required this.ethiopianDate,
    required this.description,
    this.isFast = false,
  });

  String get amharicName => nameAmharic;
  String get englishName => nameEnglish;

  String get dayOfWeekName => LocaleStrings.getWeekdayShort(
        EthiopianDateConverter.getDayOfWeek(ethiopianDate),
        AppLanguage.amharic,
      );
}

/// Complete computational result of Bahire Hasab for a given Ethiopian year.
class BahireHasabResult {
  final int ethiopianYear;
  final int ameteAlem;
  final Evangelist evangelist;
  final int wenber;
  final int abeqte;
  final int metqi;
  final int metqiMonth; // 1 = Meskerem, 2 = Tikimt
  final EthiopianDate nenewe;
  final List<OrthodoxFeast> movableFeasts;
  final int medeb;
  final int mebajaHamer;

  const BahireHasabResult({
    required this.ethiopianYear,
    required this.ameteAlem,
    required this.evangelist,
    required this.wenber,
    required this.abeqte,
    required this.metqi,
    required this.metqiMonth,
    required this.nenewe,
    required this.movableFeasts,
    required this.medeb,
    required this.mebajaHamer,
  });
}

/// Bahire Hasab (ባሕረ ሐሳብ) - Computus of the Ethiopian Orthodox Tewahedo Church.
///
/// Implements the mathematical and astronomical algorithms laid out by Patriarch Demetrius of Alexandria
/// and canonicalized within the Ethiopian Ge'ez computational tradition.
class BahireHasab {
  static const int ameteFeleseOffset = 5500;
  static const int metonicCycle = 19;
  static const int epactMultiplier = 11;
  static const int lunarMonthDays = 30;

  static const int offsetNenewe = 0;
  static const int offsetAbiyTsom = 14;
  static const int offsetDebreZeit = 41;
  static const int offsetHosanna = 62;
  static const int offsetSiklet = 67;
  static const int offsetFasika = 69;
  static const int offsetRikbeKahnat = 93;
  static const int offsetErget = 108;
  static const int offsetParaclete = 118;
  static const int offsetTsomeHawaryat = 119;
  static const int offsetTsomeDihnet = 121;

  static int ameteAlem(int year) => year + ameteFeleseOffset;

  static Evangelist evangelist(int year) =>
      LeapYearCalculator.getEvangelist(year);

  static int medeb(int year) => ameteAlem(year) % metonicCycle;

  static int wenber(int year) {
    final raw = medeb(year) - 1;
    return raw < 0 ? 18 : raw;
  }

  static int abeqte(int year) =>
      (wenber(year) * epactMultiplier) % lunarMonthDays;

  static int metqi(int year) {
    final a = abeqte(year);
    return a == 0 ? 30 : 30 - a;
  }

  static int metqiMonth(int year) => metqi(year) > 14 ? 1 : 2;

  static EthiopianDate metqiDate(int year) =>
      EthiopianDate(year, metqiMonth(year), metqi(year));

  static int dayOfWeekTewsak(int dayOfWeek) {
    switch (dayOfWeek) {
      case 7: // እሑድ (Sunday)
        return 7;
      case 1: // ሰኞ (Monday)
        return 6;
      case 2: // ማክሰኞ (Tuesday)
        return 5;
      case 3: // ረቡዕ (Wednesday)
        return 4;
      case 4: // ሐሙስ (Thursday)
        return 3;
      case 5: // ዓርብ (Friday)
        return 2;
      case 6: // ቅዳሜ (Saturday)
        return 8;
      default:
        return 0;
    }
  }

  static int mebajaHamer(int year) {
    final mDate = metqiDate(year);
    final dow = EthiopianDateConverter.getDayOfWeek(mDate);
    return mDate.day + dayOfWeekTewsak(dow);
  }

  static EthiopianDate nenewe(int year) {
    final mMonth = metqiMonth(year);
    final mDate = metqiDate(year);
    final dow = EthiopianDateConverter.getDayOfWeek(mDate);
    final sum = mDate.day + dayOfWeekTewsak(dow);

    final int neneweMonth;
    final int neneweDay;

    if (mMonth == 1) {
      if (sum <= 30) {
        neneweMonth = 5; // Tir
        neneweDay = sum;
      } else {
        neneweMonth = 6; // Yakatit
        neneweDay = sum - 30;
      }
    } else {
      neneweMonth = 6; // Yakatit
      neneweDay = sum;
    }

    return EthiopianDate(year, neneweMonth, neneweDay);
  }

  static EthiopianDate _addDays(EthiopianDate base, int days) {
    return EthiopianDateConverter.addDays(base, days);
  }

  static EthiopianDate abiyTsom(int year) =>
      _addDays(nenewe(year), offsetAbiyTsom);

  static EthiopianDate debreZeit(int year) =>
      _addDays(nenewe(year), offsetDebreZeit);

  static EthiopianDate hosanna(int year) =>
      _addDays(nenewe(year), offsetHosanna);

  static EthiopianDate siklet(int year) =>
      _addDays(nenewe(year), offsetSiklet);

  static EthiopianDate fasika(int year) =>
      _addDays(nenewe(year), offsetFasika);

  static EthiopianDate rikbeKahnat(int year) =>
      _addDays(nenewe(year), offsetRikbeKahnat);

  static EthiopianDate erget(int year) =>
      _addDays(nenewe(year), offsetErget);

  static EthiopianDate paraclete(int year) =>
      _addDays(nenewe(year), offsetParaclete);

  static EthiopianDate tsomeHawaryat(int year) =>
      _addDays(nenewe(year), offsetTsomeHawaryat);

  static EthiopianDate tsomeDihnet(int year) =>
      _addDays(nenewe(year), offsetTsomeDihnet);

  static int apostlesFastDuration(int year) {
    final start = tsomeHawaryat(year);
    final end = EthiopianDate(year, 11, 5); // Hamle 5
    final diff = EthiopianDateConverter.daysBetween(start, end);
    return math.max(0, diff);
  }

  static int greatLentDuration() => 55;

  static int ninevehFastDuration() => 3;

  static bool isGreatLent(EthiopianDate date) {
    final lentStart = abiyTsom(date.year);
    final easter = fasika(date.year);
    final dateJdn = EthiopianDateConverter.ethiopianDateToJulianDay(date);
    final startJdn = EthiopianDateConverter.ethiopianDateToJulianDay(lentStart);
    final easterJdn = EthiopianDateConverter.ethiopianDateToJulianDay(easter);
    return dateJdn >= startJdn && dateJdn < easterJdn;
  }

  static bool isApostlesFast(EthiopianDate date) {
    final fastStart = tsomeHawaryat(date.year);
    final fastEnd = EthiopianDate(date.year, 11, 5);
    final dateJdn = EthiopianDateConverter.ethiopianDateToJulianDay(date);
    final startJdn = EthiopianDateConverter.ethiopianDateToJulianDay(fastStart);
    final endJdn = EthiopianDateConverter.ethiopianDateToJulianDay(fastEnd);
    return dateJdn >= startJdn && dateJdn <= endJdn;
  }

  static bool isNinevehFast(EthiopianDate date) {
    final neneweStart = nenewe(date.year);
    final dateJdn = EthiopianDateConverter.ethiopianDateToJulianDay(date);
    final startJdn = EthiopianDateConverter.ethiopianDateToJulianDay(neneweStart);
    return dateJdn >= startJdn && dateJdn < (startJdn + 3);
  }

  static bool isFiftyDaysOfJoy(EthiopianDate date) {
    final easter = fasika(date.year);
    final pentecost = paraclete(date.year);
    final dateJdn = EthiopianDateConverter.ethiopianDateToJulianDay(date);
    final easterJdn = EthiopianDateConverter.ethiopianDateToJulianDay(easter);
    final pentecostJdn = EthiopianDateConverter.ethiopianDateToJulianDay(pentecost);
    return dateJdn >= easterJdn && dateJdn <= pentecostJdn;
  }

  static bool isWeeklyFastDay(EthiopianDate date) {
    final dow = EthiopianDateConverter.getDayOfWeek(date);
    if (dow != 3 && dow != 5) return false;
    return !isFiftyDaysOfJoy(date);
  }

  static List<OrthodoxFeast> getMovableFeasts(int year) {
    final neneweDate = nenewe(year);
    final neneweJdn = EthiopianDateConverter.ethiopianDateToJulianDay(neneweDate);

    OrthodoxFeast feastAt(
      int offset,
      String amharic,
      String english,
      String oromo,
      String tigrinya,
      String desc,
      bool isFast,
    ) {
      final d = EthiopianDateConverter.julianDayToEthiopian(neneweJdn + offset);
      return OrthodoxFeast(
        nameAmharic: amharic,
        nameEnglish: english,
        nameOromo: oromo,
        nameTigrinya: tigrinya,
        ethiopianDate: d,
        description: desc,
        isFast: isFast,
      );
    }

    return [
      feastAt(
        offsetNenewe,
        'ጾመ ነነዌ',
        'Fast of Nineveh (Nenewe)',
        'Sooma Nannawwee',
        'ጾመ ነነዌ',
        'Three-day fast commemorating the repentance of the people of Nineveh.',
        true,
      ),
      feastAt(
        offsetAbiyTsom,
        'ዓቢይ ጾም (ሁዳዴ)',
        'Great Lent (Abiy Tsom / Hudade)',
        'Sooma Guddaa',
        'ዓቢይ ጾም',
        'The 55-day Great Lent commemorating Christ\'s 40-day wilderness fast.',
        true,
      ),
      feastAt(
        offsetDebreZeit,
        'ደብረ ዘይት',
        'Debre Zeit (Mount of Olives)',
        'Dabra Zayit',
        'ደብረ ዘይት',
        'Mid-Lent Sunday on the Mount of Olives commemorating Christ\'s Second Coming.',
        false,
      ),
      feastAt(
        offsetHosanna,
        'ሆሣዕና (የዘንባባ እሑድ)',
        'Hosanna (Palm Sunday)',
        'Hosaa\'inaa',
        'ሆሣዕና',
        'Triumphal entry of Jesus Christ into Jerusalem with palms.',
        false,
      ),
      feastAt(
        offsetSiklet,
        'ስቅለት (መልካም ዓርብ)',
        'Good Friday (Siklet)',
        'Fannifama',
        'ስቅለት',
        'Solemn remembrance of the Passion and Crucifixion of Christ.',
        true,
      ),
      feastAt(
        offsetFasika,
        'ፋሲካ / ትንሣኤ',
        'Fasika / Easter (Tensae)',
        'Ayyaana Du\'aa Ka\'umsaa',
        'ፋሲካ / ትንሣኤ',
        'Feast of the Glorious Resurrection of our Lord and Savior Jesus Christ.',
        false,
      ),
      feastAt(
        offsetRikbeKahnat,
        'ርክበ ካህናት',
        'Rikbe Kahnat (Synod of the Clergy)',
        'Rikba Kaahinootaa',
        'ርክበ ካህናት',
        'Midway gathering of priests 24 days after Easter.',
        false,
      ),
      feastAt(
        offsetErget,
        'ዕርገት',
        'Ascension Day (Erget)',
        'Ol Bahinsa Gooftaa',
        'ዕርገት',
        'Ascension of our Lord Jesus Christ into Heaven 40 days after Easter.',
        false,
      ),
      feastAt(
        offsetParaclete,
        'ጰራቅሊጦስ (በዓለ ሃምሳ)',
        'Pentecost / Paraclete (Fifty Days)',
        'Pharaaqliixoos',
        'ጰራቅሊጦስ',
        'Descent of the Holy Spirit upon the Apostles on the 50th day after Easter.',
        false,
      ),
      feastAt(
        offsetTsomeHawaryat,
        'ጾመ ሐዋርያት (የሰኔ ጾም)',
        'Fast of the Apostles (Sene Tsom)',
        'Sooma Ergamootaa',
        'ጾመ ሐዋርያት',
        'Fast observed by the Holy Apostles before scattering to preach the Gospel.',
        true,
      ),
      feastAt(
        offsetTsomeDihnet,
        'ጾመ ድኅነት',
        'Fast of Salvation (Tsome Dihnet)',
        'Sooma Fayyinaa',
        'ጾመ ድኅነት',
        'Wednesday and Friday fasts throughout the year commemorating Christ\'s betrayal and passion.',
        true,
      ),
    ];
  }

  static BahireHasabResult calculate(int year) {
    return BahireHasabResult(
      ethiopianYear: year,
      ameteAlem: ameteAlem(year),
      evangelist: evangelist(year),
      wenber: wenber(year),
      abeqte: abeqte(year),
      metqi: metqi(year),
      metqiMonth: metqiMonth(year),
      nenewe: nenewe(year),
      movableFeasts: getMovableFeasts(year),
      medeb: medeb(year),
      mebajaHamer: mebajaHamer(year),
    );
  }

  /// Alias used by converter UI (same as [getMovableFeasts]).
  static List<OrthodoxFeast> getAllFeastsForYear(int year) => getMovableFeasts(year);
}
