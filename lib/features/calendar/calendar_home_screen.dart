import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/calendar/bahire_hasab.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/calendar/ethiopian_season.dart';
import '../../core/calendar/geez_numeral.dart';
import '../../core/calendar/gregorian_date.dart';
import '../../core/calendar/leap_year_calculator.dart';
import '../../core/heritage/daily_heritage_engine.dart';
import '../../core/holidays/holiday_engine.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/date_text.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/responsive.dart';
import '../../core/utils/share_helper.dart';
import '../../data/models/event_entity.dart';
import '../../data/preferences/user_preferences_repository.dart';
import '../events/dialogs/add_edit_event_dialog.dart';
import '../holidays/dialogs/holiday_detail_dialog.dart';
import '../shared/components/calendar_provenance_badge.dart';
import '../shared/components/custom_dual_date_picker_dialog.dart';
import '../shared/components/app_chrome.dart';
import '../shared/providers.dart';

/// Fully Functional Ethiopian Calendar Screen:
/// - 4 View Modes: Month Grid, Week Strip, 13-Month Year Grid, 24h Day Timeline
/// - Month & Year Picker Bottom Sheet (< Month Year ▾ >)
/// - First Day of Week support (Sunday vs Monday)
/// - Ge'ez / Arabic numerals toggle
/// - Dual Date Display (Ethiopian Primary / Gregorian Primary toggle)
/// - 4-Dot Status Indicators (Holiday, Feast, Event, Fasting)
/// - Selected Date Inspector with Fasting status, Saint of the day,
///   interactive Holiday details, and full Event management (check, edit, delete, add)
/// - Smooth swipe navigation + external jump synchronization
/// - Unified dark canvas & color constancy matching Zemen: Ethiopian Calendar design language
class CalendarHomeScreen extends ConsumerStatefulWidget {
  const CalendarHomeScreen({super.key});

  @override
  ConsumerState<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends ConsumerState<CalendarHomeScreen> {
  static const int _pageCenter = 120000;
  late PageController _pageController;

  /// Per-Ethiopian-year holiday index (month * 100 + day → holidays), so any
  /// date can be resolved regardless of which year the view is focused on.
  final Map<int, Map<int, List<Holiday>>> _holidayIndex = {};
  bool _syncing = false;
  bool _internalPageChange = false;
  String _yearViewStyle = 'MINI_CALENDARS'; // 'MINI_CALENDARS' or 'TILES'

  bool get _isGregPrimary =>
      ref.read(userSettingsProvider).calendarFormat == 'GREGORIAN';

  int get _monthsPerYear => _isGregPrimary ? 12 : 13;

  int _index(int year, int month) => year * _monthsPerYear + (month - 1);

  (int, int) _fromIndex(int i) {
    final mpy = _monthsPerYear;
    return (i ~/ mpy, (i % mpy) + 1);
  }

  @override
  void initState() {
    super.initState();
    _pageController = _newPageController();
  }

  /// Controller positioned on the month the view providers currently point at.
  PageController _newPageController() {
    return PageController(
      keepPage: false,
      initialPage: _pageCenter +
          _index(ref.read(viewYearProvider), ref.read(viewMonthProvider)),
    );
  }

  /// The month pager only exists in Month mode. When it is (re)built after
  /// navigating in Week / Year / Day mode, start it on the focused month
  /// instead of the page it was showing when it was last on screen.
  void _ensurePagerMatchesView() {
    if (_pageController.hasClients) return;
    final target =
        _pageCenter + _index(ref.read(viewYearProvider), ref.read(viewMonthProvider));
    if (_pageController.initialPage == target) return;
    final stale = _pageController;
    _pageController = _newPageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => stale.dispose());
  }

  List<Holiday> _holidaysOn(EthiopianDate date) {
    final byDay = _holidayIndex.putIfAbsent(date.year, () {
      final map = <int, List<Holiday>>{};
      for (final h in HolidayEngine.getHolidaysForYear(date.year)) {
        final d = h.ethiopianDate;
        map.putIfAbsent(d.month * 100 + d.day, () => []).add(h);
      }
      return map;
    });
    return byDay[date.month * 100 + date.day] ?? const [];
  }

  /// Year and month of [date] in the active calendar (EC 1–13 or GC 1–12).
  (int, int) _viewKeyFor(EthiopianDate date) {
    if (_isGregPrimary) {
      final g = EthiopianCalendarEngine.toGregorian(date);
      return (g.year, g.month);
    }
    return (date.year, date.month);
  }

  /// Selects [date] and focuses the month that contains it.
  void _focusDate(EthiopianDate date) {
    ref.read(selectedDateProvider.notifier).state = date;
    final (y, m) = _viewKeyFor(date);
    _updateViewYearMonth(y, m);
  }

  void _shiftSelectedBy(int days) {
    final jdn = EthiopianCalendarEngine.ethiopianToJdn(ref.read(selectedDateProvider));
    _focusDate(EthiopianCalendarEngine.jdnToEthiopian(jdn + days));
  }

