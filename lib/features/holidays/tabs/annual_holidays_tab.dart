import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../shared/providers.dart';

/// How far ahead the multi-year “Upcoming” horizon can look.
const int kHolidayHorizonMaxYears = 20;

class AnnualHolidaysTab extends ConsumerStatefulWidget {
  final int selectedYear;
  final ValueChanged<int> onYearChange;
  final ValueChanged<Holiday> onSelectHolidayForDetail;
  final ValueChanged<Holiday> onOpenReminder;
  final ValueChanged<Holiday> onOpenCardShare;
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const AnnualHolidaysTab({
    super.key,
    required this.selectedYear,
    required this.onYearChange,
    required this.onSelectHolidayForDetail,
    required this.onOpenReminder,
    required this.onOpenCardShare,
    this.onNavigateToCalendar,
  });

  @override
  ConsumerState<AnnualHolidaysTab> createState() => _AnnualHolidaysTabState();
}

class _AnnualHolidaysTabState extends ConsumerState<AnnualHolidaysTab> {
  String _categoryFilter = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// `false` = single Ethiopian year; `true` = upcoming across horizon years.
  bool _horizonMode = false;
  int _horizonYears = 5;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Holiday> _holidaysForMode(EthiopianDate todayEth) {
    if (_horizonMode) {
      return HolidayEngine.getUpcomingHolidays(
        fromDate: todayEth,
        yearsAhead: _horizonYears,
      );
    }
    return HolidayEngine.getHolidaysForYear(widget.selectedYear);
  }

  List<Holiday> _applyFilters(List<Holiday> holidays) {
    return holidays.where((h) {
      final matchesQuery = _searchQuery.isEmpty ||
          h.titleAmharic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          h.titleEnglish.toLowerCase().contains(_searchQuery.toLowerCase());

      bool matchesCategory = true;
      if (_categoryFilter == 'PUBLIC') {
        matchesCategory =
            h.isPublicHoliday || h.type == HolidayType.nationalPublic;
      } else if (_categoryFilter == 'ORTHODOX') {
        matchesCategory = h.type == HolidayType.orthodoxMajor ||
            h.type == HolidayType.orthodoxMovable;
      } else if (_categoryFilter == 'ISLAMIC') {
        matchesCategory = h.type == HolidayType.islamic;
      } else if (_categoryFilter == 'CULTURAL') {
        matchesCategory = h.type == HolidayType.culturalRegional;
      }

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLang = ref.watch(currentAppLanguageProvider);
    final todayEth = ref.watch(todayEthiopianProvider);
    final minYear = todayEth.year - 2;
    final maxYear = todayEth.year + kHolidayHorizonMaxYears;

    final holidays = _applyFilters(_holidaysForMode(todayEth));

    // Group by Ethiopian year in horizon mode for sticky year headers.
    final sections = <int, List<Holiday>>{};
    for (final h in holidays) {
      sections.putIfAbsent(h.ethiopianDate.year, () => []).add(h);
    }
    final yearKeys = sections.keys.toList()..sort();

    final itemCount = _horizonMode
        ? yearKeys.fold<int>(
            0,
            (sum, y) => sum + 1 + sections[y]!.length,
          )
        : holidays.length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('ዓመት', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.calendar_today, size: 16),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('ወደፊት', style: TextStyle(fontSize: 12)),
                      icon: Icon(Icons.upcoming, size: 16),
                    ),
                  ],
                  selected: {_horizonMode},
                  onSelectionChanged: (s) =>
                      setState(() => _horizonMode = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!_horizonMode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: widget.selectedYear > minYear
                      ? () => widget.onYearChange(widget.selectedYear - 1)
                      : null,
                ),
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelText: 'ዓ.ም (Ethiopian year)',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        value: widget.selectedYear.clamp(minYear, maxYear),
                        items: [
                          for (var y = minYear; y <= maxYear; y++)
                            DropdownMenuItem(
                              value: y,
                              child: Text(
                                '$y ዓ.ም${y == todayEth.year ? ' · ዛሬ' : ''}',
                                style: GoogleFonts.outfit(
                                  fontWeight: y == widget.selectedYear
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                        onChanged: (y) {
                          if (y != null) widget.onYearChange(y);
                        },
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: widget.selectedYear < maxYear
                      ? () => widget.onYearChange(widget.selectedYear + 1)
                      : null,
                ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.alarm_add, size: 16),
                  label: Text(
                    'መዝግብ',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    final count = await ref
                        .read(eventsNotifierProvider.notifier)
                        .scheduleAllAnnualHolidays(year: widget.selectedYear);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$count በዓላት ተመዝግበዋል (Scheduled $count)',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming holidays · next $_horizonYears years'
                  ' (${todayEth.year}–${todayEth.year + _horizonYears} ዓ.ም)',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final years in [5, 10, 15, 20]) ...[
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              '+$years ዓመት',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            selected: _horizonYears == years,
                            selectedColor:
                                AppColors.govHolidayRing.withValues(alpha: 0.35),
                            onSelected: (_) =>
                                setState(() => _horizonYears = years),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Quick jump chips in single-year mode
        if (!_horizonMode)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                for (final y in [
                  todayEth.year,
                  todayEth.year + 1,
                  todayEth.year + 5,
                  todayEth.year + 10,
                  todayEth.year + 20,
                ])
                  Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        y == todayEth.year ? 'ዛሬ $y' : '$y',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: y == widget.selectedYear
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : null,
                      onPressed: () => widget.onYearChange(y),
                    ),
                  ),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'በዓላትን ይፈልጉ (Search holidays)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),
        const SizedBox(height: 8),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('ALL', 'ሁሉም (All)'),
              const SizedBox(width: 6),
              _buildFilterChip('PUBLIC', 'የሕዝብ (Public)'),
              const SizedBox(width: 6),
              _buildFilterChip('ORTHODOX', 'ተዋሕዶ (Orthodox)'),
              const SizedBox(width: 6),
              _buildFilterChip('ISLAMIC', 'እስልምና (Islamic)'),
              const SizedBox(width: 6),
              _buildFilterChip('CULTURAL', 'ባህላዊ (Cultural)'),
            ],
          ),
        ),
        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${holidays.length} holidays'
              '${_horizonMode ? ' · ${_horizonYears}yr horizon' : ' · ${widget.selectedYear} ዓ.ም'}',
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
              const SizedBox(height: 4),
            ],
          ),
        ),
        if (holidays.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text('ምንም በዓል አልተገኘም (No holidays found)'),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (!_horizonMode) {
                    return _HolidayCard(
                      holiday: holidays[index],
                      todayEth: todayEth,
                      lang: currentLang,
                      showYear: false,
                      onDetail: widget.onSelectHolidayForDetail,
                      onReminder: widget.onOpenReminder,
                      onCard: widget.onOpenCardShare,
                      onCalendar: widget.onNavigateToCalendar,
                    );
                  }

                  // Flatten year header + cards
                  var cursor = 0;
                  for (final y in yearKeys) {
                    final items = sections[y]!;
                    if (index == cursor) {
                      return _YearHeader(
                        year: y,
                        count: items.length,
                        isCurrent: y == todayEth.year,
                      );
                    }
                    cursor++;
                    if (index < cursor + items.length) {
                      final h = items[index - cursor];
                      return _HolidayCard(
                        holiday: h,
                        todayEth: todayEth,
                        lang: currentLang,
                        showYear: true,
                        onDetail: widget.onSelectHolidayForDetail,
                        onReminder: widget.onOpenReminder,
                        onCard: widget.onOpenCardShare,
                        onCalendar: widget.onNavigateToCalendar,
                      );
                    }
                    cursor += items.length;
                  }
                  return const SizedBox.shrink();
                },
                childCount: itemCount,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String cat, String label) {
    final isSelected = _categoryFilter == cat;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => setState(() => _categoryFilter = cat),
    );
  }
}

