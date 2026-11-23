import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/calendar/ethiopian_time_converter.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../data/models/event_entity.dart';

/// Add / edit reminder or event — sticky save bar, dual dates, responsive.
class AddEditEventDialog extends StatefulWidget {
  final EthiopianDate initialDate;
  final EventEntity? eventToEdit;
  final AppLanguage currentLanguage;
  final VoidCallback onDismiss;
  final ValueChanged<EventEntity> onSave;

  const AddEditEventDialog({
    super.key,
    required this.initialDate,
    this.eventToEdit,
    this.currentLanguage = AppLanguage.amharic,
    required this.onDismiss,
    required this.onSave,
  });

  static Future<EventEntity?> open(
    BuildContext context, {
    required EthiopianDate initialDate,
    EventEntity? eventToEdit,
    AppLanguage currentLanguage = AppLanguage.amharic,
  }) {
    return showModalBottomSheet<EventEntity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final inset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: AddEditEventDialog(
            initialDate: initialDate,
            eventToEdit: eventToEdit,
            currentLanguage: currentLanguage,
            onDismiss: () => Navigator.of(ctx).pop(),
            onSave: (event) => Navigator.of(ctx).pop(event),
          ),
        );
      },
    );
  }

  static void showSavedFeedback(
    BuildContext context, {
    required bool isEdit,
    String? title,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final label = isEdit
        ? 'ክስተቱ ተስተካክሏል · Event updated'
        : 'ክስተቱ ተቀምጧል · Event saved';
    final detail = (title == null || title.trim().isEmpty)
        ? label
        : '$label\n“${title.trim()}”';
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                detail,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F7A3F),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  State<AddEditEventDialog> createState() => _AddEditEventDialogState();
}

