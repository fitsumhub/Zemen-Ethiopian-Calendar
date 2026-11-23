# -*- coding: utf-8 -*-
"""Finish the Zemen 10/10 UI pass: fonts, nav hub, calendar i18n, football light, events theme."""
from __future__ import annotations

import io
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(rel: str) -> str:
    return io.open(ROOT / rel, encoding="utf-8").read()


def save(rel: str, text: str) -> None:
    io.open(ROOT / rel, "w", encoding="utf-8", newline="\n").write(text)
    print("patched", rel)


def rep(s: str, old: str, new: str, count: int = 1, path: str = "") -> str:
    c = s.count(old)
    assert c == count, (path, old[:90], c)
    return s.replace(old, new)


def fix_google_fonts_fallback(text: str) -> str:
    """Move fontFamilyFallback out of GoogleFonts.*(...) into .copyWith(...)."""

    def repl(m: re.Match[str]) -> str:
        call = m.group(0)
        # Already fixed
        if ".copyWith(fontFamilyFallback:" in call:
            return call
        # Extract trailing fontFamilyFallback arg
        fb = re.search(
            r",\s*fontFamilyFallback:\s*([^,\n]+(?:\([^)]*\))?)\s*\)\s*$",
            call,
            re.S,
        )
        if not fb:
            return call
        fallback_expr = fb.group(1).strip()
        without = call[: fb.start()] + ")"
        return without + f".copyWith(fontFamilyFallback: {fallback_expr})"

    # Match GoogleFonts.xxx( ... ) that contains fontFamilyFallback
    pattern = re.compile(
        r"GoogleFonts\.\w+\((?:[^()]|\([^()]*\))*fontFamilyFallback:(?:[^()]|\([^()]*\))*\)",
        re.S,
    )
    return pattern.sub(repl, text)


def fix_app_fonts() -> None:
    rel = "lib/core/theme/app_fonts.dart"
    text = '''import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zemen typography helpers with Ethiopic fallbacks applied via [TextStyle.copyWith].
class AppFonts {
  AppFonts._();

  static List<String> get ethiopicFallbacks => [
        GoogleFonts.notoSansEthiopic().fontFamily ?? 'Noto Sans Ethiopic',
        'Noto Sans Ethiopic',
        'Abyssinica SIL',
        'Nyala',
        'Ebrima',
        'sans-serif',
      ];

  static TextStyle _withFallback(TextStyle style, List<String>? fallback) =>
      style.copyWith(fontFamilyFallback: fallback ?? ethiopicFallbacks);

  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<String>? fontFamilyFallback,
  }) {
    return _withFallback(
      GoogleFonts.outfit(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      ),
      fontFamilyFallback,
    );
  }

  static TextStyle fraunces({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<String>? fontFamilyFallback,
  }) {
    return _withFallback(
      GoogleFonts.fraunces(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      ),
      fontFamilyFallback,
    );
  }

  static TextStyle ethiopic({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return _withFallback(
      GoogleFonts.notoSansEthiopic(
        textStyle: textStyle,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      ),
      ethiopicFallbacks,
    );
  }
}
'''
    save(rel, text)


def fix_app_theme_and_chrome() -> None:
    for rel in (
        "lib/core/theme/app_theme.dart",
        "lib/features/shared/components/app_chrome.dart",
        "lib/main.dart",
    ):
        s = load(rel)
        s2 = fix_google_fonts_fallback(s)
        if s2 != s:
            save(rel, s2)
        else:
            print("no font fallback change", rel)