class _YearHeader extends StatelessWidget {
  final int year;
  final int count;
  final bool isCurrent;

  const _YearHeader({
    required this.year,
    required this.count,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.govHolidayRing.withValues(alpha: 0.18)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent
                ? AppColors.govHolidayRing
                : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          '$year ዓ.ም · $count holidays${isCurrent ? ' · current' : ''}',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isCurrent
                ? AppColors.govHolidayGlow
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  final Holiday holiday;
  final EthiopianDate todayEth;
  final AppLanguage lang;
  final bool showYear;
  final ValueChanged<Holiday> onDetail;
  final ValueChanged<Holiday> onReminder;
  final ValueChanged<Holiday> onCard;
  final ValueChanged<EthiopianDate>? onCalendar;

  const _HolidayCard({
    required this.holiday,
    required this.todayEth,
    required this.lang,
    required this.showYear,
    required this.onDetail,
    required this.onReminder,
    required this.onCard,
    this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final h = holiday;
    final dow = EthiopianCalendarEngine.getDayOfWeek(h.ethiopianDate);
    final gDate = EthiopianCalendarEngine.toGregorian(h.ethiopianDate);
    final monthName =
        LocaleStrings.getMonthName(h.ethiopianDate.month, lang);
    final daysDiff =
        EthiopianCalendarEngine.daysBetween(todayEth, h.ethiopianDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onDetail(h),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (h.isPublicHoliday) ...[
                              Icon(
                                Icons.star_rounded,
                                size: 16,
                                color: AppColors.govHolidayGlow,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Text(
                                h.titleAmharic,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          h.titleEnglish,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: daysDiff == 0
                          ? const Color(0xFF10B981)
                          : daysDiff > 0
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      daysDiff == 0
                          ? 'ዛሬ'
                          : daysDiff > 0
                              ? '$daysDiff ቀናት ቀሩ'
                              : '${-daysDiff} ቀናት በፊት',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: daysDiff == 0
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$monthName ${h.ethiopianDate.day}'
                      '${showYear ? ', ${h.ethiopianDate.year}' : ''}'
                      ' (${LocaleStrings.getWeekdayShort(dow, lang)})'
                      ' • ${gDate.day}/${gDate.month}/${gDate.year} G.C.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_active, size: 18),
                        tooltip: 'ማሳሰቢያ አዘጋጅ',
                        onPressed: () => onReminder(h),
                      ),
                      IconButton(
                        icon: const Icon(Icons.card_giftcard, size: 18),
                        tooltip: 'የበዓል ካርድ',
                        onPressed: () => onCard(h),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_month, size: 18),
                        tooltip: 'በካላንደር እይ',
                        onPressed: () => onCalendar?.call(h.ethiopianDate),
                      ),
                    ],
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
