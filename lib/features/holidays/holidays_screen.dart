import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/holidays/holiday_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_entity.dart';
import '../shared/components/app_surface.dart';
import '../shared/providers.dart';
import 'dialogs/holiday_card_share_dialog.dart';
import 'dialogs/holiday_detail_dialog.dart';
import 'dialogs/set_holiday_reminder_dialog.dart';
import 'tabs/annual_holidays_tab.dart';
import 'tabs/fasting_guide_tab.dart';
import 'tabs/greeting_card_studio_tab.dart';
import 'tabs/monthly_saints_tab.dart';

class HolidaysScreen extends ConsumerStatefulWidget {
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const HolidaysScreen({super.key, this.onNavigateToCalendar});

  @override
  ConsumerState<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends ConsumerState<HolidaysScreen> {
  int _selectedTab = 0;
  int _selectedYear = 2017;
  Holiday? _studioHoliday;

  @override
  void initState() {
    super.initState();
    _selectedYear = EthiopianCalendarEngine.todayEthiopian().year;
  }

  void _showHolidayDetail(Holiday h, EthiopianDate todayEth) {
    final currentLang = ref.read(currentAppLanguageProvider);
    showDialog(
      context: context,
      builder: (_) => HolidayDetailDialog(
        holiday: h,
        currentLang: currentLang,
        todayEth: todayEth,
        onDismiss: () => Navigator.of(context).pop(),
        onAddToEvents: (holiday) => _showSetReminderDialog(holiday),
        onShareCard: (holiday) {
          Navigator.of(context).pop();
          _showCardShareDialog(holiday);
        },
        onNavigateToCalendar: widget.onNavigateToCalendar,
      ),
    );
  }

  void _showSetReminderDialog(Holiday h) {
    final currentLang = ref.read(currentAppLanguageProvider);
    final allEvents = ref.read(eventsNotifierProvider).value ?? [];
    final existing = allEvents.firstWhere(
      (e) =>
          e.ethiopianYear == h.ethiopianDate.year &&
          e.ethiopianMonth == h.ethiopianDate.month &&
          e.ethiopianDay == h.ethiopianDate.day &&
          (e.title.contains(h.titleEnglish) ||
              e.title.contains(h.titleAmharic)),
      orElse: () => EventEntity.empty(),
    );

    showDialog(
      context: context,
      builder: (_) => SetHolidayReminderDialog(
        holiday: h,
        existingEvent: existing.id != 0 ? existing : null,
        currentLang: currentLang,
        onDismiss: () => Navigator.of(context).pop(),
        onSaveReminder:
            (alertHour, alertMinute, remindOnEve, reminderMinutesBefore) async {
          final targetDate = remindOnEve
              ? (h.ethiopianDate.day > 1
                  ? EthiopianDate(
                      h.ethiopianDate.year,
                      h.ethiopianDate.month,
                      h.ethiopianDate.day - 1,
                    )
                  : EthiopianDate(
                      h.ethiopianDate.year,
                      h.ethiopianDate.month == 1
                          ? 13
                          : h.ethiopianDate.month - 1,
                      30,
                    ))
              : h.ethiopianDate;

          final gDate = EthiopianCalendarEngine.toGregorian(targetDate);
          final eveSuffix = remindOnEve ? ' [ዋዜማ / Eve]' : '';
          final event = EventEntity(
            id: existing.id != 0 ? existing.id : 0,
            title: '${h.titleAmharic} (${h.titleEnglish})$eveSuffix',
            description: h.description,
            category: 'HOLIDAY',
            ethiopianYear: targetDate.year,
            ethiopianMonth: targetDate.month,
            ethiopianDay: targetDate.day,
            gregorianYear: gDate.year,
            gregorianMonth: gDate.month,
            gregorianDay: gDate.day,
            hour: alertHour,
            minute: alertMinute,
            isAllDay: true,
            recurrence: 'NONE',
            reminderMinutesBefore: reminderMinutesBefore,
            colorHex: h.isPublicHoliday ? '#EF4444' : '#F59E0B',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          await ref.read(eventsNotifierProvider.notifier).saveEvent(event);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('የበዓል ማሳሰቢያ ተመዝግቧል')),
            );
          }
        },
        onDeleteReminder: () async {
          if (existing.id != 0) {
            await ref
                .read(eventsNotifierProvider.notifier)
                .deleteEvent(existing.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ማሳሰቢያው ተሰርዟል')),
              );
            }
          }
        },
      ),
    );
  }

  void _showCardShareDialog(Holiday h) {
    final currentLang = ref.read(currentAppLanguageProvider);
    setState(() => _studioHoliday = h);
    showDialog(
      context: context,
      builder: (_) => HolidayCardShareDialog(
        currentDate: h.ethiopianDate,
        currentLanguage: currentLang,
        holiday: h,
        onDismiss: () => Navigator.of(context).pop(),
        onOpenStudio: () {
          Navigator.of(context).pop();
          setState(() {
            _studioHoliday = h;
            _selectedTab = 3;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayEth = ref.watch(todayEthiopianProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppAtmosphere(
        child: Column(
          children: [
            _HolidaysHeroHeader(
              year: _selectedYear,
              onOpenStudio: () => setState(() => _selectedTab = 3),
            ),
            TabBarHeader(
              selectedTab: _selectedTab,
              onTabSelected: (index) => setState(() => _selectedTab = index),
            ),
            Divider(
              height: 1,
              color: Theme.of(context)
                  .colorScheme
                  .outline
                  .withValues(alpha: 0.3),
            ),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  AnnualHolidaysTab(
                    selectedYear: _selectedYear,
                    onYearChange: (y) => setState(() => _selectedYear = y),
                    onSelectHolidayForDetail: (h) =>
                        _showHolidayDetail(h, todayEth),
                    onOpenReminder: (h) => _showSetReminderDialog(h),
                    onOpenCardShare: (h) => _showCardShareDialog(h),
                    onNavigateToCalendar: widget.onNavigateToCalendar,
                  ),
                  FastingGuideTab(selectedYear: _selectedYear),
                  MonthlySaintsTab(
                    onNavigateToCalendar: widget.onNavigateToCalendar,
                  ),
                  GreetingCardStudioTab(
                    initialHoliday: _studioHoliday,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidaysHeroHeader extends StatelessWidget {
  final int year;
  final VoidCallback onOpenStudio;

  const _HolidaysHeroHeader({
    required this.year,
    required this.onOpenStudio,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.92),
              const Color(0xFF0B3D2E),
              const Color(0xFF0F172A),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'በዓላት · Holidays',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ethiopian feasts, fasting & greetings · $year ዓ.ም',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onOpenStudio,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                'Card',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabBarHeader extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  const TabBarHeader({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'title': 'በዓላት', 'sub': 'Holidays', 'icon': Icons.celebration_rounded},
      {'title': 'አጽዋማት', 'sub': 'Fasting', 'icon': Icons.restaurant_menu_rounded},
      {'title': 'ጽላቶች', 'sub': 'Saints', 'icon': Icons.church_rounded},
      {'title': 'ካርድ', 'sub': 'Studio', 'icon': Icons.auto_awesome_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.surfaceBorder.withValues(alpha: 0.9),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[i]['icon'] as IconData,
                      size: 16,
                      color: isSelected
                          ? AppColors.onAccent
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tabs[i]['title'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.onAccent
                                : AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          tabs[i]['sub'] as String,
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.onAccent.withValues(alpha: 0.8)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
