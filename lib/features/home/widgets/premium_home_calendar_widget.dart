import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/calendar/ethiopian_time_converter.dart';
import '../../../core/calendar/geez_numeral.dart';
import '../../../core/calendar/leap_year_calculator.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/home_widget_engine.dart';
import '../../shared/components/custom_dual_date_picker_dialog.dart';
import '../../shared/components/ethiopian_clock_dialog.dart';
import '../../shared/components/widget_management_dialog.dart';
import '../../shared/providers.dart';

/// A Premium, Information-Rich Home Calendar Widget for Zemen: Ethiopian Calendar.
///
/// Features:
/// - Refined visual hierarchy supporting both Light and Dark themes.
/// - Prominent Ethiopian date, Ge'ez numerals, and Gregorian dual-date anchor.
/// - Live Ethiopian traditional time & standard clock indicator.
/// - Integrated spiritual indicators (Fasting status & Saint of the day).
/// - Intuitive interactive day-stepping navigation (‹ Previous, Today, Next ›).
/// - Quick action shortcuts: Date Picker, Ethiopian Clock, Add Event, Share, Widget Settings.
class PremiumHomeCalendarWidget extends ConsumerStatefulWidget {
  final VoidCallback? onAddEvent;
  final ValueChanged<EthiopianDate>? onDateSelected;

  const PremiumHomeCalendarWidget({
    super.key,
    this.onAddEvent,
    this.onDateSelected,
  });

  @override
  ConsumerState<PremiumHomeCalendarWidget> createState() =>
      _PremiumHomeCalendarWidgetState();
}

