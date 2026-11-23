import '../calendar/ethiopian_date.dart';
import '../calendar/ethiopian_season.dart';
import '../calendar/gregorian_date.dart';
import '../calendar/leap_year_calculator.dart';
import '../holidays/holiday_engine.dart';
import 'app_language.dart';
import 'locale_strings.dart';

/// Dates and engine names rendered in ONE language at a time.
///
/// Screens used to pick Amharic or English from the calendar format (EC/GC),
/// which mixed languages on the same screen. Everything user-facing should go
/// through these helpers (or [LocaleStrings.get]) with the app language.
class DateText {
  DateText._();

  static const List<String> _gregLong = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _gregShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _gregLongFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const List<String> _gregShortFr = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static final RegExp _ethiopic = RegExp('[ሀ-፿]');

  /// Amharic and Tigrinya are written in the Ge'ez script.
  static bool usesEthiopicScript(AppLanguage lang) =>
      lang == AppLanguage.amharic || lang == AppLanguage.tigrinya;

  static String gregorianMonth(int month, AppLanguage lang, {bool short = false}) {
    if (month < 1 || month > 12) return '';
    if (lang == AppLanguage.french) {
      return (short ? _gregShortFr : _gregLongFr)[month - 1];
    }
    return (short ? _gregShort : _gregLong)[month - 1];
  }

  /// "Hidar 7, 2019 E.C." · "ኅዳር 7፣ 2019 ዓ.ም"
  static String ethiopian(
    EthiopianDate date,
    AppLanguage lang, {
    bool year = true,
    bool era = true,
  }) {
    final month = LocaleStrings.getMonthName(date.month, lang);
    if (!year) return '$month ${date.day}';
    final sep = usesEthiopicScript(lang) ? '፣ ' : ', ';
    final base = '$month ${date.day}$sep${date.year}';
    return era ? '$base ${LocaleStrings.get('era_ec', lang)}' : base;
  }

  /// "November 16, 2026" · "16 novembre 2026"
  static String gregorian(
    GregorianDate date,
    AppLanguage lang, {
    bool short = false,
    bool year = true,
    bool era = false,
  }) {
    final month = gregorianMonth(date.month, lang, short: short);
    final String base;
    if (lang == AppLanguage.french) {
      base = year ? '${date.day} $month ${date.year}' : '${date.day} $month';
    } else {
      base = year ? '$month ${date.day}, ${date.year}' : '$month ${date.day}';
    }
    return era && year ? '$base ${LocaleStrings.get('era_gc', lang)}' : base;
  }

  /// Ethiopian year with its era: "2019 E.C." · "2019 ዓ.ም"
  static String ethiopianYear(int year, AppLanguage lang) =>
      '$year ${LocaleStrings.get('era_ec', lang)}';

  /// Engine strings are stored as "አማርኛ (English)". Returns the half that
  /// matches [lang] so a label is never shown in two languages at once.
  static String bilingual(String text, AppLanguage lang) {
    final open = text.indexOf(' (');
    if (open <= 0 || !text.endsWith(')')) return text;
    final first = text.substring(0, open).trim();
    final second = text.substring(open + 2, text.length - 1).trim();
    final firstIsEthiopic = _ethiopic.hasMatch(first);
    if (!firstIsEthiopic && !_ethiopic.hasMatch(second)) return text;

    // A half may carry an alias in the other script after " / ".
    String only(String half, {required bool ethiopic}) => half
        .split(' / ')
        .where((part) => _ethiopic.hasMatch(part) == ethiopic)
        .join(' / ')
        .trim();

    final ethiopicHalf =
        firstIsEthiopic ? first : only(second, ethiopic: true);
    final latinHalf = firstIsEthiopic
        ? only(second, ethiopic: false)
        : only(first, ethiopic: false);
    final wanted = usesEthiopicScript(lang) ? ethiopicHalf : latinHalf;
    return wanted.isEmpty ? text : wanted;
  }

  static String holidayTitle(Holiday holiday, AppLanguage lang) {
    switch (lang) {
      case AppLanguage.amharic:
        return holiday.titleAmharic;
      case AppLanguage.oromo:
        return holiday.titleOromo.isNotEmpty ? holiday.titleOromo : holiday.titleEnglish;
      case AppLanguage.tigrinya:
        return holiday.titleTigrinya.isNotEmpty ? holiday.titleTigrinya : holiday.titleAmharic;
      case AppLanguage.english:
      case AppLanguage.french:
        return holiday.titleEnglish;
    }
  }

  static String saintName(MonthlySaintDay saint, AppLanguage lang) {
    switch (lang) {
      case AppLanguage.amharic:
        return saint.nameAmharic;
      case AppLanguage.oromo:
        return saint.nameOromo.isNotEmpty ? saint.nameOromo : saint.nameEnglish;
      case AppLanguage.tigrinya:
        return saint.nameTigrinya.isNotEmpty ? saint.nameTigrinya : saint.nameAmharic;
      case AppLanguage.english:
      case AppLanguage.french:
        return saint.nameEnglish;
    }
  }

  static String evangelist(Evangelist evangelist, AppLanguage lang) =>
      usesEthiopicScript(lang) ? evangelist.amharicName : evangelist.englishName;

  static String season(EthiopianSeason season, AppLanguage lang) =>
      usesEthiopicScript(lang) ? season.amharicName : season.englishName;

  /// One-letter weekday header in the app language (1 = Monday … 7 = Sunday).
  static String weekdayInitial(int dayOfWeek, AppLanguage lang) {
    final short = LocaleStrings.getWeekdayShort(dayOfWeek, lang);
    return short.isEmpty ? '' : String.fromCharCode(short.runes.first);
  }
}
