import '../calendar/ethiopian_calendar_engine.dart';
import '../calendar/ethiopian_date.dart';
import '../calendar/ethiopian_time_converter.dart';
import '../calendar/geez_numeral.dart';
import '../calendar/gregorian_date.dart';
import '../calendar/leap_year_calculator.dart';
import '../holidays/holiday_engine.dart';
import '../localization/app_language.dart';
import '../localization/locale_strings.dart';

enum HomeWidgetKind {
  basicDate,
  classicDate,
  prophetsFast,
  nativityCountdown,
  /// Deep charcoal + champagne gold editorial date.
  imperialGold,
  /// Obsidian foil card focused on the saint of the day.
  obsidianSaint,
  /// Dual Ethiopian / Gregorian clock atelier.
  atelierClock,
  /// Upcoming feast countdown in couture layout.
  feastAtelier,
  /// Stacked Ethiopian + Gregorian dual date.
  dualStack,
  /// Emerald glass brand card.
  emeraldGlass,
  /// Warm parchment heritage scroll.
  parchmentScroll,
  /// Monument Ge'ez day numeral.
  geezMonument,
  /// Fasting status hero.
  midnightFast,
  /// Compact month + saint glance.
  monthGlance,
}

extension HomeWidgetKindX on HomeWidgetKind {
  static int get lastIndex => HomeWidgetKind.values.length - 1;

  static HomeWidgetKind fromIndex(int index) =>
      HomeWidgetKind.values[index.clamp(0, lastIndex)];
}

/// Live payload for EthioCal home-screen widgets (in-app preview + Android sync).
class HomeWidgetSnapshot {
  final HomeWidgetKind kind;
  final EthiopianDate eth;
  final GregorianDate greg;
  final int dayOfWeek;
  final String monthName;
  final String weekdayName;
  final String gregLabel;
  final String geezDay;
  final String geezYear;
  final bool isFasting;
  final String fastingReason;
  final int? prophetsDayIndex;
  final int? prophetsTotalDays;
  final int? daysUntilAdvent;
  final int? daysUntilGenna;
  final String gennaLabel;
  final String? upcomingTitleAm;
  final String? upcomingTitleEn;
  final int? daysUntilUpcoming;
  final String saintName;
  final String saintNameEn;
  final String formattedEthTime;
  final String formattedGregTime;

  const HomeWidgetSnapshot({
    required this.kind,
    required this.eth,
    required this.greg,
    required this.dayOfWeek,
    required this.monthName,
    required this.weekdayName,
    required this.gregLabel,
    required this.geezDay,
    required this.geezYear,
    required this.isFasting,
    required this.fastingReason,
    required this.saintName,
    required this.saintNameEn,
    required this.gennaLabel,
    this.formattedEthTime = '',
    this.formattedGregTime = '',
    this.prophetsDayIndex,
    this.prophetsTotalDays,
    this.daysUntilAdvent,
    this.daysUntilGenna,
    this.upcomingTitleAm,
    this.upcomingTitleEn,
    this.daysUntilUpcoming,
  });

  double get prophetsProgress {
    final day = prophetsDayIndex;
    final total = prophetsTotalDays;
    if (day == null || total == null || total <= 0) return 0;
    return (day / total).clamp(0.0, 1.0);
  }

  /// Rough advent→Genna season progress for nativity card (0..1).
  double get gennaSeasonProgress {
    final left = daysUntilGenna ?? 0;
    final total = prophetsTotalDays ?? 43;
    if (left <= 0) return 1;
    final elapsed = (total - left).clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }
}

class HomeWidgetEngine {
  HomeWidgetEngine._();

  static const _gregEn = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const _gregAm = [
    'ጃንዋሪ', 'ፌብሩዋሪ', 'ማርች', 'ኤፕሪል', 'ሜይ', 'ጁን',
    'ጁላይ', 'ኦገስት', 'ሰፕቴምበር', 'ኦክቶበር', 'ኖቬምበር', 'ዲሴምበር',
  ];

