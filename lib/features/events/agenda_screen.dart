import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/holidays/holiday_engine.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_entity.dart';
import '../shared/components/app_chrome.dart';
import '../shared/providers.dart';
import 'dialogs/add_edit_event_dialog.dart';

class _AgendaEntry {
  final EthiopianDate date;
  final String title;
  final String subtitle;
  final Color color;
  final EventEntity? event;
  final bool isHoliday;

  const _AgendaEntry({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.color,
    this.event,
    this.isHoliday = false,
  });
}

/// Next 14 days: holidays + personal events, easy complete / edit / jump.
class AgendaScreen extends ConsumerWidget {
  final ValueChanged<EthiopianDate>? onOpenDate;

  const AgendaScreen({super.key, this.onOpenDate});

  EthiopianDate _shift(EthiopianDate d, int days) {
    return EthiopianCalendarEngine.jdnToEthiopian(
      EthiopianCalendarEngine.ethiopianToJdn(d) + days,
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    EthiopianDate? date,
    EventEntity? event,
  }) async {
    final lang = ref.read(currentAppLanguageProvider);
    final EthiopianDate initial = date ?? ref.read(todayEthiopianProvider);
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: initial,
      eventToEdit: event,
      currentLanguage: lang,
    );
    if (draft == null || !context.mounted) return;
    try {
      await ref.read(eventsNotifierProvider.notifier).saveEvent(draft);
      if (!context.mounted) return;
      AddEditEventDialog.showSavedFeedback(
        context,
        isEdit: event != null,
        title: draft.title,
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleStrings.get('event_save_failed', lang),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayEthiopianProvider);
    final lang = ref.watch(currentAppLanguageProvider);
    final events = ref.watch(eventsNotifierProvider).value ?? [];
    final holidays = [
      ...HolidayEngine.getHolidaysForYear(today.year),
      ...HolidayEngine.getHolidaysForYear(today.year + 1),
    ];

    final entries = <_AgendaEntry>[];
    for (var i = 0; i < 14; i++) {
      final date = _shift(today, i);
      final dayEvents = events.where((e) => eventMatchesDate(e, date)).toList()
        ..sort((a, b) {
          if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
          final aMin = a.hour * 60 + a.minute;
          final bMin = b.hour * 60 + b.minute;
          return aMin.compareTo(bMin);
        });
      final dayHolidays = holidays.where(
        (h) =>
            h.ethiopianDate.year == date.year &&
            h.ethiopianDate.month == date.month &&
            h.ethiopianDate.day == date.day,
      );

      for (final h in dayHolidays) {
        entries.add(
          _AgendaEntry(
            date: date,
            title: h.titleEnglish,
            subtitle: h.titleAmharic,
            color: AppColors.accent,
            isHoliday: true,
          ),
        );
      }
      for (final e in dayEvents) {
        entries.add(
          _AgendaEntry(
            date: date,
            title: e.title,
            subtitle: e.isAllDay
                ? '${LocaleStrings.get('all_day', lang)}${e.description.isNotEmpty ? ' · ${e.description}' : ''}'
                : '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}'
                    '${e.description.isNotEmpty ? ' · ${e.description}' : ''}',
            color: _parseColor(e.colorHex),
            event: e,
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: AppFab(
        onTap: () => _openEditor(context, ref, date: today),
        label: LocaleStrings.get('add_event', lang),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              LocaleStrings.get('next_14_days', lang),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final tight = constraints.maxHeight < 320;
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: tight ? 16 : 32,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!tight)
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.surfaceBorder,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.event_available_rounded,
                                      size: 34,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                if (!tight) const SizedBox(height: 16),
                                Text(
                                  LocaleStrings.get('nothing_coming_up', lang),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  LocaleStrings.get('agenda_empty_sub', lang),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _openEditor(context, ref, date: today),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: AppColors.onAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded),
                                  label: Text(
                                    LocaleStrings.get('add_event', lang),
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final showHeader = i == 0 ||
                          entries[i - 1].date.year != entry.date.year ||
                          entries[i - 1].date.month != entry.date.month ||
                          entries[i - 1].date.day != entry.date.day;
                      final month =
                          LocaleStrings.getMonthName(entry.date.month, lang);
                      final dow = LocaleStrings.getWeekdayLong(
                        EthiopianCalendarEngine.getDayOfWeek(entry.date),
                        lang,
                      );
                      final isToday = entry.date == today;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 16, bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: isToday
                                                ? LocaleStrings.get(
                                                    'today',
                                                    lang,
                                                  )
                                                : '$dow · $month ${entry.date.day}',
                                            style: GoogleFonts.outfit(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isToday
                                                  ? const Color(0xFFFF6B6B)
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                          if (isToday)
                                            TextSpan(
                                              text:
                                                  '  ·  $dow · $month ${entry.date.day}',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.textTertiary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AppPressable(
                                    onTap: () => _openEditor(
                                      context,
                                      ref,
                                      date: entry.date,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.surfaceBorder,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          AppPressable(
                            onTap: () {
                              if (entry.event != null) {
                                _openEditor(
                                  context,
                                  ref,
                                  date: entry.date,
                                  event: entry.event,
                                );
                              } else {
                                onOpenDate?.call(entry.date);
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.surfaceBorder),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                                leading: Container(
                                  width: 4,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: entry.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    if (entry.isHoliday) ...[
                                      const Icon(
                                        Icons.celebration_rounded,
                                        size: 14,
                                        color: Color(0xFFFF6B6B),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        entry.title,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: entry.event?.isCompleted == true
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                          decoration: entry.event?.isCompleted == true
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  entry.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                trailing: entry.event == null
                                    ? Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppColors.textTertiary,
                                        size: 22,
                                      )
                                    : IconButton(
                                        tooltip: entry.event!.isCompleted
                                            ? LocaleStrings.get(
                                                'mark_incomplete',
                                                lang,
                                              )
                                            : LocaleStrings.get(
                                                'mark_complete',
                                                lang,
                                              ),
                                        icon: Icon(
                                          entry.event!.isCompleted
                                              ? Icons.check_circle_rounded
                                              : Icons.circle_outlined,
                                          color: entry.event!.isCompleted
                                              ? const Color(0xFF1FA87A)
                                              : AppColors.textTertiary,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(eventsNotifierProvider.notifier)
                                              .toggleEventCompletion(entry.event!);
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