  /// Horizontal swipe handler shared by the Week and Day views.
  void _onSwipe(DragEndDetails details, int stepDays) {
    final v = details.primaryVelocity ?? 0;
    if (v.abs() < 250) return;
    _shiftSelectedBy(v < 0 ? stepDays : -stepDays);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncToPage(int year, int month) {
    if (!_pageController.hasClients || _syncing) return;
    final target = _pageCenter + _index(year, month);
    final current = _pageController.page?.round() ?? target;
    if (current != target) {
      final diff = (target - current).abs();
      if (diff > 1) {
        _pageController.jumpToPage(target);
      } else {
        _syncing = true;
        _pageController
            .animateToPage(
              target,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted) _syncing = false;
            });
      }
    }
  }

  void _updateViewYearMonth(int year, int month, {bool jump = false}) {
    _syncing = true;
    ref.read(viewYearProvider.notifier).state = year;
    ref.read(viewMonthProvider.notifier).state = month;
    if (_pageController.hasClients) {
      final target = _pageCenter + _index(year, month);
      final current = _pageController.page?.round() ?? target;
      if (jump || (target - current).abs() > 1) {
        _pageController.jumpToPage(target);
        _syncing = false;
      } else if (target != current) {
        _pageController
            .animateToPage(
              target,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted) _syncing = false;
            });
      } else {
        _syncing = false;
      }
    } else {
      _syncing = false;
    }
  }

  void _onPageChanged(int page) {
    if (_syncing) return;
    final (y, m) = _fromIndex(page - _pageCenter);
    _internalPageChange = true;
    ref.read(viewYearProvider.notifier).state = y;
    ref.read(viewMonthProvider.notifier).state = m;
    _internalPageChange = false;
  }

  void _shiftMonth(int delta) {
    final y = ref.read(viewYearProvider);
    final m = ref.read(viewMonthProvider);
    final maxMonth = _monthsPerYear;
    var nm = m + delta;
    var ny = y;
    if (nm > maxMonth) {
      nm = 1;
      ny++;
    } else if (nm < 1) {
      nm = maxMonth;
      ny--;
    }
    _updateViewYearMonth(ny, nm);
  }

  void _goToday() {
    final today = ref.read(todayEthiopianProvider);
    ref.read(selectedDateProvider.notifier).state = today;
    final (y, m) = _viewKeyFor(today);
    _updateViewYearMonth(y, m, jump: true);
  }

  Future<void> _deleteEvent(EventEntity event) async {
    final notifier = ref.read(eventsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final lang = ref.read(currentAppLanguageProvider);
    await notifier.deleteEvent(event.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(LocaleStrings.get('event_deleted', lang)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: LocaleStrings.get('undo', lang),
            textColor: AppColors.accent,
            onPressed: () => notifier.saveEvent(event.copyWith(id: 0)),
          ),
        ),
      );
  }

  /// EC ↔ GC toggle: remap the focused month into the target calendar system.
  Future<void> _toggleCalendarFormat() async {
    final selected = ref.read(selectedDateProvider);
    final toGreg = !_isGregPrimary;
    if (toGreg) {
      final g = EthiopianCalendarEngine.toGregorian(selected);
      await ref.read(userSettingsProvider.notifier).setCalendarFormat('GREGORIAN');
      _updateViewYearMonth(g.year, g.month, jump: true);
    } else {
      await ref.read(userSettingsProvider.notifier).setCalendarFormat('ETHIOPIAN');
      _updateViewYearMonth(selected.year, selected.month, jump: true);
    }
  }

  Future<void> _addEvent([EthiopianDate? initialDate]) async {
    final EthiopianDate date = initialDate ?? ref.read(selectedDateProvider);
    final lang = ref.read(currentAppLanguageProvider);
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: date,
      currentLanguage: lang,
    );
    if (draft == null || !mounted) return;
    try {
      await ref.read(eventsNotifierProvider.notifier).saveEvent(draft);
      if (!mounted) return;
      AddEditEventDialog.showSavedFeedback(
        context,
        isEdit: false,
        title: draft.title,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save failed · ማስቀመጥ አልተሳካም',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  Future<void> _editEvent(EventEntity event) async {
    final lang = ref.read(currentAppLanguageProvider);
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: EthiopianDate(
        event.ethiopianYear,
        event.ethiopianMonth,
        event.ethiopianDay,
      ),
      eventToEdit: event,
      currentLanguage: lang,
    );
    if (draft == null || !mounted) return;
    try {
      await ref.read(eventsNotifierProvider.notifier).saveEvent(draft);
      if (!mounted) return;
      AddEditEventDialog.showSavedFeedback(
        context,
        isEdit: true,
        title: draft.title,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Save failed · ማስቀመጥ አልተሳካም',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  void _showHolidayDetail(Holiday holiday, EthiopianDate todayEth) {
    final lang = ref.read(currentAppLanguageProvider);
    showDialog(
      context: context,
      builder: (_) => HolidayDetailDialog(
        holiday: holiday,
        currentLang: lang,
        todayEth: todayEth,
        onDismiss: () => Navigator.of(context).pop(),
        onAddToEvents: (h) async {
          final gDate = EthiopianCalendarEngine.toGregorian(h.ethiopianDate);
          final event = EventEntity(
            title: '${h.titleAmharic} (${h.titleEnglish})',
            description: h.description,
            category: 'HOLIDAY',
            ethiopianYear: h.ethiopianDate.year,
            ethiopianMonth: h.ethiopianDate.month,
            ethiopianDay: h.ethiopianDate.day,
            gregorianYear: gDate.year,
            gregorianMonth: gDate.month,
            gregorianDay: gDate.day,
            hour: 8,
            minute: 0,
            isAllDay: true,
            recurrence: 'NONE',
            reminderMinutesBefore: 0,
            colorHex: h.isPublicHoliday ? '#EF4444' : '#F59E0B',
            createdAt: DateTime.now().millisecondsSinceEpoch,
          );
          await ref.read(eventsNotifierProvider.notifier).saveEvent(event);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('በዓሉ በማስታወሻ ተመዝግቧል (Holiday added to events)'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onShareCard: (_) {},
      ),
    );
  }

  void _showMonthYearPickerModal(BuildContext context) {
    final currentYear = ref.read(viewYearProvider);
    final currentMonth = ref.read(viewMonthProvider);
    final lang = ref.read(currentAppLanguageProvider);
    final isGregPrimary = ref.read(userSettingsProvider).calendarFormat == 'GREGORIAN';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        int pickerYear = currentYear;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final evangelist = LeapYearCalculator.getEvangelist(
              isGregPrimary
                  ? EthiopianCalendarEngine.toEthiopian(
                      GregorianDate(pickerYear, 1, 1),
                    ).year
                  : pickerYear,
            );
            final isLeap = isGregPrimary
                ? LeapYearCalculator.isGregorianLeapYear(pickerYear)
                : LeapYearCalculator.isEthiopianLeapYear(pickerYear);

            return Container(
              padding: EdgeInsets.fromLTRB(18, 16, 18, 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AppColors.surfaceBorder, width: 1),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 14),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleStrings.get('select_month_year', lang),
                        style: AppChrome.title(size: 16),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Year Stepper Bar
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.chevron_left_rounded, color: AppColors.accent, size: 28),
                          onPressed: () => setSheetState(() => pickerYear--),
                        ),
                        Column(
                          children: [
                            Text(
                              isGregPrimary ? '$pickerYear' : DateText.ethiopianYear(pickerYear, lang),
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              isGregPrimary
                                  ? 'Gregorian Calendar • ${isLeap ? "Leap Year (366 days)" : "Common Year (365 days)"}'
                                  : '${evangelist.amharicName} • ${isLeap ? (!isGregPrimary ? "ጳጉሜ 6 (ተደራቢ)" : "Pagume 6 (Leap)") : (!isGregPrimary ? "ጳጉሜ 5" : "Pagume 5")}',
                              style: AppChrome.mute(size: 11),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 28),
                          onPressed: () => setSheetState(() => pickerYear++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Year Jump Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _quickYearChip('-5', pickerYear - 5, () => setSheetState(() => pickerYear -= 5)),
                        _quickYearChip('-1', pickerYear - 1, () => setSheetState(() => pickerYear -= 1)),
                        _quickYearChip(
                          LocaleStrings.get('today', lang),
                          isGregPrimary
                              ? EthiopianCalendarEngine.todayGregorian().year
                              : EthiopianCalendarEngine.todayEthiopian().year,
                          () {
                            setSheetState(
                              () => pickerYear = isGregPrimary
                                  ? EthiopianCalendarEngine.todayGregorian().year
                                  : EthiopianCalendarEngine.todayEthiopian().year,
                            );
                          },
                        ),
                        _quickYearChip('+1', pickerYear + 1, () => setSheetState(() => pickerYear += 1)),
                        _quickYearChip('+5', pickerYear + 5, () => setSheetState(() => pickerYear += 5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Months Grid (12 for Gregorian, 13 for Ethiopian)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: isGregPrimary ? 12 : 13,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemBuilder: (context, idx) {
                      final monthNum = idx + 1;
                      final isSelected = pickerYear == currentYear && monthNum == currentMonth;
                      final isTodayMonth = isGregPrimary
                          ? (pickerYear == EthiopianCalendarEngine.todayGregorian().year &&
                              monthNum == EthiopianCalendarEngine.todayGregorian().month)
                          : (pickerYear == EthiopianCalendarEngine.todayEthiopian().year &&
                              monthNum == EthiopianCalendarEngine.todayEthiopian().month);
                      final monthName = isGregPrimary
                          ? _gregorianMonthName(monthNum)
                          : LocaleStrings.getMonthName(monthNum, lang);
                      final days = isGregPrimary
                          ? GregorianDate.daysInMonthFor(pickerYear, monthNum)
                          : EthiopianDate.daysInMonthFor(pickerYear, monthNum);

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.of(context).pop();
                          _updateViewYearMonth(pickerYear, monthNum, jump: true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : isTodayMonth
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : isTodayMonth
                                      ? AppColors.accent
                                      : AppColors.surfaceBorder,
                              width: isSelected || isTodayMonth ? 1.4 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$monthNum. $monthName',
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : isTodayMonth
                                          ? AppColors.accent
                                          : AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                LocaleStrings.format('days_count', lang, params: {'count': '$days'}),
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.today_rounded, size: 16, color: AppColors.accent),
                          label: Text(LocaleStrings.get('go_to_today', lang), style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.surfaceBorder),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _goToday();
                          },
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: Icon(Icons.date_range_rounded, size: 16),
                          label: Text(LocaleStrings.get('pick_date', lang), style: GoogleFonts.outfit(fontSize: 13)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showExactDatePicker();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _quickYearChip(String label, int targetYear, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textPrimary)),
        backgroundColor: AppColors.surfaceElevated,
        side: BorderSide(color: AppColors.surfaceBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        onPressed: onTap,
      ),
    );
  }

  void _showExactDatePicker() {
    final date = ref.read(selectedDateProvider);
    final lang = ref.read(currentAppLanguageProvider);
    final format = ref.read(userSettingsProvider).calendarFormat;
    showDialog(
      context: context,
      builder: (_) => CustomDualDatePickerDialog(
        initialDate: date,
        initialFormat: format,
        todayEthiopian: EthiopianCalendarEngine.todayEthiopian(),
        currentLang: lang,
        onDateSelected: (selectedDate, newFormat) async {
          ref.read(selectedDateProvider.notifier).state = selectedDate;
          await ref
              .read(userSettingsProvider.notifier)
              .setCalendarFormat(newFormat);
          if (!mounted) return;
          final (y, m) = _viewKeyFor(selectedDate);
          _updateViewYearMonth(y, m, jump: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewYear = ref.watch(viewYearProvider);
    final viewMonth = ref.watch(viewMonthProvider);
    final selected = ref.watch(selectedDateProvider);
    final today = ref.watch(todayEthiopianProvider);
    final events = ref.watch(eventsNotifierProvider).value ?? [];
    final settings = ref.watch(userSettingsProvider);
    final lang = ref.watch(currentAppLanguageProvider);
    final viewMode = ref.watch(calendarViewModeProvider);

    // Synchronize page view when external state changes
    ref.listen<int>(viewMonthProvider, (prev, next) {
      if (_syncing || _internalPageChange) return;
      final y = ref.read(viewYearProvider);
      _syncToPage(y, next);
    });
    ref.listen<int>(viewYearProvider, (prev, next) {
      if (_syncing || _internalPageChange) return;
      final m = ref.read(viewMonthProvider);
      _syncToPage(next, m);
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _addEvent(selected),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.add_rounded, color: AppColors.onAccent, size: 28),
          ),
        ),
      ),
      body: Column(
        children: [
          // —— 1. View Mode Switcher Pill Bar (Month, Week, Year, Day) ——
          _buildViewModeBar(viewMode, lang),

          // —— 2. View Mode Content Router ——
          Expanded(
            child: _buildViewModeContent(
              viewMode: viewMode,
              viewYear: viewYear,
              viewMonth: viewMonth,
              selected: selected,
              today: today,
              events: events,
              settings: settings,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW MODE SWITCHER BAR: [Month | Week | Year | Day]
  // ---------------------------------------------------------------------------
  Widget _buildViewModeBar(String currentMode, AppLanguage lang) {
    final r = AppResponsive(context);
    final modes = [
      ('MONTH', LocaleStrings.get('month_view', lang), Icons.calendar_view_month_rounded),
      ('WEEK', LocaleStrings.get('week_view', lang), Icons.view_week_rounded),
      ('YEAR', LocaleStrings.get('year_view', lang), Icons.calendar_month_rounded),
      ('DAY', LocaleStrings.get('day_view', lang), Icons.wb_sunny_outlined),
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(r.isCompact ? 10 : 14, 8, r.isCompact ? 10 : 14, 4),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: modes.map((m) {
          final isSelected = m.$1 == currentMode;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () =>
                    ref.read(calendarViewModeProvider.notifier).state = m.$1,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    vertical: r.isCompact ? 8 : 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accent,
                              AppColors.accentDeep,
                            ],
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.32),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.$3,
                        size: r.isCompact ? 15 : 16,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                      SizedBox(height: 3),
                      Text(
                        m.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: r.isCompact ? 10.5 : 11.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          letterSpacing: isSelected ? 0.2 : 0,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW MODE CONTENT ROUTER
  // ---------------------------------------------------------------------------
  Widget _buildViewModeContent({
    required String viewMode,
    required int viewYear,
    required int viewMonth,
    required EthiopianDate selected,
    required EthiopianDate today,
    required List<EventEntity> events,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    switch (viewMode) {
      case 'WEEK':
        return _buildWeekView(
          centerDate: selected,
          today: today,
          events: events,
          settings: settings,
          lang: lang,
        );
      case 'YEAR':
        return _buildYearView(
          viewYear: viewYear,
          today: today,
          settings: settings,
          lang: lang,
        );
      case 'DAY':
        return _buildDayView(
          selected: selected,
          today: today,
          events: events,
          settings: settings,
          lang: lang,
        );
      case 'MONTH':
      default:
        return _buildMonthView(
          viewYear: viewYear,
          viewMonth: viewMonth,
          selected: selected,
          today: today,
          events: events,
          settings: settings,
          lang: lang,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // 1. MONTH VIEW
  // ---------------------------------------------------------------------------
  Widget _buildMonthView({
    required int viewYear,
    required int viewMonth,
    required EthiopianDate selected,
    required EthiopianDate today,
    required List<EventEntity> events,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    _ensurePagerMatchesView();
    final isSundayStart = settings.firstDayOfWeek == 'SUNDAY';
    final isGregPrimary = settings.calendarFormat == 'GREGORIAN';
    final gToday = EthiopianCalendarEngine.toGregorian(today);

    // Focused month is native to the active calendar (EC 1–13 or GC 1–12).
    final safeMonth = isGregPrimary
        ? viewMonth.clamp(1, 12)
        : viewMonth.clamp(1, 13);
    final monthName = isGregPrimary
        ? _gregorianMonthName(safeMonth)
        : LocaleStrings.getMonthName(safeMonth, lang);
    final evangelist = LeapYearCalculator.getEvangelist(
      isGregPrimary
          ? EthiopianCalendarEngine.toEthiopian(
              GregorianDate(viewYear, safeMonth, 1),
            ).year
          : viewYear,
    );
    final isCurrentMonth = isGregPrimary
        ? (viewYear == gToday.year && safeMonth == gToday.month)
        : (viewYear == today.year && safeMonth == today.month);

    final String dualRange;
    if (isGregPrimary) {
      final daysInG = GregorianDate.daysInMonthFor(viewYear, safeMonth);
      final eStart = EthiopianCalendarEngine.toEthiopian(
        GregorianDate(viewYear, safeMonth, 1),
      );
      final eEnd = EthiopianCalendarEngine.toEthiopian(
        GregorianDate(viewYear, safeMonth, daysInG),
      );
      dualRange =
          '${LocaleStrings.getMonthName(eStart.month, lang)} – ${LocaleStrings.getMonthName(eEnd.month, lang)} ${eStart.year} ዓ.ም';
    } else {
      final daysInE = EthiopianDate.daysInMonthFor(viewYear, safeMonth);
      final gStart = EthiopianCalendarEngine.toGregorian(
        EthiopianDate(viewYear, safeMonth, 1),
      );
      final gEnd = EthiopianCalendarEngine.toGregorian(
        EthiopianDate(viewYear, safeMonth, daysInE),
      );
      dualRange =
          '${_monthAbbr(gStart.month)} – ${_monthAbbr(gEnd.month)} ${gStart.year}';
    }

    // Weekday headers: authentic Ethiopian letters when viewing Ethiopian calendar,
    // Latin letters when viewing Gregorian calendar.
    final weekHeaders = isSundayStart
        ? (!isGregPrimary
            ? [
              DateText.weekdayInitial(7, lang),
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
            ]
            : [
              DateText.weekdayInitial(7, lang),
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
            ])
        : (!isGregPrimary
            ? [
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
              DateText.weekdayInitial(7, lang),
            ]
            : [
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
              DateText.weekdayInitial(7, lang),
            ]);

    return LayoutBuilder(
      builder: (context, outer) {
        final r = AppResponsive(context);
        final hPad = r.isCompact ? 8.0 : 12.0;
        final titleSize = r.isCompact ? 15.5 : 17.0;

        // Size the month grid from the viewport so the first screen feels open,
        // then one continuous vertical scroll lifts the full page (calendar + detail).
        final contentW = outer.maxWidth - hPad * 2;
        final cellW = (contentW - 8) / 7;
        final weekdayH = r.isCompact ? 24.0 : 28.0;
        const cardPadV = 3.0;
        const rowGap = 1.5;
        final focusMonth = isGregPrimary
            ? viewMonth.clamp(1, 12)
            : viewMonth.clamp(1, 13);
        final viewDaysInMonth = isGregPrimary
            ? GregorianDate.daysInMonthFor(viewYear, focusMonth)
            : EthiopianDate.daysInMonthFor(viewYear, focusMonth);
        final viewFirstDow = isGregPrimary
            ? EthiopianCalendarEngine.getDayOfWeekGregorian(
                GregorianDate(viewYear, focusMonth, 1),
              )
            : EthiopianCalendarEngine.getDayOfWeek(
                EthiopianDate(viewYear, focusMonth, 1),
              );
        final viewLead = isSundayStart
            ? (viewFirstDow == 7 ? 0 : viewFirstDow)
            : (viewFirstDow - 1);
        final viewRowCount =
            ((viewLead + viewDaysInMonth) / 7).ceil().clamp(1, 6);
        final targetGridH = (outer.maxHeight *
                (r.isVeryShort ? 0.40 : (r.isShort ? 0.44 : 0.48)))
            .clamp(150.0, outer.maxHeight.isFinite ? outer.maxHeight : 520.0);
        final rowGapsTotal = rowGap * (viewRowCount - 1);
        final usableRowH =
            ((targetGridH - rowGapsTotal) / viewRowCount).clamp(18.0, 96.0);
        final fittedAspect = (cellW / usableRowH).clamp(0.55, 3.0);
        final preferredAspect = r.isCompact ? 1.22 : 1.15;
        final aspect =
            fittedAspect > preferredAspect ? fittedAspect : preferredAspect;
        final cellH = cellW / aspect;
        final gridH = cellH * viewRowCount + rowGapsTotal;
        final cardH = (gridH + weekdayH + cardPadV * 2).clamp(160.0, 560.0);

        Widget gridPage(int page) {
          final (y, m) = _fromIndex(page - _pageCenter);
          return _MonthGrid(
            year: y,
            month: m,
            selected: selected,
            today: today,
            events: events,
            holidaysOn: _holidaysOn,
            isSundayStart: isSundayStart,
            isGregPrimary: isGregPrimary,
            useGeezNumerals: settings.numeralType == 'GEEZ',
            showFasting: settings.showFasting,
            cellAspectRatio: aspect,
            onSelect: (d, inMonth) {
              if (inMonth) {
                ref.read(selectedDateProvider.notifier).state = d;
              } else {
                _focusDate(d);
              }
            },
            onLongPress: (d) {
              ref.read(selectedDateProvider.notifier).state = d;
              _addEvent(d);
            },
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // —— Professional month navigator / landing header ——
            SliverToBoxAdapter(
              child: Padding(
              padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 6),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.surfaceElevated,
                      AppColors.surface,
                      Color.lerp(AppColors.surface, AppColors.accent, 0.06) ??
                          AppColors.surface,
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.surfaceBorder.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 4, 2),
                      child: Row(
                        children: [
                          _NavIconButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Previous month',
                            onTap: () => _shiftMonth(-1),
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showMonthYearPickerModal(context),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 6,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$monthName $viewYear',
                                            style: GoogleFonts.outfit(
                                              fontSize: titleSize + 1,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        SizedBox(width: 2),
                                        Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.expand_more_rounded,
                                            color: AppColors.accent,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      isGregPrimary
                                          ? dualRange
                                          : '${evangelist.amharicName} · $dualRange',
                                      style: GoogleFonts.outfit(
                                        fontSize: r.isCompact ? 10.5 : 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (!isCurrentMonth)
                            _NavIconButton(
                              icon: Icons.today_rounded,
                              tooltip: 'Jump to today',
                              accent: true,
                              onTap: _goToday,
                            ),
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _toggleCalendarFormat,
                                child: AnimatedContainer(
                                  duration: Duration(milliseconds: 180),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.accent
                                            .withValues(alpha: 0.18),
                                        AppColors.accent
                                            .withValues(alpha: 0.08),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    isGregPrimary ? 'GC' : 'EC',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _NavIconButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Next month',
                            onTap: () => _shiftMonth(1),
                          ),
                        ],
                      ),
                    ),
                    // Dual-calendar context strip
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.fromLTRB(10, 2, 10, 10),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.surfaceBorder.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.accent,
                                  AppColors.ethioGoldPrimary,
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  !isGregPrimary
                                      ? 'የኢትዮጵያ የቀን አቆጣጠር'
                                      : 'Gregorian Calendar',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  isCurrentMonth
                                      ? (isGregPrimary
                                          ? 'Today · ${_gregorianMonthName(gToday.month)} ${gToday.day}, ${gToday.year}'
                                          : 'ዛሬ · ${LocaleStrings.getMonthName(today.month, lang)} ${today.day}፣ ${today.year} ዓ.ም')
                                      : (!isGregPrimary
                                          ? 'ወደ ሌላ ወር ለመቀየር ይጫኑ'
                                          : 'Tap month title to jump'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentMonth)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                LocaleStrings.get('today', lang),
                                style: GoogleFonts.outfit(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),

            // —— Sleek "jump to today" strip ——
            if (!isCurrentMonth)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 4),
                  child: Material(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _goToday,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'ዛሬ · ${LocaleStrings.getMonthName(today.month, lang)} ${today.day}፣ ${today.year} ዓ.ም',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    LocaleStrings.get('go_to_today', lang),
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 13,
                                    color: AppColors.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // —— Month grid (scrolls up with the rest of the page) ——
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Container(
                  height: cardH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surfaceElevated,
                        AppColors.surface,
                        Color.lerp(AppColors.surface, AppColors.accent, 0.05) ??
                            AppColors.surface,
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.surfaceBorder.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        Container(
                          height: weekdayH,
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.surfaceElevated.withValues(alpha: 0.9),
                                AppColors.surface.withValues(alpha: 0.4),
                              ],
                            ),
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.surfaceBorder
                                    .withValues(alpha: 0.55),
                                width: 0.8,
                              ),
                            ),
                          ),
                          child: Row(
                            children: List.generate(7, (i) {
                              final isSunday =
                                  isSundayStart ? (i == 0) : (i == 6);
                              final isSaturday =
                                  isSundayStart ? (i == 6) : (i == 5);
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    weekHeaders[i],
                                    style: GoogleFonts.outfit(
                                      fontSize: r.isCompact ? 11.5 : 12.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                      color: isSunday
                                          ? AppColors.accent
                                          : isSaturday
                                              ? AppColors.ethioGoldPrimary
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: _onPageChanged,
                            itemBuilder: (_, page) => Padding(
                              padding: const EdgeInsets.fromLTRB(4, 2, 4, 4),
                              child: gridPage(page),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Row(
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
                        const Color(0xFFEF4444),
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
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSelectedDateInspector(
                    selected: selected,
                    today: today,
                    events: events,
                    settings: settings,
                    lang: lang,
                    compact: r.isCompact || r.isShort || outer.maxHeight < 560,
                  ),
                  _buildMonthHighlights(
                    viewYear: viewYear,
                    viewMonth: focusMonth,
                    selected: selected,
                    settings: settings,
                    lang: lang,
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool ring = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ring ? 8 : 6,
            height: ring ? 8 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: ring ? Border.all(color: Colors.white, width: 1.5) : null,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: ring ? 0.75 : 0.4),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
          SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// Maps holiday types to dataset provenance tags (never invent accuracy).
  String _holidayProvenance(Holiday h) {
    switch (h.type) {
      case HolidayType.islamic:
        return 'approximate_calculated';
      case HolidayType.culturalRegional:
        return 'approximate_rule';
      case HolidayType.orthodoxMovable:
      case HolidayType.orthodoxFasting:
        return 'verified';
      case HolidayType.nationalPublic:
      case HolidayType.orthodoxMajor:
      case HolidayType.monthlySaint:
        return 'verified';
    }
  }

  String _holidayKindLabel(Holiday h) {
    switch (h.type) {
      case HolidayType.islamic:
        return 'Hijri→EC';
      case HolidayType.culturalRegional:
        return 'Regional';
      case HolidayType.orthodoxMovable:
      case HolidayType.orthodoxFasting:
        return 'Bahire Hasab';
      case HolidayType.nationalPublic:
        return 'National';
      case HolidayType.orthodoxMajor:
        return 'Fixed feast';
      case HolidayType.monthlySaint:
        return 'Saint';
    }
  }

  // ---------------------------------------------------------------------------
  // SELECTED DATE INSPECTOR CARD
  // ---------------------------------------------------------------------------
  Widget _buildSelectedDateInspector({
    required EthiopianDate selected,
    required EthiopianDate today,
    required List<EventEntity> events,
    required UserSettings settings,
    required AppLanguage lang,
    bool compact = false,
  }) {
    // FIX: Correct month name from selectedDate.month (not viewMonth!)
    final selMonthName = LocaleStrings.getMonthName(selected.month, lang);
    final selGreg = EthiopianCalendarEngine.toGregorian(selected);
    final selDow = EthiopianCalendarEngine.getDayOfWeek(selected);
    final weekdayName = LocaleStrings.getWeekdayLong(selDow, lang);
    final evangelist = LeapYearCalculator.getEvangelist(selected.year);
    final relativeLabel = getRelativeDateLabel(today, selected, settings.calendarFormat == 'GREGORIAN');
    final isGeez = settings.numeralType == 'GEEZ';
    final isGregPrimary = settings.calendarFormat == 'GREGORIAN';
    final dayNumDisplay = isGeez ? GeezNumeral.toGeez(selected.day) : '${selected.day}';

    // Observances from verified HolidayEngine + Bahire Hasab
    final fasting = HolidayEngine.isFastingDay(selected);
    final saint = HolidayEngine.monthlySaints.firstWhere(
      (s) => s.day == selected.day,
      orElse: () => HolidayEngine.monthlySaints.first,
    );
    final bahire = BahireHasab.calculate(selected.year);

    // Filter events and holidays matching selected date
    final dateEvents = events.where((e) => eventMatchesDate(e, selected)).toList();
    final dateHolidays = _holidaysOn(selected);
    final hasMovable = dateHolidays.any(
      (h) =>
          h.type == HolidayType.orthodoxMovable ||
          h.type == HolidayType.orthodoxFasting,
    );
    final hasApproximate = dateHolidays.any(
      (h) =>
          h.type == HolidayType.islamic ||
          h.type == HolidayType.culturalRegional,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
            Color.lerp(AppColors.surface, AppColors.accent, 0.06) ??
                AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.95)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              top: -22,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtle top accent bar
                  Center(
                    child: Container(
                      width: 32,
                      height: 3.5,
                      margin: EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header Row with Title and Share Pill Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        LocaleStrings.get('day_details', lang),
                        style: GoogleFonts.outfit(
                          fontSize: compact ? 10 : 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.accent,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          final text =
                              '$selMonthName ${selected.day}፣ ${selected.year} ዓ.ም ($weekdayName)\n'
                              '${evangelist.amharicName} • ${_gregorianLong(selGreg)}\n'
                              'ቅዱስ: ${saint.nameAmharic}\n'
                              'ጾም: ${fasting.isFasting ? fasting.reason : "ፍስክ"}\n'
                              'በዓል: ${dateHolidays.map((h) => h.titleAmharic).join(", ")}';
                          ShareHelper.share(text, subject: 'የኢትዮጵያ ቀን (Ethiopian Date)');
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.surfaceBorder.withValues(alpha: 0.8),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ios_share_rounded, size: 13, color: AppColors.accent),
                              SizedBox(width: 4),
                              Text(
                                LocaleStrings.get('share', lang),
                                style: GoogleFonts.outfit(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hero Calendar Ticket Tile
                  Container(
                    width: compact ? 52 : 58,
                    height: compact ? 52 : 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.accent,
                          AppColors.accentDeep,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayNumDisplay,
                            style: GoogleFonts.outfit(
                              fontSize: compact
                                  ? (isGeez ? 17 : 20)
                                  : (isGeez ? 19 : 23),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isGeez
                                ? '${selected.day}'
                                : GeezNumeral.toGeez(selected.day),
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                '$selMonthName ${selected.day}፣ ${selected.year} ዓ.ም',
                                style: GoogleFonts.outfit(
                                  fontSize: compact ? 15 : 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: selected == today
                                    ? AppColors.accent
                                    : AppColors.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.accent.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                relativeLabel,
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: selected == today
                                      ? Colors.white
                                      : AppColors.accent,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3),
                        Text(
                          '$weekdayName · ${evangelist.amharicName}',
                          style: GoogleFonts.outfit(
                            fontSize: compact ? 11.5 : 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              size: 11.5,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                !isGregPrimary
                                    ? '${selGreg.day} ${_monthAbbr(selGreg.month)} ${selGreg.year} እ.ኤ.አ.'
                                    : '${_gregorianLong(selGreg)} G.C.',
                                style: GoogleFonts.outfit(
                                  fontSize: compact ? 11 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // —— Quick Add Reminder / Event ——
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _addEvent(selected),
                  child: Ink(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.16),
                          AppColors.accent.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.alarm_add_rounded,
                            size: 18,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleStrings.get(
                                  'calendar_quick_add_title',
                                  lang,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                LocaleStrings.get(
                                  'calendar_quick_add_sub',
                                  lang,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // —— Fasting & Saint chips ——
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (settings.showFasting)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: fasting.isFasting
                              ? AppColors.ethioEmerald.withValues(alpha: 0.14)
                              : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: fasting.isFasting
                                ? AppColors.ethioEmerald.withValues(alpha: 0.35)
                                : AppColors.surfaceBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              fasting.isFasting
                                  ? Icons.spa_rounded
                                  : Icons.restaurant_rounded,
                              size: 14,
                              color: fasting.isFasting
                                  ? AppColors.ethioEmeraldLight
                                  : AppColors.textSecondary,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                fasting.isFasting
                                    ? fasting.reason
                                    : LocaleStrings.get('regular_day', lang),
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: fasting.isFasting
                                      ? AppColors.ethioEmeraldLight
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (settings.showFasting && settings.showMonthlySaints)
                    SizedBox(width: 8),
                  if (settings.showMonthlySaints)
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.ethioGoldPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.ethioGoldPrimary.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: AppColors.ethioGoldLight,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Tooltip(
                                message: saint.significance,
                                child: Text(
                                  saint.nameAmharic,
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ethioGoldLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

          // —— Bahire Hasab context when movable feast lands today ——
          if (hasMovable) ...[
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.ethioIndigoPrimary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.ethioIndigoPrimary.withValues(alpha: 0.28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ባሕረ ሐሳብ',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ethioIndigoLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const CalendarProvenanceBadge(
                        verification: 'verified',
                        subtitle: 'computed',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'መጥቅ ${bahire.metqi} · አበቅቴ ${bahire.abeqte} · ነነዌ ${bahire.nenewe.month}/${bahire.nenewe.day}',
                    style: AppChrome.mute(size: 11),
                  ),
                ],
              ),
            ),
          ],

          if (hasApproximate) ...[
            const SizedBox(height: 8),
            CalendarProvenanceBadge(
              verification: 'approximate_calculated',
              subtitle: 'sighting may differ',
            ),
          ],

          // —— Holidays with provenance badges ——
          if (dateHolidays.isNotEmpty) ...[
            SizedBox(height: 10),
            ...dateHolidays.map((h) {
              final provenance = _holidayProvenance(h);
              final kind = _holidayKindLabel(h);
              final accent = h.type == HolidayType.islamic ||
                      h.type == HolidayType.culturalRegional
                  ? AppColors.verifyApproximate
                  : h.isPublicHoliday
                      ? AppColors.accent
                      : AppColors.ethioIndigoPrimary;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showHolidayDetail(h, today),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event_available_rounded, size: 18, color: accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${h.titleAmharic} (${h.titleEnglish})',
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CalendarProvenanceBadge(
                              verification: provenance,
                              subtitle: kind,
                            ),
                            if (h.description.isNotEmpty) ...[
                              SizedBox(height: 4),
                              Text(
                                h.description,
                                style: AppChrome.mute(size: 11),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              );
            }),
          ],

          // —— Events List for Selected Date ——
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        LocaleStrings.get('events_notes', lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _addEvent(selected),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                      SizedBox(width: 3),
                      Text(
                        LocaleStrings.get('add', lang),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (dateEvents.isEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _addEvent(selected),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.surfaceBorder.withValues(alpha: 0.7),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.note_add_outlined,
                        size: 22,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          LocaleStrings.get('calendar_day_no_events', lang),
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...dateEvents.map((ev) {
              return Container(
                margin: EdgeInsets.only(bottom: 6),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    // Checkbox to toggle completion
                    IconButton(
                      icon: Icon(
                        ev.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: ev.isCompleted ? Color(0xFF10B981) : AppColors.textSecondary,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => ref.read(eventsNotifierProvider.notifier).toggleEventCompletion(ev),
                    ),
                    const SizedBox(width: 8),

                    // Event details
                    Expanded(
                      child: InkWell(
                        onTap: () => _editEvent(ev),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ev.title,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: ev.isCompleted ? TextDecoration.lineThrough : null,
                                color: ev.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ev.isAllDay
                                  ? LocaleStrings.get('all_day', lang)
                                  : '${ev.hour}:${ev.minute.toString().padLeft(2, '0')}',
                              style: AppChrome.mute(size: 10.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Edit Button
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 17, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _editEvent(ev),
                    ),
                    const SizedBox(width: 8),

                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 17, color: Color(0xFFEF4444)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deleteEvent(ev),
                    ),
                  ],
                ),
              );
            }),
            ],
          ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SHARED: period navigation bar (Week / Year / Day) + month highlights
  // ---------------------------------------------------------------------------
  Widget _periodNavBar({
    required String title,
    required String subtitle,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required String prevTooltip,
    required String nextTooltip,
    bool showToday = false,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.95)),
      ),
      child: Row(
        children: [
          _NavIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: prevTooltip,
            onTap: onPrev,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppChrome.mute(size: 11),
                  ),
                ],
              ),
            ),
          ),
          if (showToday) ...[
            _NavIconButton(
              icon: Icons.today_rounded,
              tooltip: 'Jump to today',
              accent: true,
              onTap: _goToday,
            ),
            const SizedBox(width: 4),
          ],
          for (final a in actions) ...[a, const SizedBox(width: 4)],
          _NavIconButton(
            icon: Icons.chevron_right_rounded,
            tooltip: nextTooltip,
            onTap: onNext,
          ),
        ],
      ),
    );
  }

  /// First Julian day and length of a month in the active calendar.
  (int, int) _monthSpan(int year, int month, bool isGreg) {
    if (isGreg) {
      final m = month.clamp(1, 12);
      return (
        EthiopianCalendarEngine.gregorianToJdnYMD(year, m, 1),
        GregorianDate.daysInMonthFor(year, m),
      );
    }
    final m = month.clamp(1, 13);
    return (
      EthiopianCalendarEngine.ethiopianToJdnYMD(year, m, 1),
      EthiopianDate.daysInMonthFor(year, m),
    );
  }

  /// "This month" list under the day inspector: every holiday of the focused
  /// month, tappable to select that day.
  Widget _buildMonthHighlights({
    required int viewYear,
    required int viewMonth,
    required EthiopianDate selected,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    final isGreg = settings.calendarFormat == 'GREGORIAN';
    final isGeez = settings.numeralType == 'GEEZ';
    final (firstJdn, days) = _monthSpan(viewYear, viewMonth, isGreg);

    final rows = <(EthiopianDate, Holiday)>[];
    for (var i = 0; i < days; i++) {
      final eth = EthiopianCalendarEngine.jdnToEthiopian(firstJdn + i);
      for (final h in _holidaysOn(eth)) {
        if (h.type == HolidayType.monthlySaint) continue;
        rows.add((eth, h));
      }
    }
    if (rows.isEmpty) return SizedBox.shrink();

    return Container(
      key: ValueKey('month-highlights'),
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.95)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.celebration_rounded,
                  size: 16, color: AppColors.ethioGoldPrimary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  LocaleStrings.get('holidays_this_month', lang),
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ethioGoldPrimary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${rows.length}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ethioGoldLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final (eth, h) in rows)
            _highlightRow(
              eth: eth,
              holiday: h,
              isSelected: eth == selected,
              isGreg: isGreg,
              isGeez: isGeez,
              lang: lang,
            ),
        ],
      ),
    );
  }

  Widget _highlightRow({
    required EthiopianDate eth,
    required Holiday holiday,
    required bool isSelected,
    required bool isGreg,
    required bool isGeez,
    required AppLanguage lang,
  }) {
    final g = EthiopianCalendarEngine.toGregorian(eth);
    final dow = EthiopianCalendarEngine.getDayOfWeek(eth);
    final approximate = holiday.type == HolidayType.islamic ||
        holiday.type == HolidayType.culturalRegional;
    final accent = approximate
        ? AppColors.verifyApproximate
        : holiday.isPublicHoliday
            ? AppColors.govHolidayGlow
            : AppColors.ethioIndigoLight;
    final dayText = isGreg
        ? '${g.day}'
        : (isGeez ? GeezNumeral.toGeez(eth.day) : '${eth.day}');
    final otherDate = isGreg
        ? '${LocaleStrings.getMonthName(eth.month, lang)} ${eth.day}'
        : '${_monthAbbr(g.month)} ${g.day}';

    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected
            ? accent.withValues(alpha: 0.12)
            : AppColors.surfaceElevated.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(selectedDateProvider.notifier).state = eth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    dayText,
                    style: GoogleFonts.outfit(
                      fontSize: isGeez && !isGreg ? 12 : 14,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateText.holidayTitle(holiday, lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        '${LocaleStrings.getWeekdayLong(dow, lang)} · $otherDate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppChrome.mute(size: 10.5),
                      ),
                    ],
                  ),
                ),
                if (holiday.isPublicHoliday)
                  Icon(Icons.star_rounded,
                      size: 16, color: AppColors.govHolidayGlow),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. WEEK VIEW
  // ---------------------------------------------------------------------------
  Widget _buildWeekView({
    required EthiopianDate centerDate,
    required EthiopianDate today,
    required List<EventEntity> events,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    final centerJdn = EthiopianCalendarEngine.ethiopianToJdn(centerDate);
    final centerDow = EthiopianCalendarEngine.getDayOfWeek(centerDate);
    final isSundayStart = settings.firstDayOfWeek == 'SUNDAY';
    final isGregPrimary = settings.calendarFormat == 'GREGORIAN';
    final isGeez = settings.numeralType == 'GEEZ';
    final offset = isSundayStart ? (centerDow == 7 ? 0 : centerDow) : (centerDow - 1);
    final startOfWeekJdn = centerJdn - offset;

    final weekDates = List.generate(
      7,
      (i) => EthiopianCalendarEngine.jdnToEthiopian(startOfWeekJdn + i),
    );
    final firstD = weekDates.first;
    final lastD = weekDates.last;
    final firstG = EthiopianCalendarEngine.toGregorian(firstD);
    final lastG = EthiopianCalendarEngine.toGregorian(lastD);
    final containsToday = weekDates.contains(today);

    final String title;
    final String subtitle;
    final ethRange = firstD.month == lastD.month
        ? '${LocaleStrings.getMonthName(firstD.month, lang)} ${firstD.day} – ${lastD.day}፣ ${lastD.year}'
        : '${LocaleStrings.getMonthName(firstD.month, lang)} ${firstD.day} – ${LocaleStrings.getMonthName(lastD.month, lang)} ${lastD.day}፣ ${lastD.year}';
    final gregRange = firstG.month == lastG.month
        ? '${_monthAbbr(firstG.month)} ${firstG.day} – ${lastG.day}, ${lastG.year}'
        : '${_monthAbbr(firstG.month)} ${firstG.day} – ${_monthAbbr(lastG.month)} ${lastG.day}, ${lastG.year}';
    if (isGregPrimary) {
      title = gregRange;
      subtitle = ethRange;
    } else {
      title = ethRange;
      subtitle = gregRange;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) => _onSwipe(d, 7),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        children: [
          _periodNavBar(
            title: title,
            subtitle: subtitle,
            prevTooltip: 'Previous week',
            nextTooltip: 'Next week',
            onPrev: () => _shiftSelectedBy(-7),
            onNext: () => _shiftSelectedBy(7),
            showToday: !containsToday,
          ),
          SizedBox(height: 8),

          // Compact 7-day strip for one-tap selection
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: weekDates.map((date) {
                final g = EthiopianCalendarEngine.toGregorian(date);
                final dow = EthiopianCalendarEngine.getDayOfWeek(date);
                final isToday = date == today;
                final isSelected = date == centerDate;
                final hols = _holidaysOn(date);
                final isPublic = hols.any((h) => h.isPublicHoliday);
                final hasEvent = events.any((e) => eventMatchesDate(e, date));
                final num = isGregPrimary
                    ? '${g.day}'
                    : (isGeez ? GeezNumeral.toGeez(date.day) : '${date.day}');
                return Expanded(
                  child: InkWell(
                    key: ValueKey('week-strip-${date.year}-${date.month}-${date.day}'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _focusDate(date),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          LocaleStrings.getWeekdayLong(dow, lang).characters.take(isGregPrimary ? 3 : 2).toString(),
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: dow == 7
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 4),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 160),
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isToday
                                ? AppColors.accent
                                : isSelected
                                    ? AppColors.accent.withValues(alpha: 0.18)
                                    : Colors.transparent,
                            border: isSelected && !isToday
                                ? Border.all(color: AppColors.accent, width: 1.4)
                                : isPublic && !isToday
                                    ? Border.all(color: AppColors.govHolidayGlow, width: 1.4)
                                    : null,
                          ),
                          child: Text(
                            num,
                            style: GoogleFonts.outfit(
                              fontSize: isGeez && !isGregPrimary ? 12 : 14,
                              fontWeight: FontWeight.w800,
                              color: isToday
                                  ? Colors.white
                                  : isPublic
                                      ? AppColors.govHolidayGlow
                                      : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasEvent
                                ? const Color(0xFFEF4444)
                                : hols.isNotEmpty
                                    ? AppColors.ethioIndigoPrimary
                                    : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 7 day cards
          ...weekDates.map((date) {
            final isToday = date == today;
            final isSelected = date == centerDate;
            final dow = EthiopianCalendarEngine.getDayOfWeek(date);
            final gDate = EthiopianCalendarEngine.toGregorian(date);
            final dayHolidays = _holidaysOn(date);
            final hasPublicHoliday = dayHolidays.any((h) => h.isPublicHoliday);
            final dayEvents = events.where((e) => eventMatchesDate(e, date)).toList();
            final saint = HolidayEngine.monthlySaints.firstWhere(
              (s) => s.day == date.day,
              orElse: () => HolidayEngine.monthlySaints.first,
            );
            final fasting = HolidayEngine.isFastingDay(date);
            final ethLabel = '${LocaleStrings.getMonthName(date.month, lang)} ${date.day}';
            final gregLabel = '${_monthAbbr(gDate.month)} ${gDate.day}, ${gDate.year}';
            final circleNum = isGregPrimary
                ? '${gDate.day}'
                : (isGeez ? GeezNumeral.toGeez(date.day) : '${date.day}');

            return Card(
              elevation: 0,
              margin: EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.accent
                      : isToday
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : hasPublicHoliday
                              ? AppColors.govHolidayRing.withValues(alpha: 0.7)
                              : AppColors.surfaceBorder,
                  width: isSelected || isToday || hasPublicHoliday ? 1.5 : 1,
                ),
              ),
              color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _focusDate(date),
                onLongPress: () {
                  _focusDate(date);
                  _addEvent(date);
                },
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: !isToday && hasPublicHoliday
                                  ? LinearGradient(
                                      colors: [
                                        AppColors.govHolidayGlow,
                                        AppColors.govHolidayRing,
                                        AppColors.govHolidayFill,
                                      ],
                                    )
                                  : null,
                              color: isToday
                                  ? AppColors.accent
                                  : hasPublicHoliday
                                      ? null
                                      : isSelected
                                          ? AppColors.accent.withValues(alpha: 0.2)
                                          : AppColors.surfaceElevated,
                              shape: BoxShape.circle,
                              border: !isToday && hasPublicHoliday
                                  ? Border.all(color: Colors.white, width: 2.4)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              circleNum,
                              style: GoogleFonts.outfit(
                                fontSize: isGeez && !isGregPrimary ? 14 : 17,
                                fontWeight: FontWeight.w900,
                                color: isToday
                                    ? Colors.white
                                    : hasPublicHoliday
                                        ? Color(0xFF1A1200)
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${LocaleStrings.getWeekdayLong(dow, lang)} • ${isGregPrimary ? gregLabel : ethLabel}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${isGregPrimary ? '$ethLabel፣ ${date.year}' : gregLabel}'
                                  '${settings.showMonthlySaints ? ' • ${saint.nameAmharic}' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppChrome.mute(size: 11),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 6),
                          if (isToday)
                            _miniBadge(
                              LocaleStrings.get('today', lang),
                              Colors.white,
                              AppColors.accent,
                            )
                          else if (fasting.isFasting && settings.showFasting)
                            _miniBadge(
                              LocaleStrings.get('legend_fast', lang),
                              AppColors.ethioEmeraldLight,
                              AppColors.ethioEmerald.withValues(alpha: 0.18),
                            ),
                        ],
                      ),
                      if (dayHolidays.isNotEmpty) ...[
                        SizedBox(height: 6),
                        ...dayHolidays.map(
                          (h) => Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  h.isPublicHoliday
                                      ? Icons.star_rounded
                                      : Icons.celebration_outlined,
                                  size: 13,
                                  color: h.isPublicHoliday
                                      ? AppColors.govHolidayGlow
                                      : AppColors.accent,
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    DateText.holidayTitle(h, lang),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: h.isPublicHoliday
                                          ? AppColors.govHolidayGlow
                                          : AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (dayEvents.isNotEmpty) ...[
                        SizedBox(height: 4),
                        ...dayEvents.map(
                          (e) => Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(
                                  e.isCompleted
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 14,
                                  color: e.isCompleted
                                      ? AppColors.ethioEmeraldLight
                                      : AppColors.ethioGoldPrimary,
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    e.isAllDay
                                        ? e.title
                                        : '${_formatTime(e.hour, e.minute)}  ${e.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      decoration: e.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: e.isCompleted
                                          ? AppColors.textTertiary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
  }

  // ---------------------------------------------------------------------------
  // 3. YEAR VIEW (13 Ethiopian months, or 12 Gregorian months in GC mode)
  // ---------------------------------------------------------------------------
  void _openMonth(int year, int month) {
    ref.read(calendarViewModeProvider.notifier).state = 'MONTH';
    _updateViewYearMonth(year, month, jump: true);
  }

  Widget _buildYearView({
    required int viewYear,
    required EthiopianDate today,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    final isGreg = settings.calendarFormat == 'GREGORIAN';
    final gToday = EthiopianCalendarEngine.toGregorian(today);
    final isCurrentYear = isGreg ? viewYear == gToday.year : viewYear == today.year;

    final String title;
    final String subtitle;
    if (isGreg) {
      final ecStart = EthiopianCalendarEngine.toEthiopian(GregorianDate(viewYear, 1, 1));
      final ecEnd = EthiopianCalendarEngine.toEthiopian(GregorianDate(viewYear, 12, 31));
      final leap = GregorianDate.daysInMonthFor(viewYear, 2) == 29;
      title = '$viewYear';
      subtitle = '${ecStart.year} – ${ecEnd.year} E.C. • ${leap ? 'Leap year' : '365 days'}';
    } else {
      final evangelist = LeapYearCalculator.getEvangelist(viewYear);
      final isLeap = LeapYearCalculator.isEthiopianLeapYear(viewYear);
      title = DateText.ethiopianYear(viewYear, lang);
      subtitle = '${evangelist.amharicName} • ${isLeap ? 'ጳጉሜ 6 ቀናት' : 'ጳጉሜ 5 ቀናት'}';
    }
    final mini = _yearViewStyle == 'MINI_CALENDARS';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
          child: _periodNavBar(
            title: title,
            subtitle: subtitle,
            prevTooltip: 'Previous year',
            nextTooltip: 'Next year',
            onPrev: () => ref.read(viewYearProvider.notifier).state = viewYear - 1,
            onNext: () => ref.read(viewYearProvider.notifier).state = viewYear + 1,
            showToday: !isCurrentYear,
            actions: [
              _NavIconButton(
                icon: mini ? Icons.view_list_rounded : Icons.grid_view_rounded,
                tooltip: mini ? 'Show month list' : 'Show mini calendars',
                onTap: () => setState(
                  () => _yearViewStyle = mini ? 'TILES' : 'MINI_CALENDARS',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth < 560 ? 3 : (box.maxWidth < 900 ? 4 : 6);
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                itemCount: isGreg ? 12 : 13,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: mini ? 0.74 : 0.92,
                ),
                itemBuilder: (context, index) => mini
                    ? _yearMiniMonth(viewYear, index + 1, today, settings, lang)
                    : _yearMonthTile(viewYear, index + 1, today, settings, lang),
              );
            },
          ),
        ),
      ],
    );
  }

  String _yearMonthName(int month, bool isGreg, AppLanguage lang) =>
      isGreg ? _gregorianMonthName(month) : LocaleStrings.getMonthName(month, lang);

  bool _isCurrentMonth(int year, int month, EthiopianDate today, bool isGreg) {
    final (y, m) = isGreg
        ? (() {
            final g = EthiopianCalendarEngine.toGregorian(today);
            return (g.year, g.month);
          })()
        : (today.year, today.month);
    return y == year && m == month;
  }

  Widget _yearMiniMonth(
    int viewYear,
    int month,
    EthiopianDate today,
    UserSettings settings,
    AppLanguage lang,
  ) {
    final isGreg = settings.calendarFormat == 'GREGORIAN';
    final isSundayStart = settings.firstDayOfWeek == 'SUNDAY';
    final (firstJdn, daysInM) = _monthSpan(viewYear, month, isGreg);
    final firstDow = EthiopianCalendarEngine.getDayOfWeek(
      EthiopianCalendarEngine.jdnToEthiopian(firstJdn),
    );
    final offset = isSundayStart ? (firstDow == 7 ? 0 : firstDow) : (firstDow - 1);
    final isCurrentMonth = _isCurrentMonth(viewYear, month, today, isGreg);
    final isPagume = !isGreg && month == 13;

    var holidayCount = 0;
    final dayCells = List<Widget>.generate(offset + daysInM, (cellIdx) {
      final day = cellIdx - offset + 1;
      if (day < 1) return SizedBox.shrink();
      final eth = EthiopianCalendarEngine.jdnToEthiopian(firstJdn + day - 1);
      final isToday = eth == today;
      final isPublic = _holidaysOn(eth).any((h) => h.isPublicHoliday);
      if (isPublic) holidayCount++;
      final isSunday = (cellIdx % 7) == (isSundayStart ? 0 : 6);
      return Container(
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.accent
              : isPublic
                  ? AppColors.govHolidayGlow.withValues(alpha: 0.2)
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: isToday || isPublic ? FontWeight.bold : FontWeight.normal,
              color: isToday
                  ? Colors.white
                  : isPublic
                      ? AppColors.govHolidayGlow
                      : isSunday
                          ? AppColors.accent
                          : AppColors.textPrimary,
            ),
          ),
        ),
      );
    });

    return InkWell(
      key: ValueKey('year-month-$month'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openMonth(viewYear, month),
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCurrentMonth ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentMonth ? AppColors.accent : AppColors.surfaceBorder,
            width: isCurrentMonth ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              _yearMonthName(month, isGreg, lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: isCurrentMonth || isPagume
                    ? AppColors.accent
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              holidayCount > 0
                  ? (isGreg ? '$daysInM days • ★$holidayCount' : '$daysInM ቀናት • ★$holidayCount')
                  : (isGreg ? '$daysInM days' : '$daysInM ቀናት'),
              maxLines: 1,
              style: AppChrome.mute(size: 8.5),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 7,
                children: dayCells,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearMonthTile(
    int viewYear,
    int month,
    EthiopianDate today,
    UserSettings settings,
    AppLanguage lang,
  ) {
    final isGreg = settings.calendarFormat == 'GREGORIAN';
    final (firstJdn, days) = _monthSpan(viewYear, month, isGreg);
    final isCurrentMonth = _isCurrentMonth(viewYear, month, today, isGreg);
    final isPagume = !isGreg && month == 13;

    // The same span expressed in the other calendar.
    final String otherRange;
    if (isGreg) {
      final a = EthiopianCalendarEngine.jdnToEthiopian(firstJdn);
      final b = EthiopianCalendarEngine.jdnToEthiopian(firstJdn + days - 1);
      otherRange = a.month == b.month
          ? LocaleStrings.getMonthName(a.month, lang)
          : '${LocaleStrings.getMonthName(a.month, lang)} – ${LocaleStrings.getMonthName(b.month, lang)}';
    } else {
      final a = EthiopianCalendarEngine.jdnToGregorian(firstJdn);
      final b = EthiopianCalendarEngine.jdnToGregorian(firstJdn + days - 1);
      otherRange = a.month == b.month
          ? _monthAbbr(a.month)
          : '${_monthAbbr(a.month)} – ${_monthAbbr(b.month)}';
    }
    final secondLine = isGreg
        ? otherRange
        : LocaleStrings.ethiopianMonthsEnglish[month - 1];
    final thirdLine = isGreg ? '$days days' : '$days ቀናት • $otherRange';
    final fourthLine = isGreg
        ? null
        : EthiopianSeason.fromMonth(month).amharicName;

    return InkWell(
      key: ValueKey('year-month-$month'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openMonth(viewYear, month),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrentMonth ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentMonth
                ? AppColors.accent
                : isPagume
                    ? AppColors.accent.withValues(alpha: 0.5)
                    : AppColors.surfaceBorder,
            width: isCurrentMonth ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _yearMonthName(month, isGreg, lang),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isCurrentMonth || isPagume
                    ? AppColors.accent
                    : AppColors.textPrimary,
              ),
            ),
            Text(secondLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppChrome.mute(size: 10)),
            SizedBox(height: 3),
            Text(
              thirdLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 9.5,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (fourthLine != null)
              Text(fourthLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppChrome.mute(size: 8.5)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DAY VIEW
  // ---------------------------------------------------------------------------
  Widget _buildDayView({
    required EthiopianDate selected,
    required EthiopianDate today,
    required List<EventEntity> events,
    required UserSettings settings,
    required AppLanguage lang,
  }) {
    final dow = EthiopianCalendarEngine.getDayOfWeek(selected);
    final gDate = EthiopianCalendarEngine.toGregorian(selected);
    final evangelist = LeapYearCalculator.getEvangelist(selected.year);
    final saint = HolidayEngine.monthlySaints.firstWhere(
      (s) => s.day == selected.day,
      orElse: () => HolidayEngine.monthlySaints.first,
    );
    final fasting = HolidayEngine.isFastingDay(selected);
    final isToday = selected == today;
    final isGregPrimary = settings.calendarFormat == 'GREGORIAN';
    final isGeez = settings.numeralType == 'GEEZ';
    final heritage = DailyHeritageEngine.getHeritageForDate(selected);
    final season = EthiopianSeason.fromMonth(selected.month);
    final weekday = LocaleStrings.getWeekdayLong(dow, lang);
    final monthName = LocaleStrings.getMonthName(selected.month, lang);
    final ethLong = '$monthName ${selected.day}፣ ${selected.year} ዓ.ም';
    final relative = getRelativeDateLabel(today, selected, isGregPrimary);

    final dayEvents = events.where((e) => eventMatchesDate(e, selected)).toList();
    final allDayEvents = dayEvents.where((e) => e.isAllDay).toList();
    final dayHolidays = _holidaysOn(selected);
    final nowHour = isToday ? DateTime.now().hour : -1;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) => _onSwipe(d, 1),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
        children: [
          _periodNavBar(
            title: isGregPrimary
                ? '$weekday, ${_gregorianMonthName(gDate.month)} ${gDate.day}'
                : '$weekday፣ $monthName ${selected.day}',
            subtitle: isGregPrimary
                ? '${gDate.year} • $ethLong'
                : '${selected.year} ዓ.ም • ${_gregorianLong(gDate)}',
            prevTooltip: 'Previous day',
            nextTooltip: 'Next day',
            onPrev: () => _shiftSelectedBy(-1),
            onNext: () => _shiftSelectedBy(1),
            showToday: !isToday,
          ),
          SizedBox(height: 10),

          // Day hero card
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday ? AppColors.accent : AppColors.surfaceBorder,
              ),
              boxShadow: AppChrome.softCard,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.accent
                            : AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isGregPrimary
                            ? '${gDate.day}'
                            : (isGeez
                                ? GeezNumeral.toGeez(selected.day)
                                : '${selected.day}'),
                        style: GoogleFonts.outfit(
                          fontSize: isGeez && !isGregPrimary ? 16 : 20,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isGregPrimary ? _gregorianLong(gDate) : ethLong,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${evangelist.amharicName} • ${season.amharicName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppChrome.mute(size: 12),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    _miniBadge(
                      relative,
                      isToday ? Colors.white : AppColors.accent,
                      isToday
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.14),
                    ),
                  ],
                ),
                if (settings.showFasting || settings.showMonthlySaints) ...[
                  SizedBox(height: 10),
                  Row(
                    children: [
                      if (settings.showFasting)
                        Expanded(
                          child: _dayChip(
                            icon: fasting.isFasting
                                ? Icons.spa_rounded
                                : Icons.restaurant_rounded,
                            label: fasting.isFasting
                                ? fasting.reason
                                : LocaleStrings.get('regular_day', lang),
                            color: fasting.isFasting
                                ? AppColors.ethioEmeraldLight
                                : AppColors.textSecondary,
                            tinted: fasting.isFasting,
                          ),
                        ),
                      if (settings.showFasting && settings.showMonthlySaints)
                        SizedBox(width: 8),
                      if (settings.showMonthlySaints)
                        Expanded(
                          child: _dayChip(
                            icon: Icons.auto_awesome_rounded,
                            label: saint.nameAmharic,
                            color: AppColors.ethioGoldLight,
                            tinted: true,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10),

          // Holidays (tap for details)
          ...dayHolidays.map(
            (h) => Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Material(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showHolidayDetail(h, today),
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          h.isPublicHoliday
                              ? Icons.star_rounded
                              : Icons.celebration_rounded,
                          color: h.isPublicHoliday
                              ? AppColors.govHolidayGlow
                              : AppColors.accent,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.titleAmharic,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                              Text(h.titleEnglish, style: AppChrome.mute(size: 11)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (dayHolidays.isNotEmpty) SizedBox(height: 4),

          // Daily heritage wisdom
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'የዕለቱ ምሳሌያዊ አነጋገር (${heritage.proverb.category})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  '« ${heritage.proverb.amharic} »',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
                SizedBox(height: 2),
                Text(heritage.proverb.meaning, style: AppChrome.mute(size: 11)),
              ],
            ),
          ),
          SizedBox(height: 12),

          // All-day events
          if (allDayEvents.isNotEmpty) ...[
            Text(
              LocaleStrings.get('all_day', lang),
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            ...allDayEvents.map(
              (e) => Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Material(
                  color: AppColors.ethioGoldPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _editEvent(e),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.ethioGoldPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            e.isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.event_rounded,
                            size: 16,
                            color: AppColors.ethioGoldLight,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                decoration: e.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
          ],

          // 24-hour traditional timeline
          Row(
            children: [
              Expanded(
                child: Text(
                  LocaleStrings.get('hours_of_day', lang),
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Add event',
                icon: Icon(Icons.add_rounded,
                    size: 20, color: AppColors.accent),
                onPressed: () => _addEvent(selected),
              ),
            ],
          ),
          SizedBox(height: 2),
          ..._traditionalHours.map((slot) {
            final slotEvents = dayEvents
                .where((e) => !e.isAllDay && e.hour == slot.gregHourStart)
                .toList();
            final isNow = slot.gregHourStart == nowHour;
            final active = slotEvents.isNotEmpty;
            return Container(
              margin: EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : isNow
                        ? AppColors.surfaceElevated
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isNow
                      ? AppColors.accent
                      : active
                          ? AppColors.accent.withValues(alpha: 0.4)
                          : AppColors.surfaceBorder,
                  width: isNow ? 1.4 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Row(
                      children: [
                        if (isNow) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            slot.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: active || isNow
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: active || isNow
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: slotEvents.isEmpty
                        ? Text(
                            isNow ? LocaleStrings.get('now', lang) : '—',
                            style: TextStyle(
                              fontSize: 11,
                              color: isNow
                                  ? AppColors.accent
                                  : AppColors.textTertiary.withValues(alpha: 0.5),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: slotEvents.map((e) {
                              return InkWell(
                                onTap: () => _editEvent(e),
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '${_formatTime(e.hour, e.minute)}  ${e.title}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      decoration: e.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _dayChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool tinted,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: tinted ? color.withValues(alpha: 0.13) : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: tinted ? color.withValues(alpha: 0.32) : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  String _gregorianLong(GregorianDate g) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[g.month - 1]} ${g.day}, ${g.year}';
  }

  String _monthAbbr(int m) {
    const abbrs = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return (m >= 1 && m <= 12) ? abbrs[m - 1] : '';
  }

  String _gregorianMonthName(int m) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return (m >= 1 && m <= 12) ? months[m - 1] : '';
  }

  static const List<_HourSlot> _traditionalHours = [
    _HourSlot(label: 'ጥዋት 12:00 (6:00 AM)', gregHourStart: 6),
    _HourSlot(label: 'ጥዋት 1:00 (7:00 AM)', gregHourStart: 7),
    _HourSlot(label: 'ጥዋት 2:00 (8:00 AM)', gregHourStart: 8),
    _HourSlot(label: 'ጥዋት 3:00 (9:00 AM)', gregHourStart: 9),
    _HourSlot(label: 'ጥዋት 4:00 (10:00 AM)', gregHourStart: 10),
    _HourSlot(label: 'ጥዋት 5:00 (11:00 AM)', gregHourStart: 11),
    _HourSlot(label: 'ቀትር 6:00 (12:00 PM)', gregHourStart: 12),
    _HourSlot(label: 'ከሰዓት 7:00 (1:00 PM)', gregHourStart: 13),
    _HourSlot(label: 'ከሰዓት 8:00 (2:00 PM)', gregHourStart: 14),
    _HourSlot(label: 'ከሰዓት 9:00 (3:00 PM)', gregHourStart: 15),
    _HourSlot(label: 'ከሰዓት 10:00 (4:00 PM)', gregHourStart: 16),
    _HourSlot(label: 'ከሰዓት 11:00 (5:00 PM)', gregHourStart: 17),
    _HourSlot(label: 'ምሽት 12:00 (6:00 PM)', gregHourStart: 18),
    _HourSlot(label: 'ምሽት 1:00 (7:00 PM)', gregHourStart: 19),
    _HourSlot(label: 'ምሽት 2:00 (8:00 PM)', gregHourStart: 20),
    _HourSlot(label: 'ምሽት 3:00 (9:00 PM)', gregHourStart: 21),
    _HourSlot(label: 'ሌሊት 4:00 (10:00 PM)', gregHourStart: 22),
    _HourSlot(label: 'ሌሊት 5:00 (11:00 PM)', gregHourStart: 23),
    _HourSlot(label: 'እኩለ ሌሊት 6:00 (12:00 AM)', gregHourStart: 0),
    _HourSlot(label: 'ሌሊት 7:00 (1:00 AM)', gregHourStart: 1),
    _HourSlot(label: 'ሌሊት 8:00 (2:00 AM)', gregHourStart: 2),
    _HourSlot(label: 'ንጋት 9:00 (3:00 AM)', gregHourStart: 3),
    _HourSlot(label: 'ንጋት 10:00 (4:00 AM)', gregHourStart: 4),
    _HourSlot(label: 'ንጋት 11:00 (5:00 AM)', gregHourStart: 5),
  ];
}

// ---------------------------------------------------------------------------
// MONTH GRID (42-Cell Table — primary day number centered)
// ---------------------------------------------------------------------------
class _MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final EthiopianDate selected;
  final EthiopianDate today;
  final List<EventEntity> events;
  final List<Holiday> Function(EthiopianDate date) holidaysOn;
  final bool isSundayStart;
  final bool isGregPrimary;
  final bool useGeezNumerals;
  final bool showFasting;
  final double cellAspectRatio;
  final void Function(EthiopianDate date, bool inMonth) onSelect;
  final void Function(EthiopianDate date)? onLongPress;

  const _MonthGrid({
    required this.year,
    required this.month,
    required this.selected,
    required this.today,
    required this.events,
    required this.holidaysOn,
    required this.isSundayStart,
    required this.isGregPrimary,
    required this.useGeezNumerals,
    required this.showFasting,
    this.cellAspectRatio = 1.0,
    required this.onSelect,
    this.onLongPress,
  });

  static const _gregAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    // Every cell is derived from a running Julian day number, so leading and
    // trailing days are always real dates (Pagume has only 5 or 6 days).
    final int firstJdn;
    final int daysInMonth;
    if (isGregPrimary) {
      final gMonth = month.clamp(1, 12);
      daysInMonth = GregorianDate.daysInMonthFor(year, gMonth);
      firstJdn = EthiopianCalendarEngine.gregorianToJdnYMD(year, gMonth, 1);
    } else {
      final eMonth = month.clamp(1, 13);
      daysInMonth = EthiopianDate.daysInMonthFor(year, eMonth);
      firstJdn = EthiopianCalendarEngine.ethiopianToJdnYMD(year, eMonth, 1);
    }
    final firstDow = EthiopianCalendarEngine.getDayOfWeek(
      EthiopianCalendarEngine.jdnToEthiopian(firstJdn),
    );
    final lead = isSundayStart ? (firstDow == 7 ? 0 : firstDow) : (firstDow - 1);
    final rowCount = ((lead + daysInMonth) / 7).ceil().clamp(1, 6);
    final targetCellCount = rowCount * 7;
    final cells = List<_CellData>.generate(targetCellCount, (i) {
      final jdn = firstJdn - lead + i;
      return _CellData(
        eth: EthiopianCalendarEngine.jdnToEthiopian(jdn),
        greg: EthiopianCalendarEngine.jdnToGregorian(jdn),
        inMonth: i >= lead && i < lead + daysInMonth,
      );
    });

    return LayoutBuilder(
      builder: (context, gridBox) {
        const spacing = 1.5;
        final cellW = (gridBox.maxWidth - (spacing * 6)) / 7;
        final cellH = (gridBox.maxHeight - (spacing * (rowCount - 1))) / rowCount;
        final dynamicAspect = (gridBox.maxHeight.isFinite &&
                gridBox.maxHeight > 0 &&
                cellW > 0 &&
                cellH > 0)
            ? (cellW / cellH)
            : cellAspectRatio;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: targetCellCount,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: dynamicAspect,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemBuilder: (context, i) {
        final cell = cells[i];
        final g = cell.greg;
        final dow = EthiopianCalendarEngine.getDayOfWeek(cell.eth);
        final isSunday = dow == 7;
        final isSelected = cell.eth.year == selected.year &&
            cell.eth.month == selected.month &&
            cell.eth.day == selected.day;
        final isToday = cell.eth.year == today.year &&
            cell.eth.month == today.month &&
            cell.eth.day == today.day;

        final cellHolidays = holidaysOn(cell.eth);
        final hasPublicHoliday = cellHolidays.any((h) => h.isPublicHoliday);
        final hasReligiousHoliday =
            cellHolidays.any((h) => !h.isPublicHoliday);
        final hasEvent = events.any((e) => eventMatchesDate(e, cell.eth));
        final isFasting =
            showFasting && HolidayEngine.isFastingDay(cell.eth).isFasting;

        final ethNumText =
            useGeezNumerals ? GeezNumeral.toGeez(cell.eth.day) : '${cell.eth.day}';
        final primaryNum = isGregPrimary ? '${g.day}' : ethNumText;
        final emphasize = isToday || isSelected;

        return LayoutBuilder(
          builder: (context, cellBox) {
            final side = cellBox.maxWidth < cellBox.maxHeight
                ? cellBox.maxWidth
                : cellBox.maxHeight;
            final primarySize = (side * 0.38).clamp(14.0, 22.0);
            final circleSize = (side * 0.62).clamp(26.0, 40.0);
            final holidayCircle =
                hasPublicHoliday && cell.inMonth && !isToday
                    ? (circleSize + 3).clamp(28.0, 42.0)
                    : circleSize;

            // Secondary (other-calendar) day in the corner: the dual date.
            final showSecondary =
                cellBox.maxHeight >= 36 && cellBox.maxWidth >= 36;
            final secondaryStartsMonth =
                isGregPrimary ? cell.eth.day == 1 : g.day == 1;
            final secondaryNum = isGregPrimary
                ? ethNumText
                : (g.day == 1 ? _gregAbbr[g.month - 1] : '${g.day}');

            return Material(
              key: ValueKey(
                '${cell.inMonth ? 'cell' : 'pad'}-${cell.eth.year}-${cell.eth.month}-${cell.eth.day}',
              ),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (isSelected && cell.inMonth && onLongPress != null) {
                    // Tapping already-selected date directly opens Add Reminder/Program!
                    onLongPress!(cell.eth);
                  } else {
                    onSelect(cell.eth, cell.inMonth);
                  }
                },
                onDoubleTap: cell.inMonth && onLongPress != null
                    ? () {
                        onSelect(cell.eth, cell.inMonth);
                        onLongPress!(cell.eth);
                      }
                    : null,
                onLongPress: cell.inMonth && onLongPress != null
                    ? () => onLongPress!(cell.eth)
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  // No box on normal days — chrome only for today / selected / holiday.
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.accent.withValues(alpha: 0.22),
                              AppColors.accent.withValues(alpha: 0.08),
                            ],
                          )
                        : isToday
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.12),
                                  AppColors.accent.withValues(alpha: 0.03),
                                ],
                              )
                            : hasPublicHoliday && cell.inMonth
                                ? LinearGradient(
                                    colors: [
                                      AppColors.govHolidayGlow
                                          .withValues(alpha: 0.28),
                                      AppColors.govHolidayFill
                                          .withValues(alpha: 0.12),
                                    ],
                                  )
                                : hasEvent && cell.inMonth
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFFEF4444)
                                              .withValues(alpha: 0.18),
                                          const Color(0xFFEF4444)
                                              .withValues(alpha: 0.05),
                                        ],
                                      )
                                    : null,
                    border: emphasize || (hasPublicHoliday && cell.inMonth) || (hasEvent && cell.inMonth)
                        ? Border.all(
                            width: emphasize ? 1.4 : 1.6,
                            color: isSelected
                                ? AppColors.accent
                                : isToday
                                    ? AppColors.accent
                                        .withValues(alpha: 0.5)
                                    : hasPublicHoliday && cell.inMonth
                                        ? AppColors.govHolidayGlow.withValues(alpha: 0.85)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.7),
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.accent.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : hasPublicHoliday && cell.inMonth
                            ? [
                                BoxShadow(
                                  color: AppColors.govHolidayGlow
                                      .withValues(alpha: 0.22),
                                  blurRadius: 5,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : hasEvent && cell.inMonth
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (showSecondary)
                        Positioned(
                          top: 2.5,
                          left: 4,
                          child: Text(
                            secondaryNum,
                            style: GoogleFonts.outfit(
                              fontSize: (side * 0.2).clamp(8.0, 10.0),
                              fontWeight: secondaryStartsMonth
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1,
                              color: !cell.inMonth
                                  ? AppColors.textTertiary.withValues(alpha: 0.35)
                                  : secondaryStartsMonth
                                      ? AppColors.ethioGoldLight
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      if (hasPublicHoliday && cell.inMonth)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.star_rounded,
                            size: (side * 0.18).clamp(9.0, 13.0),
                            color: AppColors.govHolidayGlow,
                            shadows: [
                              Shadow(
                                color: AppColors.govHolidayFill
                                    .withValues(alpha: 0.9),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                      else if (hasEvent && cell.inMonth)
                        Positioned(
                          top: 2.5,
                          right: 2.5,
                          child: Container(
                            width: (side * 0.14).clamp(5.0, 7.5),
                            height: (side * 0.14).clamp(5.0, 7.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.7),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      Center(
                        child: Container(
                          width: holidayCircle,
                          height: holidayCircle,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isToday
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.accent,
                                      Color.lerp(
                                            AppColors.accent,
                                            AppColors.ethioGoldPrimary,
                                            0.28,
                                          ) ??
                                          AppColors.accent,
                                    ],
                                  )
                                : hasPublicHoliday && cell.inMonth
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.govHolidayGlow,
                                          AppColors.govHolidayRing,
                                          AppColors.govHolidayFill,
                                        ],
                                      )
                                    : null,
                            color: isToday ||
                                    (hasPublicHoliday && cell.inMonth)
                                ? null
                                : isSelected
                                    ? AppColors.accent
                                        .withValues(alpha: 0.16)
                                    : Colors.transparent,
                            border: !isToday &&
                                    hasPublicHoliday &&
                                    cell.inMonth
                                ? Border.all(
                                    color: Colors.white,
                                    width: 2.4,
                                  )
                                : null,
                            boxShadow: !isToday &&
                                    hasPublicHoliday &&
                                    cell.inMonth
                                ? [
                                    BoxShadow(
                                      color: AppColors.govHolidayGlow
                                          .withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      spreadRadius: 0.5,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            primaryNum,
                            style: GoogleFonts.outfit(
                              fontSize: useGeezNumerals && !isGregPrimary
                                  ? primarySize * 0.92
                                  : primarySize,
                              fontWeight: emphasize ||
                                      (hasPublicHoliday && cell.inMonth)
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              height: 1,
                              color: isToday
                                  ? Colors.white
                                  : hasPublicHoliday && cell.inMonth
                                      ? Color(0xFF1A1200)
                                      : !cell.inMonth
                                          ? AppColors.textTertiary
                                              .withValues(alpha: 0.4)
                                          : isSelected
                                              ? AppColors.accent
                                              : isSunday
                                                  ? AppColors.accent
                                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      if (cell.inMonth &&
                          (hasPublicHoliday ||
                              hasReligiousHoliday ||
                              hasEvent ||
                              isFasting))
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (hasPublicHoliday)
                                _dot(AppColors.govHolidayGlow, size: 6.5),
                              if (hasReligiousHoliday)
                                _dot(AppColors.ethioIndigoPrimary),
                              if (hasEvent) _dot(const Color(0xFFEF4444), size: 4.8),
                              if (isFasting)
                                _dot(AppColors.ethioEmerald, size: 3.2),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  },
);
  }

  Widget _dot(Color color, {double size = 3.8}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1.2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool accent;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ? AppColors.accent : AppColors.textPrimary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.canvas.withValues(alpha: 0.35),
              border: Border.all(
                color: accent
                    ? AppColors.accent.withValues(alpha: 0.35)
                    : AppColors.surfaceBorder.withValues(alpha: 0.8),
              ),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
        ),
      ),
    );
  }
}

class _CellData {
  final EthiopianDate eth;
  final GregorianDate greg;
  final bool inMonth;
  const _CellData({required this.eth, required this.greg, required this.inMonth});
}

class _HourSlot {
  final String label;
  final int gregHourStart;
  const _HourSlot({required this.label, required this.gregHourStart});
}

