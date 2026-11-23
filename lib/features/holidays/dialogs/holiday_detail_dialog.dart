import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/share_helper.dart';

class HolidayDetailDialog extends StatelessWidget {
  final Holiday holiday;
  final AppLanguage currentLang;
  final EthiopianDate todayEth;
  final VoidCallback onDismiss;
  final ValueChanged<Holiday> onAddToEvents;
  final ValueChanged<Holiday> onShareCard;
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const HolidayDetailDialog({
    super.key,
    required this.holiday,
    this.currentLang = AppLanguage.amharic,
    required this.todayEth,
    required this.onDismiss,
    required this.onAddToEvents,
    required this.onShareCard,
    this.onNavigateToCalendar,
  });

  Color _getTypeColor(HolidayType type) {
    switch (type) {
      case HolidayType.nationalPublic:
        return const Color(0xFFEF4444);
      case HolidayType.orthodoxMajor:
      case HolidayType.orthodoxMovable:
        return const Color(0xFFF59E0B);
      case HolidayType.orthodoxFasting:
        return const Color(0xFF10B981);
      case HolidayType.islamic:
        return const Color(0xFF059669);
      case HolidayType.culturalRegional:
        return const Color(0xFF8B5CF6);
      case HolidayType.monthlySaint:
        return const Color(0xFF3B82F6);
    }
  }

  String _getTypeLabel(HolidayType type) {
    switch (type) {
      case HolidayType.nationalPublic:
        return 'National Public · የሕዝብ በዓል';
      case HolidayType.orthodoxMajor:
        return 'Orthodox Major · የተዋሕዶ በዓል';
      case HolidayType.orthodoxMovable:
        return 'Movable Feast · ተንቀሳቃሽ በዓል';
      case HolidayType.orthodoxFasting:
        return 'Canonical Fast · የጾም ወቅት';
      case HolidayType.islamic:
        return 'Islamic · የእስልምና በዓል';
      case HolidayType.culturalRegional:
        return 'Cultural · ባህላዊ በዓል';
      case HolidayType.monthlySaint:
        return 'Monthly Saint · የወር ጽላት';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dow = EthiopianCalendarEngine.getDayOfWeek(holiday.ethiopianDate);
    final gDate = EthiopianCalendarEngine.toGregorian(holiday.ethiopianDate);
    final daysUntil = holiday.ethiopianDate >= todayEth
        ? EthiopianCalendarEngine.daysBetween(todayEth, holiday.ethiopianDate)
        : -EthiopianCalendarEngine.daysBetween(holiday.ethiopianDate, todayEth);

    final typeColor = _getTypeColor(holiday.type);
    final monthName =
        LocaleStrings.getMonthName(holiday.ethiopianDate.month, currentLang);
    final weekdayName = LocaleStrings.getWeekdayLong(dow, currentLang);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _getTypeLabel(holiday.type),
                      style: GoogleFonts.outfit(
                        color: typeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                holiday.titleAmharic,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                holiday.titleEnglish,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName ${holiday.ethiopianDate.day}፣ ${holiday.ethiopianDate.year} ዓ.ም',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$weekdayName · ${gDate.day}/${gDate.month}/${gDate.year} G.C.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: daysUntil == 0
                            ? const Color(0xFF10B981)
                            : AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        daysUntil == 0
                            ? 'ዛሬ'
                            : daysUntil > 0
                                ? '$daysUntil ቀናት'
                                : '${-daysUntil} ቀን በፊት',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: daysUntil == 0
                              ? Colors.white
                              : AppColors.accentDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'About · ስለ በዓሉ',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                holiday.description,
                style: GoogleFonts.outfit(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  'Share greeting card',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => onShareCard(holiday),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.notifications_active_rounded,
                          size: 16),
                      label: Text(
                        'Remind',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        onAddToEvents(holiday);
                        onDismiss();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                      label: Text(
                        'Calendar',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        onNavigateToCalendar?.call(holiday.ethiopianDate);
                        onDismiss();
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share text',
                    icon: Icon(Icons.notes_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () {
                      ShareHelper.share(
                        '✨ ${holiday.titleAmharic} (${holiday.titleEnglish})\n'
                        '📅 $monthName ${holiday.ethiopianDate.day}፣ ${holiday.ethiopianDate.year} ዓ.ም\n'
                        '${holiday.description}\n\n'
                        '— Zemen: Ethiopian Calendar · ዘመን',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