def wire_events_hub() -> None:
    rel = "lib/main.dart"
    s = load(rel)
    s = rep(
        s,
        "import 'features/events/agenda_screen.dart';\n"
        "import 'features/events/events_screen.dart';\n",
        "import 'features/events/events_hub_screen.dart';\n",
        path=rel,
    )
    s = rep(
        s,
        """  static const _tabKeys = [
    'nav_calendar',
    'nav_converter',
    'nav_agenda',
    'nav_holidays',
    'nav_events',
    'nav_football',
  ];""",
        """  static const _tabKeys = [
    'nav_calendar',
    'nav_converter',
    'nav_holidays',
    'nav_events',
    'nav_football',
  ];""",
        path=rel,
    )
    s = rep(
        s,
        """    final pages = <Widget>[
      CalendarHomeScreen(),
      ConverterHomeScreen(onNavigateToCalendar: _jumpToCalendarDate),
      AgendaScreen(onOpenDate: _jumpToCalendarDate),
      HolidaysScreen(onNavigateToCalendar: _jumpToCalendarDate),
      EventsScreen(),
      FootballScreen(),
    ];""",
        """    final pages = <Widget>[
      CalendarHomeScreen(),
      ConverterHomeScreen(onNavigateToCalendar: _jumpToCalendarDate),
      HolidaysScreen(onNavigateToCalendar: _jumpToCalendarDate),
      EventsHubScreen(onOpenDate: _jumpToCalendarDate),
      FootballScreen(),
    ];""",
        path=rel,
    )
    save(rel, s)


def settings_widgets_row() -> None:
    rel = "lib/features/settings/settings_screen.dart"
    s = load(rel)
    if "showWidgetPickerSheet" not in s:
        s = rep(
            s,
            "import '../shared/components/ethiocal_logo.dart';\n",
            "import '../shared/components/ethiocal_logo.dart';\n"
            "import '../shared/components/widget_management_dialog.dart';\n",
            path=rel,
        )
    if "nav_home_widgets" not in s.split("_jumpToToday")[0][-800:]:
        s = rep(
            s,
            """                  _NavRow(
                    icon: Icons.today_rounded,
                    title: t('jump_to_today'),
                    subtitle: t('jump_to_today_sub'),
                    onTap: () => _jumpToToday(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_notifications')),""",
            """                  _NavRow(
                    icon: Icons.today_rounded,
                    title: t('jump_to_today'),
                    subtitle: t('jump_to_today_sub'),
                    onTap: () => _jumpToToday(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.widgets_rounded,
                    title: t('nav_home_widgets'),
                    subtitle: t('home_widgets_sub'),
                    onTap: () => showWidgetPickerSheet(context, lang),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_notifications')),""",
            path=rel,
        )
    save(rel, s)


