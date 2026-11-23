# -*- coding: utf-8 -*-
"""Continue UI pass: fonts, calendar i18n, football, events, tests."""
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


def rep(s: str, old: str, new: str, count: int | None = 1, path: str = "") -> str:
    c = s.count(old)
    if count is None:
        if c == 0:
            print("SKIP", path, old[:60])
            return s
        return s.replace(old, new)
    assert c == count, (path, old[:80], c, count)
    return s.replace(old, new)


def fix_chrome_and_main_fonts() -> None:
    # app_chrome: move fallbacks to copyWith
    rel = "lib/features/shared/components/app_chrome.dart"
    s = load(rel)
    s = re.sub(
        r"GoogleFonts\.outfit\(\n(?P<body>(?:.*\n)*?)\s*fontFamilyFallback: fontFallbacks,\n\s*\)",
        lambda m: "GoogleFonts.outfit(\n"
        + re.sub(r",\n$", "\n", m.group("body").rstrip() + "\n")
        + "      ).copyWith(fontFamilyFallback: fontFallbacks)",
        s,
    )
    # Clean possible double commas from trailing commas before )
    s = s.replace(",\n      ).copyWith", "\n      ).copyWith")
    save(rel, s)

    rel = "lib/main.dart"
    s = load(rel)
    s = re.sub(
        r"GoogleFonts\.outfit\(\n(?P<body>(?:.*\n)*?)\s*fontFamilyFallback: AppTheme\.ethiopicFontFallbacks,\n\s*\)",
        lambda m: "GoogleFonts.outfit(\n"
        + re.sub(r",\n$", "\n", m.group("body").rstrip() + "\n")
        + "                            ).copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks)",
        s,
    )
    s = s.replace(",\n                            ).copyWith", "\n                            ).copyWith")
    # AnimatedDefaultTextStyle case may differ in indent
    s = re.sub(
        r"(style: GoogleFonts\.outfit\(\n(?:.*\n)*?)\s*fontFamilyFallback: AppTheme\.ethiopicFontFallbacks,\n(\s*)\)",
        lambda m: m.group(1).rstrip().rstrip(",")
        + "\n"
        + m.group(2)
        + ").copyWith(fontFamilyFallback: AppTheme.ethiopicFontFallbacks)",
        s,
    )
    save(rel, s)


def localize_calendar() -> None:
    rel = "lib/features/calendar/calendar_home_screen.dart"
    s = load(rel)
    if "date_text.dart" not in s:
        s = rep(
            s,
            "import '../../core/localization/locale_strings.dart';\n",
            "import '../../core/localization/date_text.dart';\n"
            "import '../../core/localization/locale_strings.dart';\n",
            path=rel,
        )

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

    s = rep(
        s,
        """                      _buildLegendItem(
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
                      _buildLegendItem(AppColors.verifyApproximate, 'እስላማዊ'),""",
        """                      _buildLegendItem(
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
                      ),""",
        path=rel,
    )

    pairs = [
        ("!isGregPrimary ? 'ወር እና ዓመት ይምረጡ' : 'Select Month & Year'",
         "LocaleStrings.get('select_month_year', lang)"),
        ("isGregPrimary ? '$pickerYear' : '$pickerYear ዓ.ም'",
         "isGregPrimary ? '$pickerYear' : DateText.ethiopianYear(pickerYear, lang)"),
        ("!isGregPrimary ? 'ዛሬ' : 'Today'",
         "LocaleStrings.get('today', lang)"),
        ("!isGregPrimary ? 'ዛሬ' : 'TODAY'",
         "LocaleStrings.get('today', lang)"),
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
         "LocaleStrings.get('regular_day', lang)"),
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
        ("child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),",
         "child: Icon(Icons.add_rounded, color: AppColors.onAccent, size: 28),"),
        ("content: Text(isGreg ? 'Event deleted' : 'ማስታወሻ ተሰርዟል'),",
         "content: Text(LocaleStrings.get('event_deleted', lang)),"),
        ("label: isGreg ? 'UNDO' : 'መልስ',",
         "label: LocaleStrings.get('undo', lang),"),
        ("? ['እ', 'ሰ', 'ማ', 'ረ', 'ሐ', 'ዓ', 'ቅ']",
         """? [
              DateText.weekdayInitial(7, lang),
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
            ]"""),
        ("? ['ሰ', 'ማ', 'ረ', 'ሐ', 'ዓ', 'ቅ', 'እ']",
         """? [
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
              DateText.weekdayInitial(7, lang),
            ]"""),
        ("isGreg ? holiday.titleEnglish : holiday.titleAmharic",
         "DateText.holidayTitle(holiday, lang)"),
        ("!isGregPrimary ? h.titleAmharic : h.titleEnglish",
         "DateText.holidayTitle(h, lang)"),
    ]
    for old, new in pairs:
        c = s.count(old)
        if c == 0:
            print("SKIP", old[:60])
            continue
        s = s.replace(old, new)
        print("ok", c, old[:40])

    # Year title ዓ.ም
    s = s.replace(
        "title = '$viewYear ዓ.ም';",
        "title = DateText.ethiopianYear(viewYear, lang);",
    )

    save(rel, s)


