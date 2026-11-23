import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/world/world_country_engine.dart';
import '../../shared/components/app_chrome.dart';

class AgeAndDifferenceTab extends StatefulWidget {
  final AppLanguage currentLang;
  /// 0 = Age, 1 = Date Math (span). Used by Convert/Age/Date Math tabs.
  final int initialMode;
  final bool hideModeSwitcher;

  const AgeAndDifferenceTab({
    super.key,
    required this.currentLang,
    this.initialMode = 0,
    this.hideModeSwitcher = false,
  });

  @override
  State<AgeAndDifferenceTab> createState() => _AgeAndDifferenceTabState();
}

class _AgeAndDifferenceTabState extends State<AgeAndDifferenceTab> {
  late int _modeIndex; // 0: Age Calculator, 1: Date Difference

  int _birthYear = 1990;
  int _birthMonth = 1;
  int _birthDay = 1;

  int _startYear = 2010;
  int _startMonth = 1;
  int _startDay = 1;

  int _endYear = 2017;
  int _endMonth = 1;
  int _endDay = 1;

  @override
  void initState() {
    super.initState();
    _modeIndex = widget.initialMode.clamp(0, 1);
    final today = EthiopianCalendarEngine.todayEthiopian();
    _endYear = today.year;
    _endMonth = today.month;
    _endDay = today.day;
  }