def localize_calendar() -> None:
    rel = "lib/features/calendar/calendar_home_screen.dart"
    s = load(rel)
    if "date_text.dart" not in s:
        # insert after locale_strings import if present, else after first localization import
        if "import '../../core/localization/locale_strings.dart';" in s:
            s = rep(
                s,
                "import '../../core/localization/locale_strings.dart';\n",
                "import '../../core/localization/date_text.dart';\n"
                "import '../../core/localization/locale_strings.dart';\n",
                path=rel,
            )
        else:
            raise AssertionError("locale_strings import missing")

    # View mode bar → app language + AppSegmented-style labels
    s = rep(
        s,
        """  Widget _buildViewModeBar(String currentMode) {
    final r = AppResponsive(context);
    final isGregPrimary =
        ref.watch(userSettingsProvider.select((s) => s.calendarFormat == 'GREGORIAN'));
    final modes = [
      ('MONTH', !isGregPrimary ? 'ወር' : 'Month', Icons.calendar_view_month_rounded),
      ('WEEK', !isGregPrimary ? 'ሳምንት' : 'Week', Icons.view_week_rounded),
      ('YEAR', !isGregPrimary ? 'ዓመት' : 'Year', Icons.calendar_month_rounded),
      ('DAY', !isGregPrimary ? 'ዕለት' : 'Day', Icons.wb_sunny_outlined),
    ];""",
        """  Widget _buildViewModeBar(String currentMode) {
    final r = AppResponsive(context);
    final lang = ref.watch(currentAppLanguageProvider);
    final modes = [
      ('MONTH', LocaleStrings.get('month_view', lang), Icons.calendar_view_month_rounded),
      ('WEEK', LocaleStrings.get('week_view', lang), Icons.view_week_rounded),
      ('YEAR', LocaleStrings.get('year_view', lang), Icons.calendar_month_rounded),
      ('DAY', LocaleStrings.get('day_view', lang), Icons.wb_sunny_outlined),
    ];""",
        path=rel,
    )

    # Legend
    s = rep(
        s,
        """                  child: Row(
                    children: [
                      _buildLegendItem(
                        AppColors.govHolidayRing,
                        'መንግሥት',
                        ring: true,
                      ),
                      SizedBox(width: 8),
                      _buildLegendItem(AppColors.ethioIndigoPrimary, 'ባሕረ ሐሳብ'),
                      SizedBox(width: 8),
                      _buildLegendItem(AppColors.ethioGoldPrimary, 'ማስታወሻ'),
                      if (settings.showFasting) ...[
                        SizedBox(width: 8),
                        _buildLegendItem(AppColors.ethioEmerald, 'ጾም'),
                      ],
                      SizedBox(width: 8),
                      _buildLegendItem(AppColors.verifyApproximate, 'እስላማዊ'),
                    ],
                  ),""",
        """                  child: Row(
                    children: [
                      _buildLegendItem(
                        AppColors.govHolidayRing,
                        LocaleStrings.get('legend_public', lang),
                        ring: true,
                      ),
                      SizedBox(width: 8),
                      _buildLegendItem(
                        AppColors.ethioIndigoPrimary,
                        LocaleStrings.get('legend_feast', lang),
                      ),
                      SizedBox(width: 8),
                      _buildLegendItem(
                        AppColors.ethioGoldPrimary,
                        LocaleStrings.get('legend_event', lang),
                      ),
                      if (settings.showFasting) ...[
                        SizedBox(width: 8),
                        _buildLegendItem(
                          AppColors.ethioEmerald,
                          LocaleStrings.get('legend_fast', lang),
                        ),
                      ],
                      SizedBox(width: 8),
                      _buildLegendItem(
                        AppColors.verifyApproximate,
                        LocaleStrings.get('filter_islamic', lang),
                      ),
                    ],
                  ),""",
        path=rel,
    )

    replacements = [
        ("!isGregPrimary ? 'ወር እና ዓመት ይምረጡ' : 'Select Month & Year'",
         "LocaleStrings.get('select_month_year', lang)"),
        ("isGregPrimary ? '$pickerYear' : '$pickerYear ዓ.ም'",
         "isGregPrimary ? '$pickerYear' : DateText.ethiopianYear(pickerYear, lang)"),
        ("!isGregPrimary ? 'ዛሬ' : 'Today'",
         "LocaleStrings.get('today', lang)", 4),
        ("!isGregPrimary ? '$days ቀናት' : '$days days'",
         "LocaleStrings.format('days_count', lang, {'count': '$days'})"),
        ("!isGregPrimary ? 'ወደ ዛሬ ተመለስ' : 'Go to Today'",
         "LocaleStrings.get('go_to_today', lang)"),
        ("!isGregPrimary ? 'ቀን ምረጥ' : 'Pick Date'",
         "LocaleStrings.get('pick_date', lang)"),
        ("!isGregPrimary ? 'ወደ ዛሬ' : 'Go to Today'",
         "LocaleStrings.get('go_to_today', lang)"),
        ("!isGregPrimary ? 'የዕለቱ ዝርዝር' : 'Day details'",
         "LocaleStrings.get('day_details', lang)"),
        ("!isGregPrimary ? 'አጋራ' : 'Share'",
         "LocaleStrings.get('share', lang)"),
        ("(!isGregPrimary ? 'ፍስክ ቀን' : 'Regular Day')",
         "LocaleStrings.get('regular_day', lang)", 2),
        ("!isGregPrimary ? 'የዕለቱ ማስታወሻዎች' : 'Events & Notes'",
         "LocaleStrings.get('events_notes', lang)"),
        ("!isGregPrimary ? 'አክል' : 'Add'",
         "LocaleStrings.get('add', lang)"),
        ("(!isGregPrimary ? 'ሙሉ ቀን' : 'All Day')",
         "LocaleStrings.get('all_day', lang)"),
        ("!isGregPrimary ? 'ሙሉ ቀን' : 'All day'",
         "LocaleStrings.get('all_day', lang)"),
        ("isGreg ? 'Holidays this month' : 'የዚህ ወር በዓላት'",
         "LocaleStrings.get('holidays_this_month', lang)"),
        ("!isGregPrimary ? 'ጾም' : 'Fast'",
         "LocaleStrings.get('legend_fast', lang)"),
        ("!isGregPrimary ? 'የቀኑ የሰዓታት መርሃ-ግብር' : 'Traditional 24h timeline'",
         "LocaleStrings.get('hours_of_day', lang)"),
        ("isNow ? (!isGregPrimary ? 'አሁን' : 'Now') : '—'",
         "isNow ? LocaleStrings.get('now', lang) : '—'"),
        ("!isGregPrimary ? 'ዛሬ' : 'TODAY'",
         "LocaleStrings.get('today', lang)"),
        # FAB icon color
        ("child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),",
         "child: Icon(Icons.add_rounded, color: AppColors.onAccent, size: 28),"),
        ("content: Text(isGreg ? 'Event deleted' : 'ማስታወሻ ተሰርዟል'),",
         "content: Text(LocaleStrings.get('event_deleted', lang)),"),
        ("label: isGreg ? 'UNDO' : 'መልስ',",
         "label: LocaleStrings.get('undo', lang),"),
    ]

    for item in replacements:
        if len(item) == 2:
            old, new = item
            count = 1
        else:
            old, new, count = item
        c = s.count(old)
        if c == 0:
            print("SKIP missing:", old[:70])
            continue
        if c != count and count == 1 and c > 1:
            # replace all when we didn't specify and multiple exist for same pattern
            s = s.replace(old, new)
            print("replaced all", c, ":", old[:50])
        else:
            assert c == count, (old[:70], c, count)
            s = s.replace(old, new)
            print("replaced", count, ":", old[:50])

    # Weekday initials should use DateText / LocaleStrings language, not hard Amharic
    s = rep(
        s,
        """      ? ['እ', 'ሰ', 'ማ', 'ረ', 'ሐ', 'ዓ', 'ቅ']""",
        """      ? [
              DateText.weekdayInitial(7, lang),
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
            ]""",
        path=rel,
        count=1,
    )
    s = rep(
        s,
        """      ? ['ሰ', 'ማ', 'ረ', 'ሐ', 'ዓ', 'ቅ', 'እ']""",
        """      ? [
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
              DateText.weekdayInitial(7, lang),
            ]""",
        path=rel,
        count=1,
    )

    # Holiday titles / saint names via DateText where clear
    s = s.replace(
        "isGreg ? holiday.titleEnglish : holiday.titleAmharic",
        "DateText.holidayTitle(holiday, lang)",
    )
    s = s.replace(
        "!isGregPrimary ? h.titleAmharic : h.titleEnglish",
        "DateText.holidayTitle(h, lang)",
    )

    save(rel, s)