  static HomeWidgetSnapshot build(
    HomeWidgetKind kind, {
    AppLanguage lang = AppLanguage.amharic,
    EthiopianDate? forDate,
  }) {
    final eth = forDate ?? EthiopianCalendarEngine.todayEthiopian();
    final greg = EthiopianCalendarEngine.toGregorian(eth);
    final dow = EthiopianCalendarEngine.getDayOfWeek(eth);
    final fasting = HolidayEngine.isFastingDay(eth);
    final saint = HolidayEngine.monthlySaints.firstWhere(
      (s) => s.day == eth.day,
      orElse: () => HolidayEngine.monthlySaints.first,
    );

    final prophets = _prophetsProgress(eth);
    final gennaDay = HolidayEngine.gennaDay(eth.year);
    var genna = EthiopianDate(eth.year, 4, gennaDay);
    var daysToGenna = EthiopianCalendarEngine.daysBetween(eth, genna);
    if (daysToGenna < 0) {
      genna = EthiopianDate(eth.year + 1, 4, HolidayEngine.gennaDay(eth.year + 1));
      daysToGenna = EthiopianCalendarEngine.daysBetween(eth, genna);
    }

    final upcoming = _nextPublicHoliday(eth);
    final monthName = LocaleStrings.getMonthName(eth.month, lang);
    final gennaMonth = LocaleStrings.getMonthName(genna.month, lang);

    final now = DateTime.now();
    final ethTime = EthiopianTimeConverter.gregorianToEthiopian(now.hour, now.minute);
    final formattedEth = '${ethTime.period.amharic} ${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')}';
    final formattedGreg = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return HomeWidgetSnapshot(
      kind: kind,
      eth: eth,
      greg: greg,
      dayOfWeek: dow,
      monthName: monthName,
      weekdayName: LocaleStrings.getWeekdayLong(dow, lang),
      gregLabel: _gregLabel(greg, lang),
      geezDay: GeezNumeral.toGeez(eth.day),
      geezYear: GeezNumeral.toGeez(eth.year),
      isFasting: fasting.isFasting,
      fastingReason: fasting.reason,
      saintName: saint.nameAmharic,
      saintNameEn: saint.nameEnglish,
      formattedEthTime: formattedEth,
      formattedGregTime: formattedGreg,
      prophetsDayIndex: prophets.$1,
      prophetsTotalDays: prophets.$2,
      daysUntilAdvent: prophets.$3,
      daysUntilGenna: daysToGenna,
      gennaLabel: '$gennaMonth ${genna.day}',
      upcomingTitleAm: upcoming?.$1,
      upcomingTitleEn: upcoming?.$2,
      daysUntilUpcoming: upcoming?.$3,
    );
  }

  /// Steps an EthiopianDate forward or backward by [offsetDays].
  static EthiopianDate shiftDays(EthiopianDate date, int offsetDays) {
    if (offsetDays == 0) return date;
    final jdn = EthiopianCalendarEngine.ethiopianToJdn(date);
    return EthiopianCalendarEngine.jdnToEthiopian(jdn + offsetDays);
  }

  static String _gregLabel(GregorianDate greg, AppLanguage lang) {
    final useAm = lang == AppLanguage.amharic || lang == AppLanguage.tigrinya;
    final month = useAm ? _gregAm[greg.month - 1] : _gregEn[greg.month - 1];
    return '$month ${greg.day}, ${greg.year}';
  }

  /// (dayIndex?, totalFastDays, daysUntilStart?)
  static (int?, int?, int?) _prophetsProgress(EthiopianDate eth) {
    var year = eth.year;
    var start = EthiopianDate(year, 3, 15);
    var endExclusive = EthiopianDate(year, 4, HolidayEngine.gennaDay(year));
    var startJ = EthiopianCalendarEngine.ethiopianToJdn(start);
    var endJ = EthiopianCalendarEngine.ethiopianToJdn(endExclusive);
    final todayJ = EthiopianCalendarEngine.ethiopianToJdn(eth);
    if (todayJ >= endJ) {
      year += 1;
      start = EthiopianDate(year, 3, 15);
      endExclusive = EthiopianDate(year, 4, HolidayEngine.gennaDay(year));
      startJ = EthiopianCalendarEngine.ethiopianToJdn(start);
      endJ = EthiopianCalendarEngine.ethiopianToJdn(endExclusive);
    }
    final total = endJ - startJ;
    if (todayJ < startJ) {
      return (null, total, startJ - todayJ);
    }
    return (todayJ - startJ + 1, total, 0);
  }

  static String shareText(HomeWidgetSnapshot s, {AppLanguage lang = AppLanguage.amharic}) {
    final fasting = s.isFasting ? s.fastingReason : 'ፍስክ · Regular day';
    final upcoming = (s.upcomingTitleAm?.isNotEmpty ?? false)
        ? '${s.upcomingTitleAm} · ${s.daysUntilUpcoming} ቀን'
        : '';
    final prophets = s.prophetsDayIndex != null && s.prophetsDayIndex! > 0
        ? 'ጾመ ነቢያት ቀን ${s.prophetsDayIndex}/${s.prophetsTotalDays}'
        : (s.daysUntilAdvent != null && s.daysUntilAdvent! > 0)
            ? 'ጾመ ነቢያት በ ${s.daysUntilAdvent} ቀን'
            : null;
    return [
      'Zemen: Ethiopian Calendar · ${s.weekdayName}',
      '${s.monthName} ${s.eth.day} (${s.geezDay}) ${s.eth.year} ዓ.ም',
      s.gregLabel,
      'ቅዱስ · ${s.saintName}',
      fasting,
      ?prophets,
      if (s.daysUntilGenna != null) 'ገና · ${s.daysUntilGenna} ቀን (${s.gennaLabel})',
      if (upcoming.isNotEmpty) upcoming,
    ].join('\n');
  }

  static (String, String, int)? _nextPublicHoliday(EthiopianDate eth) {
    final yearList = [
      ...HolidayEngine.getHolidaysForYear(eth.year),
      ...HolidayEngine.getHolidaysForYear(eth.year + 1),
    ].where((h) => h.isPublicHoliday).toList()
      ..sort((a, b) => a.ethiopianDate.compareTo(b.ethiopianDate));

    for (final h in yearList) {
      final d = EthiopianCalendarEngine.daysBetween(eth, h.ethiopianDate);
      if (d >= 0) {
        return (h.titleAmharic, h.titleEnglish, d);
      }
    }
    return null;
  }

  static Map<String, String> toPreferenceMap(
    HomeWidgetSnapshot s, {
    bool showFasting = true,
    bool showGeez = true,
    bool showSaint = true,
    String size = 'compact',
    String firstDayOfWeek = 'MONDAY',
    String themeFamily = 'noirGold',
  }) {
    final monthStart = EthiopianDate(s.eth.year, s.eth.month, 1);
    final monthStartDow = EthiopianCalendarEngine.getDayOfWeek(monthStart);
    return {
      'widget_eth_y': '${s.eth.year}',
      'widget_eth_m': '${s.eth.month}',
      'widget_eth_d': '${s.eth.day}',
      'widget_month': s.monthName,
      'widget_weekday': s.weekdayName,
      'widget_dow': '${s.dayOfWeek}',
      'widget_days_in_month': '${s.eth.daysInMonth()}',
      'widget_month_start_dow': '$monthStartDow',
      'widget_first_day': firstDayOfWeek,
      'widget_geez': s.geezDay,
      'widget_geez_year': s.geezYear,
      'widget_evangelist': LeapYearCalculator.getEvangelist(s.eth.year).amharic,
      'widget_greg': s.gregLabel,
      'widget_fasting': s.isFasting ? '1' : '0',
      'widget_fasting_reason': s.fastingReason,
      'widget_saint': s.saintName,
      'widget_time_eth': s.formattedEthTime,
      'widget_time_greg': s.formattedGregTime,
      'widget_prophets_day': '${s.prophetsDayIndex ?? 0}',
      'widget_prophets_total': '${s.prophetsTotalDays ?? 43}',
      'widget_days_advent': '${s.daysUntilAdvent ?? 0}',
      'widget_days_genna': '${s.daysUntilGenna ?? 0}',
      'widget_genna_label': s.gennaLabel,
      'widget_upcoming_am': s.upcomingTitleAm ?? '',
      'widget_upcoming_en': s.upcomingTitleEn ?? '',
      'widget_upcoming_days': '${s.daysUntilUpcoming ?? 0}',
      'widget_kind': '${s.kind.index}',
      'widget_theme_family': themeFamily,
      'widget_show_fasting': showFasting ? '1' : '0',
      'widget_show_geez': showGeez ? '1' : '0',
      'widget_show_saint': showSaint ? '1' : '0',
      'widget_size': size,
      'widget_updated_ms': '${DateTime.now().millisecondsSinceEpoch}',
    };
  }
}
