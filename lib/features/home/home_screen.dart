import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/calendar/ethiopian_date.dart';
import '../../core/heritage/daily_heritage_engine.dart';
import '../../core/holidays/holiday_engine.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/share_helper.dart';
import '../../data/models/event_entity.dart';
import '../events/dialogs/add_edit_event_dialog.dart';
import '../holidays/dialogs/holiday_card_share_dialog.dart';
import '../shared/components/app_surface.dart';
import '../shared/components/ethiopian_clock_dialog.dart';
import '../shared/components/widget_management_dialog.dart';
import '../shared/providers.dart';
import 'widgets/premium_home_calendar_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final void Function(String destination) onNavigateDestination;
  final bool openClockTrigger;
  final VoidCallback? onClockTriggerConsumed;

  const HomeScreen({
    super.key,
    required this.onNavigateDestination,
    this.openClockTrigger = false,
    this.onClockTriggerConsumed,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    if (widget.openClockTrigger) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showClockDialog();
        widget.onClockTriggerConsumed?.call();
      });
    }
  }

  void _showClockDialog() {
    showDialog(
      context: context,
      builder: (_) => const EthiopianClockDialog(),
    );
  }

  Future<void> _showAddEventDialog(
    EthiopianDate todayEth,
    AppLanguage lang, [
    EventEntity? eventToEdit,
  ]) async {
    final draft = await AddEditEventDialog.open(
      context,
      initialDate: todayEth,
      eventToEdit: eventToEdit,
      currentLanguage: lang,
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save failed · ማስቀመጥ አልተሳካም'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFFC62828),
        ),
      );
    }
  }

  void _showShareCardDialog(EthiopianDate todayEth, AppLanguage lang) {
    showDialog(
      context: context,
      builder: (_) => HolidayCardShareDialog(
        currentDate: todayEth,
        currentLanguage: lang,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showWidgetDialog(AppLanguage lang) {
    showDialog(
      context: context,
      builder: (_) => WidgetManagementDialog(currentLanguage: lang),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(userSettingsProvider);
    final currentLang = ref.watch(currentAppLanguageProvider);
    final todayEth = ref.watch(todayEthiopianProvider);
    final todayEvents = ref.watch(eventsForSelectedDateProvider);
    final upcomingHoliday = ref.watch(upcomingHolidayProvider);

    final heritage = DailyHeritageEngine.getHeritageForDate(todayEth);
    final monthName = LocaleStrings.getMonthName(todayEth.month, currentLang);

    final fastingStatus = HolidayEngine.isFastingDay(todayEth);
    final dailySaint = HolidayEngine.monthlySaints.firstWhere(
      (s) => s.day == todayEth.day,
      orElse: () => HolidayEngine.monthlySaints.first,
    );

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppAtmosphere(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Premium interactive home calendar widget
            PremiumHomeCalendarWidget(
              onAddEvent: () => _showAddEventDialog(todayEth, currentLang),
              onDateSelected: (date) {
                ref.read(selectedDateProvider.notifier).state = date;
                ref.read(viewYearProvider.notifier).state = date.year;
                ref.read(viewMonthProvider.notifier).state = date.month;
                widget.onNavigateDestination('CALENDAR');
              },
            ),
            const SizedBox(height: 14),

            // Observances row
            Row(
              children: [
                if (settings.showFasting)
                  Expanded(
                    child: AppPanel(
                      color: fastingStatus.isFasting
                          ? (isDark ? Color(0xFF143028) : const Color(0xFFE5F6EE))
                          : null,
                      padding: EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.spa_outlined,
                                size: 16,
                                color: fastingStatus.isFasting
                                    ? AppColors.ethioEmerald
                                    : theme.colorScheme.primary,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'ጾም',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: fastingStatus.isFasting
                                      ? AppColors.ethioEmeraldDark
                                      : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            fastingStatus.reason,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (settings.showFasting && settings.showMonthlySaints) const SizedBox(width: 10),
                if (settings.showMonthlySaints)
                  Expanded(
                    child: AppPanel(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome, size: 16, color: theme.colorScheme.secondary),
                              const SizedBox(width: 6),
                              Text(
                                'ጽላት',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dailySaint.nameAmharic,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Daily wisdom
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ቀን ቀን · የዕለቱ ጥበብ',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      AppPill(label: heritage.proverb.category),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '«${heritage.proverb.amharic}»',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    heritage.proverb.englishTranslation,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    heritage.proverb.meaning,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ወቅት: ${heritage.solarPhase}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.ios_share_rounded, size: 16),
                        label: const Text('አጋራ'),
                        onPressed: () {
                          final shareText =
                              'የዕለቱ የኢትዮጵያ ጥበብ ($monthName ${todayEth.day}፣ ${todayEth.year} ዓ.ም)\n\n'
                              '«${heritage.proverb.amharic}»\n'
                              '${heritage.proverb.englishTranslation}\n\n'
                              'ትርጉም: ${heritage.proverb.meaning}\n'
                              '— Zemen: Ethiopian Calendar';
                          ShareHelper.share(shareText);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (upcomingHoliday != null) ...[
              AppPanel(
                onTap: () => widget.onNavigateDestination('HOLIDAYS'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppPill(
                            label: 'ቀጣይ በዓል',
                            background: theme.colorScheme.primary,
                            foreground: theme.colorScheme.onPrimary,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            upcomingHoliday.titleAmharic,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${upcomingHoliday.titleEnglish} · ${LocaleStrings.getMonthName(upcomingHoliday.ethiopianDate.month, currentLang)} ${upcomingHoliday.ethiopianDate.day}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${EthiopianCalendarEngine.daysBetween(todayEth, upcomingHoliday.ethiopianDate)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'ቀናት',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            AppSectionLabel(
              title: LocaleStrings.get('quick_actions', currentLang),
              trailing: TextButton.icon(
                onPressed: () => _showWidgetDialog(currentLang),
                icon: const Icon(Icons.widgets_outlined, size: 16),
                label: const Text('ዊጄት'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.add_rounded,
                    label: 'ማስታወሻ',
                    onTap: () => _showAddEventDialog(todayEth, currentLang),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'ቀን ቀያሪ',
                    onTap: () => widget.onNavigateDestination('CONVERTER'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.functions_rounded,
                    label: 'ባሕረ ሐሳብ',
                    onTap: () => widget.onNavigateDestination('CONVERTER'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionCard(
                    icon: Icons.card_giftcard_rounded,
                    label: 'ካርድ አጋራ',
                    onTap: () => _showShareCardDialog(todayEth, currentLang),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            AppSectionLabel(
              title: 'የዛሬ ማስታወሻዎች (${todayEvents.length})',
              trailing: TextButton(
                onPressed: () => widget.onNavigateDestination('EVENTS'),
                child: Text(LocaleStrings.get('view_all', currentLang)),
              ),
            ),
            if (todayEvents.isEmpty)
              AppPanel(
                child: Column(
                  children: [
                    Icon(Icons.event_available_outlined, size: 36, color: theme.colorScheme.outline),
                    const SizedBox(height: 10),
                    Text(
                      LocaleStrings.get('no_events_today', currentLang),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('አዲስ ማስታወሻ'),
                      onPressed: () => _showAddEventDialog(todayEth, currentLang),
                    ),
                  ],
                ),
              )
            else
              ...todayEvents.map((event) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: AppPanel(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          event.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                          color: event.isCompleted ? AppColors.ethioEmerald : theme.colorScheme.outline,
                        ),
                        onPressed: () => ref.read(eventsNotifierProvider.notifier).toggleEventCompletion(event),
                      ),
                      title: Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                          color: event.isCompleted
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        event.isAllDay ? 'ሙሉ ቀን' : '${event.hour}:${event.minute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _showAddEventDialog(todayEth, currentLang, event),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.45)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