def fix_football_light() -> None:
    rel = "lib/features/football/football_screen.dart"
    s = load(rel)
    s = rep(
        s,
        """    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0C1220),
            Color(0xFF151B28),
            Color(0xFF1A2333),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF0D6B4C), Color(0xFF078930)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF078930).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.sports_soccer_rounded,
                color: Colors.white, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Football',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),""",
        """    final isDark = AppColors.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0C1220),
                  Color(0xFF151B28),
                  Color(0xFF1A2333),
                ]
              : [
                  AppColors.surface,
                  AppColors.surfaceElevated,
                  AppColors.surface,
                ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.accentDeep,
                  AppColors.accent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(Icons.sports_soccer_rounded,
                color: AppColors.onAccent, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Football',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                ),""",
        path=rel,
    )
    save(rel, s)


def polish_events_screen() -> None:
    rel = "lib/features/events/events_screen.dart"
    s = load(rel)
    # Dynamic categories from locale
    s = rep(
        s,
        """  static const _categories = [
    _Cat('ALL', 'All', Icons.apps_rounded),
    _Cat('TASK', 'Tasks', Icons.check_circle_outline_rounded),
    _Cat('MEETING', 'Meetings', Icons.groups_rounded),
    _Cat('BIRTHDAY', 'Birthdays', Icons.cake_rounded),
    _Cat('EXAM', 'Exams', Icons.school_rounded),
    _Cat('ANNIVERSARY', 'Anniversaries', Icons.favorite_border_rounded),
    _Cat('RELIGIOUS', 'Religious', Icons.temple_buddhist_rounded),
    _Cat('CULTURAL', 'Cultural', Icons.public_rounded),
    _Cat('OTHER', 'Other', Icons.more_horiz_rounded),
  ];""",
        """  List<_Cat> _categoriesFor(AppLanguage lang) => [
        _Cat('ALL', LocaleStrings.get('cat_all', lang), Icons.apps_rounded),
        _Cat('TASK', LocaleStrings.get('cat_task', lang), Icons.check_circle_outline_rounded),
        _Cat('MEETING', LocaleStrings.get('cat_meeting', lang), Icons.groups_rounded),
        _Cat('BIRTHDAY', LocaleStrings.get('cat_birthday', lang), Icons.cake_rounded),
        _Cat('EXAM', LocaleStrings.get('cat_exam', lang), Icons.school_rounded),
        _Cat(
          'ANNIVERSARY',
          LocaleStrings.get('cat_anniversary', lang),
          Icons.favorite_border_rounded,
        ),
        _Cat('RELIGIOUS', LocaleStrings.get('cat_religious', lang), Icons.temple_buddhist_rounded),
        _Cat('CULTURAL', LocaleStrings.get('cat_cultural', lang), Icons.public_rounded),
        _Cat('OTHER', LocaleStrings.get('cat_other', lang), Icons.more_horiz_rounded),
      ];""",
        path=rel,
    )
    if "import '../../core/localization/app_language.dart';" not in s:
        s = rep(
            s,
            "import '../../core/localization/locale_strings.dart';\n",
            "import '../../core/localization/app_language.dart';\n"
            "import '../../core/localization/locale_strings.dart';\n",
            path=rel,
        )
    # Use categories list in build
    if "_categoriesFor(lang)" not in s:
        # Find where _categories is iterated
        if "for (final cat in _categories)" in s:
            s = s.replace("for (final cat in _categories)", "for (final cat in _categoriesFor(lang))")
        elif "_categories.map" in s:
            s = s.replace("_categories.map", "_categoriesFor(lang).map")
        else:
            # insert near start of build after lang
            s = rep(
                s,
                "    final lang = ref.watch(currentAppLanguageProvider);\n",
                "    final lang = ref.watch(currentAppLanguageProvider);\n"
                "    final categories = _categoriesFor(lang);\n",
                path=rel,
            )
            s = s.replace("_categories", "categories")
            # undo accidental rename of method
            s = s.replace("List<_Cat> categoriesFor", "List<_Cat> _categoriesFor")
            s = s.replace("_categoriesFor(lang)", "_categoriesFor(lang)")  # noop safety

    s = s.replace("label: 'Open',", "label: LocaleStrings.get('stat_open', lang),")
    s = s.replace("label: 'Done',", "label: LocaleStrings.get('stat_done', lang),")
    s = s.replace("label: 'Total',", "label: LocaleStrings.get('stat_total', lang),")
    s = s.replace(
        "color: const Color(0xFFFF6B6B),",
        "color: AppColors.accent,",
        1,
    )
    s = s.replace(
        "color: const Color(0xFF1FA87A),",
        "color: AppColors.ethioEmerald,",
        1,
    )
    s = s.replace(
        "color: const Color(0xFF6CABDD),",
        "color: AppColors.ethioIndigoPrimary,",
        1,
    )
    # Empty state hardcodes
    s = s.replace(
        "hasAny ? 'No matching events' : 'No events yet'",
        "hasAny\n                  ? LocaleStrings.get('no_matching_events', lang)\n                  : LocaleStrings.get('no_events_yet', lang)",
    )
    # _EmptyEvents needs lang - check constructor
    if "required this.onAdd" in s and "final AppLanguage lang" not in s.split("class _EmptyEvents")[1][:400]:
        s = rep(
            s,
            """class _EmptyEvents extends StatelessWidget {
  final bool hasAny;
  final VoidCallback onAdd;
  const _EmptyEvents({required this.hasAny, required this.onAdd});""",
            """class _EmptyEvents extends StatelessWidget {
  final bool hasAny;
  final VoidCallback onAdd;
  final AppLanguage lang;
  const _EmptyEvents({required this.hasAny, required this.onAdd, required this.lang});""",
            path=rel,
        )
        s = s.replace(
            "_EmptyEvents(\n",
            "_EmptyEvents(\n                  lang: lang,\n",
        )
        # empty sub + add button
        s = s.replace(
            """              hasAny
                  ? 'Try another search or category'
                  : 'Tap + to add your first reminder, meeting, or birthday',""",
            """              hasAny
                  ? LocaleStrings.get('try_another_search', lang)
                  : LocaleStrings.get('events_empty_sub', lang),""",
        )
        s = s.replace(
            "label: Text('Add event', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),",
            "label: Text(LocaleStrings.get('add_event', lang), style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AppColors.onAccent)),",
        )
        s = s.replace(
            "color: Colors.white,",
            "color: AppColors.textPrimary,",
            1,
        )
    # Search field / hard dark colors → theme
    s = s.replace(
        "style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),",
        "style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),",
    )
    s = s.replace("color: const Color(0xFF171A21)", "color: AppColors.surfaceElevated")
    s = s.replace("color: const Color(0xFF2A2F3A)", "color: AppColors.surfaceBorder")
    s = s.replace("color: const Color(0xFF7A8496)", "color: AppColors.textTertiary")
    s = s.replace("color: const Color(0xFFB8C0D0)", "color: AppColors.textSecondary")
    s = s.replace("color: const Color(0xFF8B93A3)", "color: AppColors.textSecondary")
    s = s.replace("color: const Color(0xFF6B7385)", "color: AppColors.textTertiary")
    s = s.replace("color: Color(0xFF8B93A3)", "color: AppColors.textSecondary")
    save(rel, s)