def fix_football() -> None:
    rel = "lib/features/football/football_screen.dart"
    s = load(rel)
    if "final isDark = AppColors.isDark;" in s:
        print("football already patched")
        return
    old = """    return Container(
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
          ),"""
    new = """    final isDark = AppColors.isDark;
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
          ),"""
    s = rep(s, old, new, path=rel)
    save(rel, s)


def polish_events() -> None:
    rel = "lib/features/events/events_screen.dart"
    s = load(rel)
    if "import '../../core/localization/app_language.dart';" not in s:
        s = rep(
            s,
            "import '../../core/localization/locale_strings.dart';\n",
            "import '../../core/localization/app_language.dart';\n"
            "import '../../core/localization/locale_strings.dart';\n",
            path=rel,
        )
    if "List<_Cat> _categoriesFor" not in s:
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
    # Fix _categoryLabel helper that uses _categories
    s = s.replace(
        """    return _categories
        .firstWhere((c) => c.id == id, orElse: () => _categories.last)
""",
        """    final cats = _categoriesFor(ref.read(currentAppLanguageProvider));
    return cats
        .firstWhere((c) => c.id == id, orElse: () => cats.last)
""",
    )
    s = s.replace(
        "    final lang = ref.watch(currentAppLanguageProvider);\n",
        "    final lang = ref.watch(currentAppLanguageProvider);\n"
        "    final categories = _categoriesFor(lang);\n",
        1,
    )
    s = s.replace("itemCount: _categories.length,", "itemCount: categories.length,")
    s = s.replace("final cat = _categories[i];", "final cat = categories[i];")

    s = s.replace("label: 'Open',", "label: LocaleStrings.get('stat_open', lang),")
    s = s.replace("label: 'Done',", "label: LocaleStrings.get('stat_done', lang),")
    s = s.replace("label: 'Total',", "label: LocaleStrings.get('stat_total', lang),")
    s = s.replace("color: const Color(0xFFFF6B6B),", "color: AppColors.accent,", 1)
    s = s.replace("color: const Color(0xFF1FA87A),", "color: AppColors.ethioEmerald,", 1)
    s = s.replace("color: const Color(0xFF6CABDD),", "color: AppColors.ethioIndigoPrimary,", 1)

    if "required this.lang" not in s.split("class _EmptyEvents")[1][:350]:
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
            "? _EmptyEvents(\n",
            "? _EmptyEvents(\n                  lang: lang,\n",
        )
        s = s.replace(
            "hasAny ? 'No matching events' : 'No events yet'",
            "hasAny\n                  ? LocaleStrings.get('no_matching_events', lang)\n                  : LocaleStrings.get('no_events_yet', lang)",
        )
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
        # title color in empty
        s = s.replace(
            """            Text(
              hasAny
                  ? LocaleStrings.get('no_matching_events', lang)
                  : LocaleStrings.get('no_events_yet', lang),
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),""",
            """            Text(
              hasAny
                  ? LocaleStrings.get('no_matching_events', lang)
                  : LocaleStrings.get('no_events_yet', lang),
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),""",
        )

    s = s.replace(
        "style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),",
        "style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),",
    )
    for a, b in [
        ("color: const Color(0xFF171A21)", "color: AppColors.surfaceElevated"),
        ("color: const Color(0xFF2A2F3A)", "color: AppColors.surfaceBorder"),
        ("color: const Color(0xFF7A8496)", "color: AppColors.textTertiary"),
        ("color: const Color(0xFFB8C0D0)", "color: AppColors.textSecondary"),
        ("color: const Color(0xFF8B93A3)", "color: AppColors.textSecondary"),
        ("color: const Color(0xFF6B7385)", "color: AppColors.textTertiary"),
        ("color: Color(0xFF8B93A3)", "color: AppColors.textSecondary"),
    ]:
        s = s.replace(a, b)
    save(rel, s)


def update_tests() -> None:
    for rel in ("test/e2e_app_journey_test.dart", "test/calendar_strict_e2e_test.dart"):
        s = load(rel)
        s2 = s.replace("'Agenda',\n", "").replace(", 'Agenda'", "").replace("'Agenda', ", "")
        if s2 != s:
            save(rel, s2)
        else:
            print("tests ok", rel)


def ensure_settings_import_lang() -> None:
    rel = "lib/features/settings/settings_screen.dart"
    s = load(rel)
    if "widget_management_dialog.dart" not in s:
        s = rep(
            s,
            "import '../shared/components/ethiocal_logo.dart';\n",
            "import '../shared/components/ethiocal_logo.dart';\n"
            "import '../shared/components/widget_management_dialog.dart';\n",
            path=rel,
        )
        save(rel, s)
    else:
        print("settings import ok")


def main() -> None:
    fix_chrome_and_main_fonts()
    ensure_settings_import_lang()
    localize_calendar()
    fix_football()
    polish_events()
    update_tests()
    print("DONE")


if __name__ == "__main__":
    main()
