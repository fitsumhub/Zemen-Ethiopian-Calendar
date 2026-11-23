import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/calendar/ethiopian_season.dart';
import '../../core/calendar/geez_numeral.dart';
import '../../core/calendar/gregorian_date.dart';
import '../../core/calendar/leap_year_calculator.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/share_helper.dart';
import '../shared/providers.dart';
import 'tabs/age_difference_tab.dart';
import 'tabs/bahire_hasab_tab.dart';
import 'tabs/country_comparator_tab.dart';
import 'tabs/geez_numerals_tab.dart';
import 'tabs/time_converter_tab.dart';

const _gregMonths = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Converter: [Convert | Age | Date Math] on unified dark canvas.
/// Select Date card, wheel pickers, RESULT card — AppColors.
class ConverterHomeScreen extends ConsumerStatefulWidget {
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const ConverterHomeScreen({super.key, this.onNavigateToCalendar});

  @override
  ConsumerState<ConverterHomeScreen> createState() =>
      _ConverterHomeScreenState();
}

class _ConverterHomeScreenState extends ConsumerState<ConverterHomeScreen> {
  int _mode = 0; // 0 Convert, 1 Age, 2 Date Math
  bool _isEthiopian = true;

  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _yearCtrl;

  int _ethMonth = 3;
  int _ethDay = 6;
  int _ethYear = 2019;
  int _gregMonth = 11;
  int _gregDay = 15;
  int _gregYear = 2026;

  @override
  void initState() {
    super.initState();
    final eth = EthiopianCalendarEngine.todayEthiopian();
    final greg = EthiopianCalendarEngine.todayGregorian();
    _ethMonth = eth.month;
    _ethDay = eth.day;
    _ethYear = eth.year;
    _gregMonth = greg.month;
    _gregDay = greg.day;
    _gregYear = greg.year;
    _monthCtrl = FixedExtentScrollController(initialItem: _ethMonth - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _ethDay - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _ethYear - 1900);
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _setDirection(bool ethiopian) {
    if (_isEthiopian == ethiopian) return;
    setState(() {
      if (_isEthiopian) {
        // Sync Gregorian picker to current converted Gregorian date
        final g = EthiopianCalendarEngine.toGregorian(
            EthiopianDate(_ethYear, _ethMonth, _ethDay));
        _gregYear = g.year;
        _gregMonth = g.month;
        _gregDay = g.day;
      } else {
        // Sync Ethiopian picker to current converted Ethiopian date
        final e = EthiopianCalendarEngine.toEthiopian(
            GregorianDate(_gregYear, _gregMonth, _gregDay));
        _ethYear = e.year;
        _ethMonth = e.month;
        _ethDay = e.day;
      }
      _isEthiopian = ethiopian;
      _clampSelectedDay();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_monthCtrl.hasClients) {
        _monthCtrl.jumpToItem((_isEthiopian ? _ethMonth : _gregMonth) - 1);
      }
      if (_dayCtrl.hasClients) {
        _dayCtrl.jumpToItem((_isEthiopian ? _ethDay : _gregDay) - 1);
      }
      if (_yearCtrl.hasClients) {
        _yearCtrl.jumpToItem(
            ((_isEthiopian ? _ethYear : _gregYear) - 1900).clamp(0, 199));
      }
    });
  }

  /// Keeps day within the selected month (critical for Pagume 5/6 days).
  void _clampSelectedDay() {
    if (_isEthiopian) {
      final max = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
      if (_ethDay > max) _ethDay = max;
    } else {
      final max = DateTime(_gregYear, _gregMonth + 1, 0).day;
      if (_gregDay > max) _gregDay = max;
    }
  }

  void _onMonthChanged(int index) {
    setState(() {
      if (_isEthiopian) {
        _ethMonth = index + 1;
      } else {
        _gregMonth = index + 1;
      }
      final before = _isEthiopian ? _ethDay : _gregDay;
      _clampSelectedDay();
      final after = _isEthiopian ? _ethDay : _gregDay;
      if (after != before && _dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(after - 1);
      }
    });
  }

  void _onYearChanged(int index) {
    setState(() {
      if (_isEthiopian) {
        _ethYear = 1900 + index;
      } else {
        _gregYear = 1900 + index;
      }
      final before = _isEthiopian ? _ethDay : _gregDay;
      _clampSelectedDay();
      final after = _isEthiopian ? _ethDay : _gregDay;
      if (after != before && _dayCtrl.hasClients) {
        _dayCtrl.jumpToItem(after - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentAppLanguageProvider);

    if (_mode == 1 || _mode == 2) {
      return ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _modeBar(),
            ),
            Expanded(
              child: AgeAndDifferenceTab(
                currentLang: lang,
                initialMode: _mode == 1 ? 0 : 1,
                hideModeSwitcher: true,
              ),
            ),
          ],
        ),
      );
    }