  @override
  void didUpdateWidget(covariant AgeAndDifferenceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      setState(() => _modeIndex = widget.initialMode.clamp(0, 1));
    }
  }

  InputDecoration _field(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary, fontSize: 12),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent),
      ),
    );
  }

  void _clampDays() {
    final maxBirth = EthiopianDate.daysInMonthFor(_birthYear, _birthMonth);
    final maxStart = EthiopianDate.daysInMonthFor(_startYear, _startMonth);
    final maxEnd = EthiopianDate.daysInMonthFor(_endYear, _endMonth);
    if (_birthDay > maxBirth) _birthDay = maxBirth;
    if (_startDay > maxStart) _startDay = maxStart;
    if (_endDay > maxEnd) _endDay = maxEnd;
  }

  @override
  Widget build(BuildContext context) {
    final todayEth = EthiopianCalendarEngine.todayEthiopian();
    _clampDays();

    final birthDate = EthiopianDate(_birthYear, _birthMonth, _birthDay);
    final ageDiff = WorldCountryEngine.calculateDifference(birthDate, todayEth);

    final startDate = EthiopianDate(_startYear, _startMonth, _startDay);
    final endDate = EthiopianDate(_endYear, _endMonth, _endDay);
    final spanDiff = WorldCountryEngine.calculateDifference(startDate, endDate);

    final maxBirthDays = EthiopianDate.daysInMonthFor(_birthYear, _birthMonth);
    final maxStartDays = EthiopianDate.daysInMonthFor(_startYear, _startMonth);
    final maxEndDays = EthiopianDate.daysInMonthFor(_endYear, _endMonth);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (!widget.hideModeSwitcher) ...[
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModePill(
                    label: 'Age',
                    selected: _modeIndex == 0,
                    onTap: () => setState(() => _modeIndex = 0),
                  ),
                ),
                Expanded(
                  child: _ModePill(
                    label: 'Span',
                    selected: _modeIndex == 1,
                    onTap: () => setState(() => _modeIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
        ],

        if (_modeIndex == 0) ...[
          _SectionCard(
            title: 'Birthdate (Ethiopian)',
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('bm_$_birthMonth'),
                    initialValue: _birthMonth,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: _field('Month'),
                    items: List.generate(13, (i) => i + 1).map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(
                          LocaleStrings.getMonthName(m, widget.currentLang),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _birthMonth = val ?? 1),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('bd_$_birthDay'),
                    initialValue: _birthDay.clamp(1, maxBirthDays),
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: _field('Day'),
                    items: List.generate(maxBirthDays, (i) => i + 1).map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text('$d', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _birthDay = val ?? 1),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    key: ValueKey('by_$_birthYear'),
                    initialValue: _birthYear,
                    dropdownColor: AppColors.surface,
                    style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    decoration: _field('Year'),
                    items: List.generate(100, (i) => todayEth.year - i).map((y) {
                      return DropdownMenuItem(
                        value: y,
                        child: Text('$y', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _birthYear = val ?? 1990),
                  ),
                ),
              ],
            ),
          ),
          if (ageDiff.totalDays < 0) ...[
            const SizedBox(height: 14),
            const _ErrorNoticeCard(
              title: 'የተሳሳተ የልደት ቀን (Invalid Birthdate)',
              message:
                  'የተመረጠው የልደት ቀን ከዛሬ ቀን መብለጥ አይችልም። እባክዎ ያለፈ ቀን ይምረጡ።\n(Birthdate cannot be in the future. Please select a past date.)',
            ),
          ] else ...[
            const SizedBox(height: 14),
            _ResultHero(
              eyebrow: 'YOUR AGE',
              headline:
                  '${ageDiff.ethiopianYears}y  ${ageDiff.ethiopianMonths}m  ${ageDiff.ethiopianDays}d',
              subtitle: 'As of today · Ethiopian calendar',
              stats: [
                _Stat('Days', '${ageDiff.totalDays}'),
                _Stat('Weeks', '${ageDiff.totalWeeks}'),
                _Stat('Hours', '${ageDiff.totalDays.abs() * 24}'),
              ],
            ),
          ],
        ] else ...[
          _SectionCard(
            title: 'Start date',
            child: _DateRow(
              month: _startMonth,
              day: _startDay.clamp(1, maxStartDays),
              year: _startYear,
              maxDays: maxStartDays,
              yearItems: List.generate(50, (i) => todayEth.year - 30 + i),
              lang: widget.currentLang,
              field: _field,
              onMonth: (v) => setState(() => _startMonth = v),
              onDay: (v) => setState(() => _startDay = v),
              onYear: (v) => setState(() => _startYear = v),
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'End date',
            child: _DateRow(
              month: _endMonth,
              day: _endDay.clamp(1, maxEndDays),
              year: _endYear,
              maxDays: maxEndDays,
              yearItems: List.generate(50, (i) => todayEth.year - 30 + i),
              lang: widget.currentLang,
              field: _field,
              onMonth: (v) => setState(() => _endMonth = v),
              onDay: (v) => setState(() => _endDay = v),
              onYear: (v) => setState(() => _endYear = v),
            ),
          ),
          if (spanDiff.totalDays < 0) ...[
            const SizedBox(height: 14),
            const _ErrorNoticeCard(
              title: 'የተሳሳተ የጊዜ ቅደም ተከተል (Invalid Date Range)',
              message:
                  'የመጀመሪያው ቀን ከመጨረሻው ቀን ማለፍ አይችልም። እባክዎ ቅደም ተከተሉን ያስተካክሉ።\n(Start date cannot be after end date. Please adjust the range.)',
            ),
          ] else ...[
            const SizedBox(height: 14),
            _ResultHero(
              eyebrow: 'DIFFERENCE',
              headline: '${spanDiff.totalDays} days',
              subtitle:
                  '${spanDiff.ethiopianYears} years · ${spanDiff.ethiopianMonths} months · ${spanDiff.ethiopianDays} days',
              stats: [
                _Stat('Years', '${spanDiff.ethiopianYears}'),
                _Stat('Months', '${spanDiff.ethiopianMonths}'),
                _Stat('Days', '${spanDiff.ethiopianDays}'),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModePill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppChrome.card(radius: 16),
      padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  final int month;
  final int day;
  final int year;
  final int maxDays;
  final List<int> yearItems;
  final AppLanguage lang;
  final InputDecoration Function(String) field;
  final ValueChanged<int> onMonth;
  final ValueChanged<int> onDay;
  final ValueChanged<int> onYear;

  const _DateRow({
    required this.month,
    required this.day,
    required this.year,
    required this.maxDays,
    required this.yearItems,
    required this.lang,
    required this.field,
    required this.onMonth,
    required this.onDay,
    required this.onYear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('m_$month'),
            initialValue: month,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: field('Month'),
            items: List.generate(13, (i) => i + 1).map((m) {
              return DropdownMenuItem(
                value: m,
                child: Text('$m', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => onMonth(val ?? 1),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('d_$day'),
            initialValue: day,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: field('Day'),
            items: List.generate(maxDays, (i) => i + 1).map((d) {
              return DropdownMenuItem(
                value: d,
                child: Text('$d', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => onDay(val ?? 1),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<int>(
            key: ValueKey('y_$year'),
            initialValue: yearItems.contains(year) ? year : yearItems.first,
            dropdownColor: AppColors.surface,
            style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
            decoration: field('Year'),
            items: yearItems.map((y) {
              return DropdownMenuItem(
                value: y,
                child: Text('$y', style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) => onYear(val ?? year),
          ),
        ),
      ],
    );
  }
}

class _ErrorNoticeCard extends StatelessWidget {
  final String title;
  final String message;

  const _ErrorNoticeCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ethioRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ethioRed.withValues(alpha: 0.35)),
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
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ethioRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
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
    );
  }
}

class _Stat {
  final String label;
  final String value;
  const _Stat(this.label, this.value);
}

class _ResultHero extends StatelessWidget {
  final String eyebrow;
  final String headline;
  final String subtitle;
  final List<_Stat> stats;

  const _ResultHero({
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        children: [
          Text(
            eyebrow,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.accent,
            ),
          ),
          SizedBox(height: 8),
          Text(
            headline,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: stats.map((s) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.value,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        s.label,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