class _PremiumHomeCalendarWidgetState
    extends ConsumerState<PremiumHomeCalendarWidget> {
  late EthiopianDate _activeDate;
  int _dayOffset = 0;
  Timer? _liveClockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _activeDate = EthiopianCalendarEngine.todayEthiopian();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    super.dispose();
  }

  void _stepDate(int deltaDays) {
    HapticFeedback.selectionClick();
    setState(() {
      _dayOffset += deltaDays;
      _activeDate = HomeWidgetEngine.shiftDays(_activeDate, deltaDays);
    });
  }

  void _resetToToday() {
    HapticFeedback.mediumImpact();
    setState(() {
      _dayOffset = 0;
      _activeDate = EthiopianCalendarEngine.todayEthiopian();
    });
  }

  void _openDatePicker(AppLanguage lang, String currentFormat) {
    showDialog(
      context: context,
      builder: (_) => CustomDualDatePickerDialog(
        initialDate: _activeDate,
        initialFormat: currentFormat,
        todayEthiopian: EthiopianCalendarEngine.todayEthiopian(),
        currentLang: lang,
        onDateSelected: (selected, format) {
          final today = EthiopianCalendarEngine.todayEthiopian();
          final offset =
              EthiopianCalendarEngine.daysBetween(today, selected);
          setState(() {
            _activeDate = selected;
            _dayOffset = offset;
          });
          ref.read(selectedDateProvider.notifier).state = selected;
          ref.read(viewYearProvider.notifier).state = selected.year;
          ref.read(viewMonthProvider.notifier).state = selected.month;
          widget.onDateSelected?.call(selected);
        },
      ),
    );
  }

  void _openClockDialog() {
    showDialog(
      context: context,
      builder: (_) => const EthiopianClockDialog(),
    );
  }

  void _openWidgetCustomizer(AppLanguage lang) {
    showWidgetPickerSheet(context, lang);
  }

  void _shareDate(HomeWidgetSnapshot s, AppLanguage lang) {
    final text = HomeWidgetEngine.shareText(s, lang: lang);
    ShareHelper.share(text, subject: 'Zemen: Ethiopian Calendar · Date');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lang = ref.watch(currentAppLanguageProvider);
    final settings = ref.watch(userSettingsProvider);

    // Compute calendar attributes for the active date
    final todayEth = ref.watch(todayEthiopianProvider);
    final isToday = _dayOffset == 0 &&
        _activeDate.year == todayEth.year &&
        _activeDate.month == todayEth.month &&
        _activeDate.day == todayEth.day;

    final gregDate = EthiopianCalendarEngine.toGregorian(_activeDate);
    final dow = EthiopianCalendarEngine.getDayOfWeek(_activeDate);
    final monthName = LocaleStrings.getMonthName(_activeDate.month, lang);
    final weekdayName = LocaleStrings.getWeekdayLong(dow, lang);
    final geezDay = GeezNumeral.toGeez(_activeDate.day);
    final geezYear = GeezNumeral.toGeez(_activeDate.year);

    final evangelist = LeapYearCalculator.getEvangelist(_activeDate.year);
    final fastingStatus = HolidayEngine.isFastingDay(_activeDate);
    final saint = HolidayEngine.monthlySaints.firstWhere(
      (s) => s.day == _activeDate.day,
      orElse: () => HolidayEngine.monthlySaints.first,
    );

    // Check if active date is an Ethiopian holiday
    final holidays = HolidayEngine.getHolidaysForDate(_activeDate);
    final holiday = holidays.isNotEmpty ? holidays.first : null;

    final ethTime = EthiopianTimeConverter.gregorianToEthiopian(
      _currentTime.hour,
      _currentTime.minute,
    );

    final snapshot = HomeWidgetEngine.build(
      HomeWidgetKind.classicDate,
      lang: lang,
      forDate: _activeDate,
    );

    // Date status indicator label (Today, Yesterday, Tomorrow, or difference)
    final dateStatusLabel = switch (_dayOffset) {
      0 => 'ዛሬ · Today',
      -1 => 'ትላንት · Yesterday',
      1 => 'ነገ · Tomorrow',
      _ => _dayOffset < 0
          ? '${_dayOffset.abs()} ቀናት በፊት'
          : 'በ $_dayOffset ቀናት ውስጥ',
    };

    // Design Tokens & Colors
    final cardBg = isDark
        ? AppColors.darkCard
        : Colors.white;
    final cardBorder = isDark
        ? AppColors.darkBorder
        : Color(0xFFE2E8F0);
    final textColorHigh = isDark ? AppColors.darkTextHigh : Color(0xFF0F172A);
    final textColorMed = isDark ? AppColors.darkTextMed : Color(0xFF64748B);
    final accentColor = AppColors.accent;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0x0C000000),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===================================================================
          // 1. TOP HEADER STRIP: Status, Evangelist & Stepping Navigation
          // ===================================================================
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated.withValues(alpha: 0.6)
                  : const Color(0xFFF8FAFC),
              border: Border(bottom: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: Row(
              children: [
                // Day Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: isToday
                        ? accentColor.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF2D3748) : const Color(0xFFEDF2F7)),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isToday ? accentColor.withValues(alpha: 0.4) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isToday ? accentColor : textColorMed,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          dateStatusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isToday ? accentColor : textColorHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Evangelist Tag
                Expanded(
                  child: Text(
                    evangelist.amharicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: textColorMed,
                    ),
                  ),
                ),

                // Date Navigation Controls (‹  Today  ›)
                _SteppingNavButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'ያለፈው ቀን (Previous day)',
                  onTap: () => _stepDate(-1),
                ),
                if (!isToday) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: _resetToToday,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        'ዛሬ',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                _SteppingNavButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'ቀጣዩ ቀን (Next day)',
                  onTap: () => _stepDate(1),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 2. MAIN HERO CALENDAR DISPLAY (Ethiopian Primary + Gregorian Anchor)
          // ===================================================================
          InkWell(
            onTap: () => _openDatePicker(lang, settings.calendarFormat),
            splashColor: accentColor.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Large Ethiopian Day with AnimatedSwitcher
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Text(
                      '${_activeDate.day}',
                      key: ValueKey(_activeDate.day),
                      style: GoogleFonts.outfit(
                        fontSize: 62,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        color: textColorHigh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Month, Year, Geez Badge & Weekday details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Month & Geez Badge Row
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$monthName ${_activeDate.year} ($geezYear)',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColorHigh,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Ge'ez Numeral Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  geezDay,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Weekday Name
                        Text(
                          weekdayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Corresponding Gregorian Date Anchor
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 13,
                              color: textColorMed,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                '${gregDate.day}/${gregDate.month}/${gregDate.year} G.C. (${snapshot.gregLabel})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11.5,
                                  color: textColorMed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Calendar Picker Cue Icon
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCardElevated
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.edit_calendar_outlined,
                      size: 18,
                      color: textColorMed,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ===================================================================
          // 3. SPIRITUAL & OCCASION BADGES (Fasting, Saint, Holiday)
          // ===================================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Fasting Status Pill
                if (settings.showFasting)
                  _BadgePill(
                    icon: fastingStatus.isFasting
                        ? Icons.spa_rounded
                        : Icons.restaurant_rounded,
                    label: fastingStatus.isFasting
                        ? 'ጾም · ${fastingStatus.reason}'
                        : 'ፍስክ · Regular Day',
                    backgroundColor: fastingStatus.isFasting
                        ? const Color(0xFF059669).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    textColor: fastingStatus.isFasting
                        ? const Color(0xFF10B981)
                        : textColorMed,
                    borderColor: fastingStatus.isFasting
                        ? const Color(0xFF059669).withValues(alpha: 0.3)
                        : cardBorder,
                  ),

                // Saint of the Day Pill
                if (settings.showMonthlySaints)
                  _BadgePill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'ጽላት · ${saint.nameAmharic}',
                    backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.14),
                    textColor: const Color(0xFFA78BFA),
                    borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ),

                // Special Holiday (if active)
                if (holiday != null)
                  _BadgePill(
                    icon: Icons.celebration_rounded,
                    label: 'በዓል · ${holiday.titleAmharic}',
                    backgroundColor: accentColor.withValues(alpha: 0.16),
                    textColor: accentColor,
                    borderColor: accentColor.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14),

          // ===================================================================
          // 4. LIVE ETHIOPIAN & GREGORIAN TIME FOOTER
          // ===================================================================
          InkWell(
            onTap: _openClockDialog,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated.withValues(alpha: 0.7)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.schedule_rounded, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'የኢትዮጵያ ሰዓት (Traditional Time)',
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: textColorMed,
                          ),
                        ),
                        Text(
                          '${ethTime.period.amharic} ${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')} · ${ethTime.isDaytime ? "ቀን" : "ሌሊት"}',
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: textColorHigh,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Live Gregorian digital seconds
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}:${_currentTime.second.toString().padLeft(2, '0')}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: textColorHigh,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),

          // ===================================================================
          // 5. QUICK ACTIONS STRIP (Add Event, Share, Customize Launcher Widget)
          // ===================================================================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkCardElevated.withValues(alpha: 0.4)
                  : const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: cardBorder, width: 0.8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _CompactActionButton(
                    icon: Icons.add_rounded,
                    label: 'ማስታወሻ',
                    onTap: () => widget.onAddEvent?.call(),
                  ),
                  const SizedBox(width: 8),
                  _CompactActionButton(
                    icon: Icons.ios_share_rounded,
                    label: 'አጋራ',
                    onTap: () => _shareDate(snapshot, lang),
                  ),
                  const SizedBox(width: 12),
                  _CompactActionButton(
                    icon: Icons.widgets_outlined,
                    label: 'የስልክ ዊጄት',
                    highlight: true,
                    onTap: () => _openWidgetCustomizer(lang),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SUB-COMPONENTS
// ---------------------------------------------------------------------------

class _SteppingNavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SteppingNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCardElevated : Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 18,
              color: isDark ? AppColors.darkTextHigh : Color(0xFF1E293B),
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  const _BadgePill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _CompactActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.accent;

    return Material(
      color: highlight
          ? accent.withValues(alpha: 0.12)
          : (isDark ? AppColors.darkCard : Colors.white),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight
                  ? accent.withValues(alpha: 0.3)
                  : (isDark ? AppColors.darkBorder : Color(0xFFCBD5E1)),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: highlight
                    ? accent
                    : (isDark ? AppColors.darkTextMed : Color(0xFF475569)),
              ),
              SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: highlight
                      ? accent
                      : (isDark ? AppColors.darkTextHigh : Color(0xFF334155)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
