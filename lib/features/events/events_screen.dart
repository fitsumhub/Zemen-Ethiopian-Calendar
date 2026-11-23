import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/export/ics_exporter.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/share_helper.dart';
import '../../data/models/event_entity.dart';
import '../shared/components/app_chrome.dart';
import '../shared/providers.dart';
import 'dialogs/add_edit_event_dialog.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<_Cat> _categoriesFor(AppLanguage lang) => [
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
      ];

  Future<void> _showAddEditEventDialog([EventEntity? eventToEdit]) async {
    final todayEth = ref.read(todayEthiopianProvider);
    final currentLang = ref.read(currentAppLanguageProvider);
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: todayEth,
      eventToEdit: eventToEdit,
      currentLanguage: currentLang,
    );
    if (draft == null || !mounted) return;
    try {
      await ref.read(eventsNotifierProvider.notifier).saveEvent(draft);
      if (!mounted) return;
      AddEditEventDialog.showSavedFeedback(
        context,
        isEdit: eventToEdit != null,
        title: draft.title,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleStrings.get(
              'event_save_failed',
              ref.read(currentAppLanguageProvider),
            ),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    }
  }

  Future<void> _confirmDelete(EventEntity event) async {
    final lang = ref.read(currentAppLanguageProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          LocaleStrings.get('delete_event_q', lang),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          LocaleStrings.format(
            'delete_event_body',
            lang,
            params: {'title': event.title},
          ),
          style: GoogleFonts.outfit(color: AppColors.darkTextMed),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocaleStrings.get('cancel', lang)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocaleStrings.get('delete', lang)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(eventsNotifierProvider.notifier).deleteEvent(event.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleStrings.get('event_deleted', lang),
            style: GoogleFonts.outfit(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportEventsToIcs(List<EventEntity> events) {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No events to export', style: GoogleFonts.outfit()),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final icsContent = IcsExporter.exportToIcs(events);
    ShareHelper.share(icsContent, subject: 'ethiocal_events.ics');
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.accent;
    }
  }

  String _recurrenceLabel(String r, AppLanguage lang) {
    switch (r) {
      case 'DAILY':
        return LocaleStrings.get('recur_short_daily', lang);
      case 'WEEKLY':
        return LocaleStrings.get('recur_short_weekly', lang);
      case 'MONTHLY_ETHIOPIAN':
        return LocaleStrings.get('recur_short_monthly', lang);
      case 'MONTHLY_GREGORIAN':
        return LocaleStrings.get('recur_short_monthly_gc', lang);
      case 'YEARLY_ETHIOPIAN':
        return LocaleStrings.get('recur_short_yearly', lang);
      case 'YEARLY_GREGORIAN':
        return LocaleStrings.get('recur_short_yearly_gc', lang);
      default:
        return '';
    }
  }

  IconData _categoryIcon(String id) {
    final cats = _categoriesFor(ref.read(currentAppLanguageProvider));
    return cats
        .firstWhere((c) => c.id == id, orElse: () => cats.last)
        .icon;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentAppLanguageProvider);
    final categories = _categoriesFor(lang);
    final filtered = ref.watch(filteredEventsProvider);
    final allEvents = ref.watch(eventsNotifierProvider).value ?? [];
    final selectedCategory = ref.watch(eventCategoryFilterProvider);
    final selectedStatus = ref.watch(eventStatusFilterProvider);
    final openCount = allEvents.where((e) => !e.isCompleted).length;
    final doneCount = allEvents.where((e) => e.isCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: AppFab(
        onTap: () => _showAddEditEventDialog(),
        label: LocaleStrings.get('add_event', lang),
      ),
      body: Column(
        children: [
          // Header stats
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 360;
                final gap = narrow ? 6.0 : 8.0;
                return Row(
                  children: [
                    Expanded(
                      child: _StatPill(
                        label: LocaleStrings.get('stat_open', lang),
                        value: '$openCount',
                        color: AppColors.accent,
                        selected: selectedStatus == 'OPEN',
                        compact: narrow,
                        onTap: () =>
                            ref.read(eventStatusFilterProvider.notifier).set(
                                  selectedStatus == 'OPEN' ? 'ALL' : 'OPEN',
                                ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _StatPill(
                        label: LocaleStrings.get('stat_done', lang),
                        value: '$doneCount',
                        color: AppColors.ethioEmerald,
                        selected: selectedStatus == 'DONE',
                        compact: narrow,
                        onTap: () =>
                            ref.read(eventStatusFilterProvider.notifier).set(
                                  selectedStatus == 'DONE' ? 'ALL' : 'DONE',
                                ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _StatPill(
                        label: LocaleStrings.get('stat_total', lang),
                        value: '${allEvents.length}',
                        color: AppColors.ethioIndigoPrimary,
                        selected: selectedStatus == 'ALL',
                        compact: narrow,
                        onTap: () => ref
                            .read(eventStatusFilterProvider.notifier)
                            .set('ALL'),
                      ),
                    ),
                    SizedBox(width: gap),
                    AppPressable(
                      onTap: () => _exportEventsToIcs(allEvents),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: narrow ? 40 : 44,
                        height: narrow ? 40 : 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Icon(
                          Icons.ios_share_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.outfit(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: LocaleStrings.get('search_events', lang),
                hintStyle: GoogleFonts.outfit(color: AppColors.textTertiary),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(eventSearchQueryProvider.notifier).set('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.surfaceBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
                ),
              ),
              onChanged: (val) {
                ref.read(eventSearchQueryProvider.notifier).set(val);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final selected = selectedCategory == cat.id;
                return AppPressable(
                  onTap: () => ref.read(eventCategoryFilterProvider.notifier).set(cat.id),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFFF6B6B).withValues(alpha: 0.18)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFFFF6B6B) : AppColors.surfaceBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          cat.icon,
                          size: 15,
                          color: selected ? const Color(0xFFFF8A80) : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
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
              },
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? _EmptyEvents(
                  lang: lang,
                    hasAny: allEvents.isNotEmpty,
                    onAdd: () => _showAddEditEventDialog(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final event = filtered[index];
                      final color = _parseColor(event.colorHex);
                      final month = LocaleStrings.getMonthName(event.ethiopianMonth, lang);
                      final rec = _recurrenceLabel(event.recurrence, lang);
                      final showDateHeader = index == 0 ||
                          filtered[index - 1].ethiopianYear != event.ethiopianYear ||
                          filtered[index - 1].ethiopianMonth != event.ethiopianMonth ||
                          filtered[index - 1].ethiopianDay != event.ethiopianDay;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateHeader)
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 2 : 12,
                                bottom: 8,
                                left: 2,
                              ),
                              child: Text(
                                '$month ${event.ethiopianDay}, ${event.ethiopianYear}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          Dismissible(
                            key: ValueKey('ev_${event.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _confirmDelete(event);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.white),
                            ),
                            child: AppPressable(
                              onTap: () => _showAddEditEventDialog(event),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.surfaceBorder),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: const BorderRadius.horizontal(
                                            left: Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(10, 12, 4, 12),
                                          child: Row(
                                            children: [
                                              AppPressable(
                                                onTap: () => ref
                                                    .read(eventsNotifierProvider.notifier)
                                                    .toggleEventCompletion(event),
                                                borderRadius: BorderRadius.circular(20),
                                                child: Icon(
                                                  event.isCompleted
                                                      ? Icons.check_circle_rounded
                                                      : Icons.circle_outlined,
                                                  color: event.isCompleted
                                                      ? const Color(0xFF1FA87A)
                                                      : AppColors.textTertiary,
                                                  size: 26,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          _categoryIcon(event.category),
                                                          size: 14,
                                                          color: color,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            event.title,
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: GoogleFonts.outfit(
                                                              fontSize: 15,
                                                              fontWeight: FontWeight.w700,
                                                              color: event.isCompleted
                                                                  ? AppColors.textSecondary
                                                                  : AppColors.textPrimary,
                                                              decoration: event.isCompleted
                                                                  ? TextDecoration.lineThrough
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (event.description.isNotEmpty) ...[
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        event.description,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 12,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 4,
                                                      children: [
                                                        _MetaChip(
                                                          icon: Icons.schedule_rounded,
                                                          label: event.isAllDay
                                                              ? LocaleStrings.get(
                                                                  'all_day',
                                                                  lang,
                                                                )
                                                              : '${event.hour.toString().padLeft(2, '0')}:${event.minute.toString().padLeft(2, '0')}',
                                                        ),
                                                        if (rec.isNotEmpty)
                                                          _MetaChip(
                                                            icon: Icons.repeat_rounded,
                                                            label: rec,
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Delete',
                                                visualDensity: VisualDensity.compact,
                                                onPressed: () => _confirmDelete(event),
                                                icon: Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 20,
                                                  color: AppColors.textTertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

class _Cat {
  final String id;
  final String label;
  final IconData icon;
  const _Cat(this.id, this.label, this.icon);
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    this.selected = false,
    this.compact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final bool hasAny;
  final VoidCallback onAdd;
  final AppLanguage lang;
  const _EmptyEvents({required this.hasAny, required this.onAdd, required this.lang});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxHeight < 320;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 28,
            vertical: tight ? 16 : 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Icon(
                        hasAny
                            ? Icons.search_off_rounded
                            : Icons.event_note_rounded,
                        size: 34,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  if (!tight) const SizedBox(height: 16),
                  Text(
                    hasAny
                        ? LocaleStrings.get('no_matching_events', lang)
                        : LocaleStrings.get('no_events_yet', lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasAny
                        ? LocaleStrings.get('try_another_search', lang)
                        : LocaleStrings.get('events_empty_sub', lang),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!hasAny) ...[
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        LocaleStrings.get('add_event', lang),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onAccent,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