    if (_mode == 3) {
      return ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _modeBar(),
            ),
            Expanded(
              child: BahireHasabTab(currentLang: lang),
            ),
          ],
        ),
      );
    }

    if (_mode == 4) {
      return ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _modeBar(),
            ),
            Expanded(
              child: GeezNumeralsTab(),
            ),
          ],
        ),
      );
    }

    if (_mode == 5) {
      return ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _modeBar(),
            ),
            const Expanded(
              child: TimeConverterTab(),
            ),
          ],
        ),
      );
    }

    if (_mode == 6) {
      return ColoredBox(
        color: AppColors.canvas,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _modeBar(),
            ),
            const Expanded(
              child: CountryComparatorTab(),
            ),
          ],
        ),
      );
    }

    // Conversion logic — use clamped locals (state is clamped on picker change).
    var ethY = _ethYear;
    var ethM = _ethMonth;
    var ethD = _ethDay;
    var gregY = _gregYear;
    var gregM = _gregMonth;
    var gregD = _gregDay;

    final maxDays = _isEthiopian
        ? EthiopianDate.daysInMonthFor(ethY, ethM)
        : DateTime(gregY, gregM + 1, 0).day;
    if (_isEthiopian && ethD > maxDays) ethD = maxDays;
    if (!_isEthiopian && gregD > maxDays) gregD = maxDays;

    String? conversionError;
    try {
      if (_isEthiopian) {
        final g = EthiopianCalendarEngine.toGregorian(
            EthiopianDate(ethY, ethM, ethD));
        gregY = g.year;
        gregM = g.month;
        gregD = g.day;
      } else {
        final e = EthiopianCalendarEngine.toEthiopian(
            GregorianDate(gregY, gregM, gregD));
        ethY = e.year;
        ethM = e.month;
        ethD = e.day;
      }
    } catch (e) {
      conversionError = e.toString();
    }

    final ethDate = EthiopianDate(ethY, ethM, ethD);
    final dow = EthiopianCalendarEngine.getDayOfWeek(ethDate);
    final weekday = LocaleStrings.weekdaysEnglishLong[dow - 1];
    final isToday = ethDate == EthiopianCalendarEngine.todayEthiopian();
    final evangelist = LeapYearCalculator.getEvangelist(ethY);
    final ethSeason = EthiopianSeason.fromMonth(ethM);

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                // —— Mode Bar: [Convert | Age | Date Math ...] ——
                _modeBar(),
                const SizedBox(height: 16),

                // —— Select Date Card ——
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.isDark
                            ? const Color(0x18000000)
                            : const Color(0x06000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Date · ቀን ይምረጡ',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Ethiopian / Gregorian Segmented Toggle
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _setDirection(true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: _isEthiopian
                                        ? AppColors.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    border: _isEthiopian
                                        ? Border.all(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.35),
                                          )
                                        : null,
                                    boxShadow: _isEthiopian
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x12000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '🇪🇹 Ethiopian',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: _isEthiopian
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _isEthiopian
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _setDirection(false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  decoration: BoxDecoration(
                                    color: !_isEthiopian
                                        ? AppColors.surface
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    border: !_isEthiopian
                                        ? Border.all(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.35),
                                          )
                                        : null,
                                    boxShadow: !_isEthiopian
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x12000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 1),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '🌍 Gregorian',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: !_isEthiopian
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: !_isEthiopian
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3-Wheel Scroll Date Picker
                      SizedBox(
                        height: 180,
                        child: Row(
                          children: [
                            // Month Wheel
                            Expanded(
                              flex: 4,
                              child: CupertinoPicker.builder(
                                scrollController: _monthCtrl,
                                itemExtent: 38,
                                selectionOverlay: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.symmetric(
                                      horizontal: BorderSide(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                onSelectedItemChanged: _onMonthChanged,
                                childCount: _isEthiopian ? 13 : 12,
                                itemBuilder: (context, i) {
                                  final name = _isEthiopian
                                      ? LocaleStrings.getMonthName(i + 1, lang)
                                      : _gregMonths[i];
                                  final isSel = i ==
                                      (_isEthiopian
                                          ? _ethMonth - 1
                                          : _gregMonth - 1);
                                  return Center(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.outfit(
                                        fontSize: isSel ? 16 : 14,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Day Wheel
                            Expanded(
                              flex: 2,
                              child: CupertinoPicker.builder(
                                scrollController: _dayCtrl,
                                itemExtent: 38,
                                selectionOverlay: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.symmetric(
                                      horizontal: BorderSide(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                onSelectedItemChanged: (i) {
                                  setState(() {
                                    if (_isEthiopian) {
                                      _ethDay = i + 1;
                                    } else {
                                      _gregDay = i + 1;
                                    }
                                  });
                                },
                                childCount: maxDays,
                                itemBuilder: (context, i) {
                                  final isSel = i ==
                                      (_isEthiopian
                                          ? _ethDay - 1
                                          : _gregDay - 1);
                                  return Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: GoogleFonts.outfit(
                                        fontSize: isSel ? 18 : 14,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Year Wheel
                            Expanded(
                              flex: 3,
                              child: CupertinoPicker.builder(
                                scrollController: _yearCtrl,
                                itemExtent: 38,
                                selectionOverlay: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.symmetric(
                                      horizontal: BorderSide(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                                onSelectedItemChanged: _onYearChanged,
                                childCount: 200,
                                itemBuilder: (context, i) {
                                  final y = 1900 + i;
                                  final isSel = y ==
                                      (_isEthiopian ? _ethYear : _gregYear);
                                  return Center(
                                    child: Text(
                                      '$y',
                                      style: GoogleFonts.outfit(
                                        fontSize: isSel ? 18 : 14,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? AppColors.textPrimary
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // —— RESULT / ERROR Card ——
                if (conversionError != null)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ethioRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.ethioRed.withValues(alpha: 0.35),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.ethioRed.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            color: AppColors.ethioRed,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'የቀን ስህተት (Conversion Error)',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ethioRed,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'የተመረጠው ቀን ሊሰላ አልቻለም። እባክዎ ትክክለኛ ቀን ይምረጡ።\n($conversionError)',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.isDark
                              ? const Color(0x20000000)
                              : const Color(0x0A000000),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'RESULT · ውጤት',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.accent.withValues(alpha: 0.14)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.35))
                                    : null,
                              ),
                              child: Text(
                                isToday ? 'ዛሬ (Today)' : 'የተቀየረበት ቀን',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isToday
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isEthiopian
                              ? '$weekday, ${_gregMonths[gregM - 1]} $gregD, $gregY G.C.'
                              : '$weekday፣ ${LocaleStrings.getMonthName(ethM, lang)} $ethD $ethY ዓ.ም',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isEthiopian
                              ? 'ምንጭ: 🇪🇹 ${LocaleStrings.getMonthName(ethM, lang)} $ethD $ethY ዓ.ም (ግዕዝ: ${GeezNumeral.toGeez(ethD)}) • ወቅት: ${ethSeason.amharicName}'
                              : 'ግዕዝ: ${GeezNumeral.toGeez(ethD)}/${GeezNumeral.toGeez(ethM)}/${GeezNumeral.toGeez(ethY)} ዓ.ም • ወንጌላዊ: ${evangelist.amharicName} • ወቅት: ${ethSeason.amharicName}',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: Text(
                                  'ኮፒ (Copy)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(
                                      color: AppColors.surfaceBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () {
                                  final text = _isEthiopian
                                      ? '$gregD ${_gregMonths[gregM - 1]} $gregY G.C.'
                                      : '$ethD ${LocaleStrings.getMonthName(ethM, lang)} $ethY ዓ.ም';
                                  Clipboard.setData(ClipboardData(text: text));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('ቀኑ ኮፒ ተደርጓል (Date copied)'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.share_rounded, size: 16),
                                label: Text(
                                  'አጋራ (Share)',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: BorderSide(
                                      color: AppColors.surfaceBorder),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                onPressed: () {
                                  final text = _isEthiopian
                                      ? '🇪🇹 $ethD ${LocaleStrings.getMonthName(ethM, lang)} $ethY ዓ.ም ➔ 🌍 $gregD ${_gregMonths[gregM - 1]} $gregY G.C.'
                                      : '🌍 $gregD ${_gregMonths[gregM - 1]} $gregY G.C. ➔ 🇪🇹 $ethD ${LocaleStrings.getMonthName(ethM, lang)} $ethY ዓ.ም';
                                  ShareHelper.share(
                                      '$text\n\n— ከዘመን የቀን መቁጠሪያ (Zemen: Ethiopian Calendar)');
                                },
                              ),
                            ),
                            if (widget.onNavigateToCalendar != null) ...[
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.calendar_month_rounded,
                                    size: 19),
                                tooltip: 'በካላንደር እይ (View in Calendar)',
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      AppColors.accent.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.accent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  widget.onNavigateToCalendar?.call(ethDate);
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modePill(0, 'Convert (ቀን)'),
            _modePill(1, 'Age (ዕድሜ)'),
            _modePill(2, 'Math (ልዩነት)'),
            _modePill(3, 'Computus (ባሕረ ሐሳብ)'),
            _modePill(4, 'Ge\'ez (ግዕዝ)'),
            _modePill(5, 'Time (ሰዓት)'),
            _modePill(6, 'World (ዓለም)'),
          ],
        ),
      ),
    );
  }

  Widget _modePill(int index, String label) {
    final isSel = _mode == index;
    return GestureDetector(
      onTap: () => setState(() => _mode = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSel ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: isSel
              ? Border.all(
                  color: AppColors.accent.withValues(alpha: 0.45),
                )
              : null,
          boxShadow: isSel
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? AppColors.accent : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