def update_tests() -> None:
    for rel, old, new in (
        (
            "test/e2e_app_journey_test.dart",
            "'Converter',\n      'Agenda',\n",
            "'Converter',\n",
        ),
        (
            "test/e2e_app_journey_test.dart",
            "'Events',\n      'Football',",
            "'Events',\n      'Football',",  # keep Events
        ),
        (
            "test/calendar_strict_e2e_test.dart",
            "const labels = ['Converter', 'Agenda', 'Holidays', 'Events', 'Football'];",
            "const labels = ['Converter', 'Holidays', 'Events', 'Football'];",
        ),
    ):
        s = load(rel)
        if old in s and old != new:
            s = s.replace(old, new)
            # Also remove Agenda from list if still present as alone
            s = s.replace("'Agenda',\n", "")
            s = s.replace(", 'Agenda'", "")
            save(rel, s)
        else:
            s2 = s.replace("'Agenda',\n", "").replace(", 'Agenda'", "")
            if s2 != s:
                save(rel, s2)
            else:
                print("tests already ok", rel)


def ensure_go_to_today_key() -> None:
    rel = "lib/core/localization/locale_strings.dart"
    s = load(rel)
    if "'go_to_today'" in s and "'today':" in s:
        print("keys present")
        return
    # Minimal insert into english/amharic/french maps if missing
    inserts = {
        "_englishMap": {
            "go_to_today": "Go to Today",
            "today": "Today",
        },
        "_amharicMap": {
            "go_to_today": "ወደ ዛሬ",
            "today": "ዛሬ",
        },
        "_frenchMap": {
            "go_to_today": "Aller à aujourd'hui",
            "today": "Aujourd'hui",
        },
    }
    for map_name, keys in inserts.items():
        start = s.index(f"static const Map<String, String> {map_name} = {{")
        end = s.index("\n  };", start)
        body = s[start:end]
        add = []
        for k, v in keys.items():
            if f"'{k}':" not in body:
                esc = v.replace("\\", "\\\\").replace("'", "\\'")
                add.append(f"    '{k}': '{esc}',")
        if add:
            s = s[:end] + "\n" + "\n".join(add) + s[end:]
    save(rel, s)


def main() -> None:
    fix_app_fonts()
    fix_app_theme_and_chrome()
    ensure_go_to_today_key()
    wire_events_hub()
    settings_widgets_row()
    localize_calendar()
    fix_football_light()
    polish_events_screen()
    update_tests()
    print("DONE")


if __name__ == "__main__":
    main()
