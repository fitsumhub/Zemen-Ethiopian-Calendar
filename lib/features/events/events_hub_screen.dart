import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calendar/ethiopian_date.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/responsive.dart';
import '../shared/components/app_segmented.dart';
import '../shared/providers.dart';
import 'agenda_screen.dart';
import 'dialogs/add_edit_event_dialog.dart';
import 'events_screen.dart';

/// One "Events" destination: what is coming up, and everything you saved.
///
/// The agenda and the event list used to be two separate top-level tabs; they
/// answer the same question, so they share one place in the navigation.
class EventsHubScreen extends ConsumerStatefulWidget {
  final ValueChanged<EthiopianDate> onOpenDate;

  const EventsHubScreen({super.key, required this.onOpenDate});

  @override
  ConsumerState<EventsHubScreen> createState() => _EventsHubScreenState();
}

class _EventsHubScreenState extends ConsumerState<EventsHubScreen> {
  int _segment = 0;

  Future<void> _quickAdd() async {
    final lang = ref.read(currentAppLanguageProvider);
    final today = ref.read(todayEthiopianProvider);
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: today,
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

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(currentAppLanguageProvider);
    final r = AppResponsive(context);
    final eventCount = (ref.watch(eventsNotifierProvider).value ?? []).length;

    return ColoredBox(
      color: AppColors.canvas,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              r.isCompact ? 12 : 16,
              4,
              r.isCompact ? 12 : 16,
              8,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleStrings.get('nav_events', lang),
                        style: GoogleFonts.outfit(
                          fontSize: r.font(18),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (eventCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$eventCount',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    Material(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _quickAdd,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.isCompact ? 10 : 12,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: AppColors.onAccent,
                              ),
                              if (!r.isCompact) ...[
                                const SizedBox(width: 4),
                                Text(
                                  LocaleStrings.get('add_event', lang),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppSegmented(
                  labels: [
                    LocaleStrings.get('events_upcoming', lang),
                    LocaleStrings.get('events_mine', lang),
                  ],
                  icons: const [
                    Icons.upcoming_outlined,
                    Icons.event_note_outlined,
                  ],
                  index: _segment,
                  onChanged: (i) => setState(() => _segment = i),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _segment,
              children: [
                AgendaScreen(onOpenDate: widget.onOpenDate),
                const EventsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