class _AddEditEventDialogState extends State<AddEditEventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _titleFocus = FocusNode();
  String? _titleError;
  bool _saving = false;
  late String _category;
  late int _ethYear;
  late int _ethMonth;
  late int _ethDay;
  late bool _isAllDay;
  late int _hour;
  late int _minute;
  late String _recurrence;
  late int _reminderMinutes;
  late String _colorHex;

  final _categories = const [
    ('TASK', 'cat_task_one', Icons.check_circle_outline_rounded),
    ('MEETING', 'cat_meeting_one', Icons.groups_rounded),
    ('BIRTHDAY', 'cat_birthday_one', Icons.cake_rounded),
    ('EXAM', 'cat_exam_one', Icons.school_rounded),
    ('ANNIVERSARY', 'cat_anniversary_one', Icons.favorite_border_rounded),
    ('RELIGIOUS', 'cat_religious', Icons.temple_buddhist_rounded),
    ('CULTURAL', 'cat_cultural', Icons.public_rounded),
    ('OTHER', 'cat_other', Icons.more_horiz_rounded),
  ];

  final _reminders = const [
    (-1, 'reminder_none'),
    (0, 'reminder_at_time'),
    (5, 'reminder_5min'),
    (15, 'reminder_15min'),
    (30, 'reminder_30min'),
    (60, 'reminder_1hour'),
    (1440, 'reminder_1day'),
  ];

  String _s(String key) => LocaleStrings.get(key, widget.currentLanguage);

  final _colors = const [
    '#EF4444',
    '#F59E0B',
    '#10B981',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
    '#06B6D4',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.eventToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');
    _category = edit?.category ?? 'TASK';
    _ethYear = edit?.ethiopianYear ?? widget.initialDate.year;
    _ethMonth = edit?.ethiopianMonth ?? widget.initialDate.month;
    _ethDay = edit?.ethiopianDay ?? widget.initialDate.day;
    if (edit != null) {
      _isAllDay = edit.isAllDay;
      _hour = edit.hour;
      _minute = edit.minute;
    } else {
      final now = TimeOfDay.now();
      _isAllDay = false;
      _hour = now.hour;
      _minute = (now.minute ~/ 5) * 5;
    }
    _recurrence = edit?.recurrence ?? 'NONE';
    _reminderMinutes = edit?.reminderMinutesBefore ?? 15;
    _colorHex = edit?.colorHex ?? '#EF4444';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _scrollController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  InputDecoration _fieldDecoration(
    String label, {
    IconData? icon,
    String? errorText,
  }) {
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFC62828), width: 1.4),
    );
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.textSecondary, size: 20),
      errorText: errorText,
      errorStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: AppColors.canvas,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        borderSide: BorderSide(color: AppColors.accent, width: 1.4),
      ),
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
    );
  }

  void _clampDayToMonth() {
    final maxDays = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
    if (_ethDay > maxDays) _ethDay = maxDays;
  }

  void _setMonth(int month) {
    setState(() {
      _ethMonth = month;
      _clampDayToMonth();
    });
  }

  void _setYear(int year) {
    setState(() {
      _ethYear = year;
      _clampDayToMonth();
    });
  }

  void _save() {
    if (_saving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = _s('event_title_required'));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
      _titleFocus.requestFocus();
      return;
    }

    setState(() {
      _titleError = null;
      _saving = true;
    });

    try {
      _clampDayToMonth();
      final greg = EthiopianCalendarEngine.toGregorian(
        EthiopianDate(_ethYear, _ethMonth, _ethDay),
      );
      widget.onSave(
        EventEntity(
          id: widget.eventToEdit?.id ?? 0,
          title: title,
          description: _descController.text.trim(),
          category: _category,
          ethiopianYear: _ethYear,
          ethiopianMonth: _ethMonth,
          ethiopianDay: _ethDay,
          gregorianYear: greg.year,
          gregorianMonth: greg.month,
          gregorianDay: greg.day,
          hour: _isAllDay ? 8 : _hour,
          minute: _isAllDay ? 0 : _minute,
          isAllDay: _isAllDay,
          recurrence: _recurrence,
          reminderMinutesBefore: _reminderMinutes,
          colorHex: _colorHex,
          isCompleted: widget.eventToEdit?.isCompleted ?? false,
          createdAt: widget.eventToEdit?.createdAt ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _s('event_save_failed'),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final brightness = Theme.of(context).brightness;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      helpText: _s('event_select_time'),
      builder: (context, child) {
        final base = brightness == Brightness.dark
            ? ThemeData.dark(useMaterial3: true)
            : ThemeData.light(useMaterial3: true);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: AppColors.accent,
              secondary: AppColors.accentSoft,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hour = picked.hour;
      _minute = picked.minute;
      _isAllDay = false;
    });
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.35,
      ),
    );
  }

  Widget _datePickers({required int maxDays, required int safeDay}) {
    Widget month() => DropdownButtonFormField<int>(
          key: ValueKey('em_$_ethMonth'),
          initialValue: _ethMonth,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
          decoration: _fieldDecoration(_s('event_field_month')),
          items: List.generate(13, (i) => i + 1).map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(
                LocaleStrings.getMonthName(m, widget.currentLanguage),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (val) => _setMonth(val ?? 1),
        );

    Widget day() => DropdownButtonFormField<int>(
          key: ValueKey('ed_${_ethYear}_${_ethMonth}_$maxDays'),
          initialValue: safeDay,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
          decoration: _fieldDecoration(_s('event_field_day')),
          items: List.generate(maxDays, (i) => i + 1)
              .map((d) => DropdownMenuItem(value: d, child: Text('$d')))
              .toList(),
          onChanged: (val) => setState(() => _ethDay = val ?? 1),
        );

    Widget year() => DropdownButtonFormField<int>(
          key: ValueKey('ey_$_ethYear'),
          initialValue: _ethYear,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 13),
          decoration: _fieldDecoration(_s('event_field_year')),
          items: List.generate(12, (i) => _ethYear - 5 + i)
              .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
              .toList(),
          onChanged: (val) => _setYear(val ?? 2017),
        );

    final r = AppResponsive(context);
    if (r.width < 380) {
      return Column(
        children: [
          month(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: day()),
              const SizedBox(width: 8),
              Expanded(child: year()),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 5, child: month()),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: day()),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: year()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);
    final maxDays = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
    final safeDay = _ethDay.clamp(1, maxDays);
    if (safeDay != _ethDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final latestMax = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
        if (_ethDay > latestMax) setState(() => _ethDay = latestMax);
      });
    }

    final greg = EthiopianCalendarEngine.toGregorian(
      EthiopianDate(_ethYear, _ethMonth, safeDay),
    );
    final monthName =
        LocaleStrings.getMonthName(_ethMonth, widget.currentLanguage);
    final ethTime =
        EthiopianTimeConverter.gregorianToEthiopian(_hour, _minute);
    final isEdit = widget.eventToEdit != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenH = MediaQuery.sizeOf(context).height;
        final available = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : screenH;
        final target = (screenH *
                (r.isVeryShort ? 0.96 : (r.isShort ? 0.94 : 0.90)))
            .clamp(360.0, 900.0);
        final sheetHeight = available < target ? available : target;

        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: r.isExpanded ? 560 : double.infinity,
              maxHeight: sheetHeight,
            ),
            child: Material(
              color: AppColors.surface,
              elevation: 8,
              shadowColor: Colors.black26,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 8, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _s(isEdit
                                    ? 'event_dialog_edit'
                                    : 'event_dialog_add'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: r.font(17),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$monthName $safeDay · ${greg.day}/${greg.month}/${greg.year} ${_s('era_gc')}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        focusNode: _titleFocus,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary),
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          if (_titleError != null) {
                            setState(() => _titleError = null);
                          }
                        },
                        decoration: _fieldDecoration(
                          _s('event_field_title'),
                          icon: Icons.title_rounded,
                          errorText: _titleError,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descController,
                        style: GoogleFonts.outfit(color: AppColors.textPrimary),
                        maxLines: 2,
                        decoration: _fieldDecoration(
                          _s('event_field_notes'),
                          icon: Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel(_s('event_section_category')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categories.map((c) {
                          final selected = _category == c.$1;
                          return InkWell(
                            onTap: () => setState(() => _category = c.$1),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.accent.withValues(alpha: 0.16)
                                    : AppColors.canvas,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.surfaceBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    c.$3,
                                    size: 14,
                                    color: selected
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    _s(c.$2),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _sectionLabel(_s('event_section_ethiopian_date')),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$monthName $_ethDay, $_ethYear ${_s('era_ec')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${greg.day}/${greg.month}/${greg.year} ${_s('era_gc')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: AppColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _datePickers(maxDays: maxDays, safeDay: safeDay),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _sectionLabel(_s('event_section_time')),
                      const SizedBox(height: 8),
                      if (!_isAllDay)
                        InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.outfit(
                                          color: AppColors.textPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${ethTime.period.amharic} ${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')} · ${_s('event_time_tap_change')}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _s('event_all_day_caption'),
                                  style: GoogleFonts.outfit(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                      Material(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            title: Text(
                              _s('event_all_day_toggle'),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              _s(_isAllDay
                                  ? 'event_all_day_sub_on'
                                  : 'event_all_day_sub_off'),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            value: _isAllDay,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.accent,
                            onChanged: (val) =>
                                setState(() => _isAllDay = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        key: ValueKey('rec_$_recurrence'),
                        initialValue: _recurrence,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _fieldDecoration(
                          _s('event_section_repeat'),
                          icon: Icons.repeat_rounded,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'NONE',
                            child: Text(_s('recur_none')),
                          ),
                          DropdownMenuItem(
                            value: 'DAILY',
                            child: Text(_s('recur_daily')),
                          ),
                          DropdownMenuItem(
                            value: 'WEEKLY',
                            child: Text(_s('recur_weekly')),
                          ),
                          DropdownMenuItem(
                            value: 'MONTHLY_ETHIOPIAN',
                            child: Text(_s('recur_monthly_ec')),
                          ),
                          DropdownMenuItem(
                            value: 'MONTHLY_GREGORIAN',
                            child: Text(_s('recur_monthly_gc')),
                          ),
                          DropdownMenuItem(
                            value: 'YEARLY_ETHIOPIAN',
                            child: Text(_s('recur_yearly_ec')),
                          ),
                          DropdownMenuItem(
                            value: 'YEARLY_GREGORIAN',
                            child: Text(_s('recur_yearly_gc')),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _recurrence = val ?? 'NONE'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        key: ValueKey('rem_$_reminderMinutes'),
                        initialValue: _reminderMinutes,
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        style: GoogleFonts.outfit(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _fieldDecoration(
                          _s('event_section_reminder'),
                          icon: Icons.notifications_none_rounded,
                        ),
                        items: _reminders
                            .map(
                              (r) => DropdownMenuItem(
                                value: r.$1,
                                child: Text(_s(r.$2)),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _reminderMinutes = val ?? 15),
                      ),
                      const SizedBox(height: 14),
                      _sectionLabel(_s('event_section_color')),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _colors.map((c) {
                          final selected = _colorHex == c;
                          return InkWell(
                            onTap: () => setState(() => _colorHex = c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _parseHex(c),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: AppColors.textPrimary,
                                        width: 2.5,
                                      )
                                    : Border.all(
                                        color: Colors.black12,
                                      ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: _parseHex(c)
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              // Sticky action bar — always visible above keyboard / thumb zone.
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  10 + MediaQuery.paddingOf(context).bottom.clamp(0, 12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(
                    top: BorderSide(color: AppColors.surfaceBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : widget.onDismiss,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: BorderSide(color: AppColors.surfaceBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _s('cancel'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor:
                              AppColors.accent.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _saving
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.onAccent,
                                ),
                              )
                            : Text(
                                _s(isEdit
                                    ? 'event_save_changes'
                                    : 'event_save'),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onAccent,
                                ),
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
        );
      },
    );
  }
}
