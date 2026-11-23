import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/ads/ad_config.dart';
import '../../core/ads/ad_platform.dart';
import '../../core/ads/consent_manager.dart';
import '../../core/brand/brand.dart';
import '../../core/calendar/calendar_data_catalog.dart';
import '../../core/calendar/ethiopian_calendar_engine.dart';
import '../../core/export/ics_exporter.dart';
import '../../core/export/ics_importer.dart';
import '../../core/export/read_local_bytes.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/locale_strings.dart';
import '../../core/notifications/notification_scheduler.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/responsive.dart';
import '../../core/utils/share_helper.dart';
import '../../data/models/event_entity.dart';
import '../shared/components/app_surface.dart';
import '../shared/components/calendar_provenance_badge.dart';
import '../shared/components/ethiocal_logo.dart';
import '../shared/components/widget_management_dialog.dart';
import '../shared/providers.dart';

/// Professional settings hub — clear sections, one job per block.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final allEvents = ref.watch(eventsNotifierProvider).value ?? [];
    final lang = ref.watch(currentAppLanguageProvider);
    final r = AppResponsive(context);
    final accent = Theme.of(context).colorScheme.primary;
    String t(String key) => LocaleStrings.get(key, lang);
    String tf(String key, Map<String, String> params) =>
        LocaleStrings.format(key, lang, params: params);
    final currentLang = AppLanguage.fromString(settings.language);
    final scheduledCount = allEvents
        .where((e) => e.reminderMinutesBefore >= 0 && !e.isCompleted)
        .length;
    final ecYear = EthiopianCalendarEngine.todayEthiopian().year;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          t('settings'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: false,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
      ),
      body: AppAtmosphere(
        child: ResponsiveBody(
          padding: EdgeInsets.fromLTRB(
            r.isCompact ? 14 : 18,
            4,
            r.isCompact ? 14 : 18,
            110,
          ),
          child: ListView(
            children: [
              _BrandHero(accent: accent),
              const SizedBox(height: 22),

              _SectionTitle(t('section_language')),
              _SettingsCard(
                children: [
                  _NavRow(
                    icon: Icons.language_rounded,
                    title: t('app_language'),
                    subtitle: _langName(settings.language),
                    trailing: _ValueChip(label: currentLang.shortLabel),
                    onTap: () => _showLanguageSheet(context, settings.language, ref),
                  ),
                  _Divider(),
                  _Block(
                    icon: Icons.pin_rounded,
                    title: t('numeral_style'),
                    subtitle: t('numeral_style_sub'),
                    child: _ChoiceRow(
                      options: const [
                        ('ARABIC', '1 2 3'),
                        ('GEEZ', '፩ ፪ ፫'),
                      ],
                      selected: settings.numeralType,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(userSettingsProvider.notifier).setNumeralType(v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_appearance')),
              _SettingsCard(
                children: [
                  _Block(
                    icon: Icons.brightness_6_rounded,
                    title: t('theme_mode'),
                    subtitle: _themeName(settings.themeMode, lang),
                    child: _ChoiceRow(
                      options: [
                        ('LIGHT', t('theme_light')),
                        ('DARK', t('theme_dark')),
                        ('SYSTEM', t('theme_auto')),
                        ('AMOLED', t('theme_amoled')),
                      ],
                      selected: settings.themeMode,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref.read(userSettingsProvider.notifier).setThemeMode(v);
                      },
                    ),
                  ),
                  _Divider(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Row(
                      children: [
                        Icon(Icons.palette_rounded, size: 20, color: accent),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t('color_accent'),
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _paletteShort(settings.accentPalette),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: _ThemeGrid(
                      selectedId: settings.accentPalette,
                      onSelect: (id) {
                        HapticFeedback.selectionClick();
                        ref.read(userSettingsProvider.notifier).setAccentPalette(id);
                      },
                    ),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.restart_alt_rounded,
                    title: t('reset_appearance'),
                    subtitle: t('reset_appearance_sub'),
                    onTap: () => _resetAppearance(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_calendar')),
              _SettingsCard(
                children: [
                  _Block(
                    icon: Icons.calendar_month_rounded,
                    title: t('default_calendar'),
                    subtitle: t('default_calendar_sub'),
                    child: _ChoiceRow(
                      options: [
                        ('ETHIOPIAN', t('cal_ethiopian')),
                        ('GREGORIAN', t('cal_gregorian')),
                      ],
                      selected: settings.calendarFormat,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(userSettingsProvider.notifier)
                            .setCalendarFormat(v);
                      },
                    ),
                  ),
                  _Divider(),
                  _Block(
                    icon: Icons.view_week_rounded,
                    title: t('first_day_of_week'),
                    child: _ChoiceRow(
                      options: [
                        ('MONDAY', t('day_monday')),
                        ('SUNDAY', t('day_sunday')),
                      ],
                      selected: settings.firstDayOfWeek,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(userSettingsProvider.notifier)
                            .setFirstDayOfWeek(v);
                      },
                    ),
                  ),
                  _Divider(),
                  _SwitchRow(
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: AppColors.ethioEmerald,
                    title: t('fasting_highlights'),
                    subtitle: t('fasting_highlights_sub'),
                    value: settings.showFasting,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(userSettingsProvider.notifier).setShowFasting(v);
                    },
                  ),
                  _Divider(),
                  _SwitchRow(
                    icon: Icons.church_rounded,
                    iconColor: const Color(0xFFF472B6),
                    title: t('monthly_saints'),
                    subtitle: t('monthly_saints_sub'),
                    value: settings.showMonthlySaints,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(userSettingsProvider.notifier)
                          .setShowMonthlySaints(v);
                    },
                  ),
                  _Divider(),
                  _SwitchRow(
                    icon: Icons.sports_soccer_rounded,
                    iconColor: const Color(0xFF38BDF8),
                    title: t('show_football'),
                    subtitle: t('show_football_sub'),
                    value: settings.showFootball,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref.read(userSettingsProvider.notifier).setShowFootball(v);
                    },
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.today_rounded,
                    title: t('jump_to_today'),
                    subtitle: t('jump_to_today_sub'),
                    onTap: () => _jumpToToday(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.widgets_rounded,
                    title: t('nav_home_widgets'),
                    subtitle: t('home_widgets_sub'),
                    onTap: () => showWidgetPickerSheet(context, lang),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_notifications')),
              _SettingsCard(
                children: [
                  _SwitchRow(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFFB923C),
                    title: t('enable_reminders'),
                    subtitle: settings.notificationsEnabled
                        ? tf('reminders_on_count', {'count': '$scheduledCount'})
                        : t('reminders_off'),
                    value: settings.notificationsEnabled,
                    onChanged: (v) => _toggleNotifications(context, ref, v),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.notifications_none_rounded,
                    title: t('send_test_notification'),
                    subtitle: t('send_test_sub'),
                    trailing: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: () => _sendTestNotification(context, ref),
                      child: Text(
                        t('test'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.sync_rounded,
                    title: t('reschedule_reminders'),
                    subtitle: t('reschedule_reminders_sub'),
                    onTap: settings.notificationsEnabled
                        ? () => _rescheduleReminders(context, ref)
                        : null,
                    trailing: settings.notificationsEnabled
                        ? null
                        : _ValueChip(label: t('off')),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_data')),
              _SettingsCard(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.ios_share_rounded, color: accent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t('export_events'),
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _ValueChip(label: '${allEvents.length}'),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          t('export_events_sub'),
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _importEvents(context, ref),
                                icon: const Icon(Icons.upload_file_rounded, size: 18),
                                label: Text(
                                  t('import_ics'),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () =>
                                    _exportEvents(context, ref, allEvents),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: Text(
                                  t('export_ics'),
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.event_available_rounded,
                    title: t('add_holiday_reminders'),
                    subtitle: tf('add_holiday_reminders_sub', {'year': '$ecYear'}),
                    onTap: () => _addHolidayReminders(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.delete_forever_rounded,
                    title: t('clear_all_events'),
                    subtitle: allEvents.isEmpty
                        ? t('clear_all_events_empty')
                        : tf('clear_all_events_sub', {
                            'count': '${allEvents.length}',
                          }),
                    onTap: allEvents.isEmpty
                        ? null
                        : () => _clearAllEvents(context, ref, allEvents.length),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_accuracy')),
              _SettingsCard(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('verified_engine'),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            CalendarProvenanceBadge(
                              verification: 'verified',
                              subtitle: 'EC↔GC',
                            ),
                            CalendarProvenanceBadge(
                              verification: 'verified',
                              subtitle: 'Bahire Hasab',
                            ),
                            CalendarProvenanceBadge(
                              verification: 'approximate_calculated',
                              subtitle: 'Islamic',
                            ),
                            CalendarProvenanceBadge(
                              verification: 'approximate_rule',
                              subtitle: 'Regional',
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          t('verified_engine_sub'),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _showCalendarSources(context),
                      child: Text(
                        t('sources_licenses'),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_privacy')),
              _SettingsCard(
                children: [
                  if (AdPlatform.supportsMobileAds) ...[
                    _NavRow(
                      icon: Icons.shield_outlined,
                      title: t('ad_consent'),
                      subtitle: t('ad_consent_sub'),
                      onTap: () => _openConsent(context),
                    ),
                    _Divider(),
                  ],
                  _NavRow(
                    icon: Icons.privacy_tip_outlined,
                    title: t('privacy_policy'),
                    subtitle: t('privacy_policy_sub'),
                    onTap: () => _showPrivacyPolicyDialog(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.link_rounded,
                    title: t('copy_policy_link'),
                    subtitle: AdConfig.privacyPolicyUrl,
                    onTap: () => _copyPrivacyLink(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle(t('section_about')),
              _SettingsCard(
                children: [
                  _NavRow(
                    icon: Icons.info_outline_rounded,
                    title: Brand.displayName,
                    subtitle: t('about_version'),
                    onTap: () => _showAboutDialog(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.person_outline_rounded,
                    title: t('about_developer'),
                    subtitle: t('about_developer_sub'),
                    onTap: () => _showDeveloperDialog(context, ref),
                  ),
                  _Divider(),
                  _NavRow(
                    icon: Icons.copy_all_rounded,
                    title: t('copy_app_info'),
                    subtitle: t('copy_app_info_sub'),
                    onTap: () => _copyAppInfo(context, ref),
                  ),
                ],
              ),
              SizedBox(height: 28),
              Center(
                child: Text(
                  Brand.displayNameBilingual,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  '${Brand.developerBrand} · ${Brand.developerName}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  Brand.developerMotto,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  AppLanguage _langOf(WidgetRef ref) => ref.read(currentAppLanguageProvider);

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    HapticFeedback.selectionClick();
    await ref.read(userSettingsProvider.notifier).setNotificationsEnabled(enabled);
    if (!context.mounted) return;
    final lang = _langOf(ref);
    final active = ref.read(userSettingsProvider).notificationsEnabled;
    if (enabled && !active) {
      _snack(context, LocaleStrings.get('permission_denied_reminders', lang));
    } else if (active) {
      final count = (ref.read(eventsNotifierProvider).value ?? [])
          .where((e) => e.reminderMinutesBefore >= 0 && !e.isCompleted)
          .length;
      _snack(
        context,
        LocaleStrings.format(
          'reminders_enabled',
          lang,
          params: {'count': '$count'},
        ),
      );
    } else {
      _snack(context, LocaleStrings.get('reminders_disabled', lang));
    }
  }

  Future<void> _sendTestNotification(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    final lang = _langOf(ref);
    final ok = await NotificationScheduler.showTestNotification(language: lang);
    if (!context.mounted) return;
    _snack(
      context,
      LocaleStrings.get(
        ok ? 'test_notification_sent' : 'test_notification_denied',
        lang,
      ),
    );
  }

  Future<void> _rescheduleReminders(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    await ref.read(eventsNotifierProvider.notifier).rescheduleAllReminders();
    if (!context.mounted) return;
    final count = (ref.read(eventsNotifierProvider).value ?? []).length;
    _snack(
      context,
      LocaleStrings.format(
        'reminders_rescheduled',
        _langOf(ref),
        params: {'count': '$count'},
      ),
    );
  }

  void _exportEvents(
    BuildContext context,
    WidgetRef ref,
    List<EventEntity> allEvents,
  ) {
    if (allEvents.isEmpty) {
      _snack(context, LocaleStrings.get('no_events_export', _langOf(ref)));
      return;
    }
    final ics = IcsExporter.exportToIcs(allEvents);
    ShareHelper.share(ics, subject: 'zemen_events.ics');
  }

  Future<void> _importEvents(BuildContext context, WidgetRef ref) async {
    final lang = _langOf(ref);
    HapticFeedback.selectionClick();
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['ics', 'ical', 'ifb'],
        dialogTitle: LocaleStrings.get('import_ics', lang),
        initialDirectory: r'C:\Users\ROG\Downloads',
      );
      if (file == null) return;

      var bytes = await file.readAsBytes();
      if (bytes.isEmpty && file.path != null && file.path!.isNotEmpty) {
        bytes = await readLocalFileBytes(file.path!) ?? bytes;
      }
      if (!context.mounted) return;
      if (bytes.isEmpty) {
        _snack(context, LocaleStrings.get('import_ics_empty', lang));
        return;
      }
      final content = utf8.decode(bytes, allowMalformed: true);
      if (content.trim().isEmpty) {
        _snack(context, LocaleStrings.get('import_ics_empty', lang));
        return;
      }

      final parsed = IcsImporter.parse(content);
      if (parsed.events.isEmpty) {
        _snack(context, LocaleStrings.get('import_ics_none', lang));
        return;
      }

      final result = await ref
          .read(eventsNotifierProvider.notifier)
          .importEvents(parsed.events);
      if (!context.mounted) return;

      final name = parsed.calendarName;
      final message = LocaleStrings.format(
        'import_ics_done',
        lang,
        params: {
          'imported': '${result.imported}',
          'skipped': '${result.skipped}',
          'name': name == null || name.isEmpty ? 'calendar' : name,
        },
      );
      _snack(context, message);
    } catch (e) {
      if (!context.mounted) return;
      _snack(
        context,
        LocaleStrings.format(
          'import_ics_failed',
          lang,
          params: {'error': e.toString()},
        ),
      );
    }
  }

  Future<void> _addHolidayReminders(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    final year = EthiopianCalendarEngine.todayEthiopian().year;
    final count = await ref
        .read(eventsNotifierProvider.notifier)
        .scheduleAllAnnualHolidays(year: year);
    if (!context.mounted) return;
    _snack(
      context,
      LocaleStrings.format(
        'holidays_added',
        _langOf(ref),
        params: {'count': '$count', 'year': '$year'},
      ),
    );
  }

  Future<void> _clearAllEvents(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final lang = _langOf(ref);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocaleStrings.get('clear_all_events_title', lang),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          LocaleStrings.format(
            'clear_all_events_body',
            lang,
            params: {'count': '$count'},
          ),
          style: GoogleFonts.outfit(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocaleStrings.get('cancel', lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocaleStrings.get('delete_all', lang)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed =
        await ref.read(eventsNotifierProvider.notifier).clearAllEvents();
    if (!context.mounted) return;
    HapticFeedback.heavyImpact();
    _snack(
      context,
      LocaleStrings.format(
        'events_deleted',
        lang,
        params: {'count': '$removed'},
      ),
    );
  }

  Future<void> _resetAppearance(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    await ref.read(userSettingsProvider.notifier).resetAppearanceDefaults();
    if (!context.mounted) return;
    _snack(context, LocaleStrings.get('appearance_reset', _langOf(ref)));
  }

  void _jumpToToday(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    final settings = ref.read(userSettingsProvider);
    if (settings.calendarFormat == 'GREGORIAN') {
      final g = EthiopianCalendarEngine.todayGregorian();
      final e = EthiopianCalendarEngine.todayEthiopian();
      ref.read(selectedDateProvider.notifier).set(e);
      ref.read(viewYearProvider.notifier).set(g.year);
      ref.read(viewMonthProvider.notifier).set(g.month);
    } else {
      final e = EthiopianCalendarEngine.todayEthiopian();
      ref.read(selectedDateProvider.notifier).set(e);
      ref.read(viewYearProvider.notifier).set(e.year);
      ref.read(viewMonthProvider.notifier).set(e.month);
    }
    ref.read(calendarViewModeProvider.notifier).set('MONTH');
    _snack(context, LocaleStrings.get('calendar_focused_today', _langOf(ref)));
  }

  Future<void> _copyPrivacyLink(BuildContext context, WidgetRef ref) async {
    await Clipboard.setData(
      ClipboardData(text: AdConfig.privacyPolicyUrl),
    );
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    _snack(context, LocaleStrings.get('policy_link_copied', _langOf(ref)));
  }

  Future<void> _copyAppInfo(BuildContext context, WidgetRef ref) async {
    final info =
        '${Brand.displayName}\nVersion 1.0.0\nPackage: ${Brand.packageId}\n'
        '${Brand.tagline}\nDeveloper: ${Brand.developerName} (${Brand.developerBrand})';
    await Clipboard.setData(ClipboardData(text: info));
    if (!context.mounted) return;
    HapticFeedback.selectionClick();
    _snack(context, LocaleStrings.get('app_info_copied', _langOf(ref)));
  }

  Future<void> _openConsent(BuildContext context) async {
    if (!AdPlatform.supportsMobileAds) return;
    await ConsentManager.instance.showPrivacyOptionsForm(
      onDismissed: (error) {
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Consent form error: ${error.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (context.mounted &&
            !ConsentManager.instance.isPrivacyOptionsRequired) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(
                'Consent status',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              content: Text(
                'A consent form is not required in your region right now. '
                'Calendar events and notes stay on this device.',
                style: GoogleFonts.outfit(fontSize: 13.5, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  void _showLanguageSheet(
    BuildContext context,
    String currentCode,
    WidgetRef ref,
  ) {
    final uiLang = AppLanguage.fromString(currentCode);
    final languages = AppLanguage.values;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    LocaleStrings.get('select_language', uiLang),
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'English · አማርኛ · Afaan Oromoo · ትግርኛ · Français',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                for (final lang in languages)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      selected: currentCode == lang.preferenceValue,
                      selectedTileColor:
                          AppColors.accent.withValues(alpha: 0.12),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: currentCode == lang.preferenceValue
                            ? AppColors.accent
                            : AppColors.surface,
                        child: Text(
                          lang.shortLabel,
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: currentCode == lang.preferenceValue
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      title: Text(
                        lang.nativeName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        lang.displayName == lang.nativeName
                            ? lang.code.toUpperCase()
                            : '${lang.displayName} · ${lang.code.toUpperCase()}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: currentCode == lang.preferenceValue
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () async {
                        HapticFeedback.selectionClick();
                        await ref
                            .read(userSettingsProvider.notifier)
                            .setLanguage(lang.preferenceValue);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (!context.mounted) return;
                        _snack(
                          context,
                          LocaleStrings.format(
                            'language_applied',
                            lang,
                            params: {'name': lang.nativeName},
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPrivacyPolicyDialog(BuildContext context, WidgetRef ref) async {
    final lang = _langOf(ref);
    var body =
        '${Brand.displayName} privacy summary:\n\n'
        '1. Calendar privacy\n'
        'Personal events, notes, and date calculations stay on your device.\n\n'
        '2. Ads\n'
        'Google Mobile Ads may use device identifiers to show ads.\n\n'
        '3. Consent\n'
        'Where required, Google UMP collects your consent choices.\n\n'
        '4. Full policy\n'
        '${AdConfig.privacyPolicyUrl}';
    try {
      final html = await rootBundle.loadString('docs/privacy-policy.html');
      final stripped = html
          .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'<[^>]+>'), ' ')
          .replaceAll(RegExp(r'&amp;'), '&')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'[ \t]+\n'), '\n')
          .replaceAll(RegExp(r'\n{3,}'), '\n\n')
          .trim();
      if (stripped.isNotEmpty) body = stripped;
    } catch (_) {
      // Keep the short summary if the bundled HTML asset is unavailable.
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocaleStrings.get('privacy_policy', lang),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              body,
              style: GoogleFonts.outfit(fontSize: 13, height: 1.45),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ShareHelper.share(
                AdConfig.privacyPolicyUrl,
                subject: '${Brand.displayName} Privacy Policy',
              );
            },
            child: Text(LocaleStrings.get('share_link', lang)),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: AdConfig.privacyPolicyUrl),
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(LocaleStrings.get('copy', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleStrings.get('ok', lang)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final lang = _langOf(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            EthioCalLogo(size: 32),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                Brand.displayName,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          '${Brand.displayName} / ${Brand.nameAm}\n${Brand.tagline}\n\n'
          'Accurate Ethiopian calendar math, Bahire Hasab, 13 months, '
          'holidays, fasting, converters, and personal events — private on device.\n\n'
          'Version 1.0.0\nPackage: ${Brand.packageId}\n\n'
          '${LocaleStrings.get('developer_label', lang)}: '
          '${Brand.developerName} (${Brand.developerBrand})',
          style: GoogleFonts.outfit(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDeveloperDialog(context, ref);
            },
            child: Text(LocaleStrings.get('about_developer', lang)),
          ),
          TextButton(
            onPressed: () {
              ShareHelper.share(
                '${Brand.displayName}\n${Brand.tagline}\nVersion 1.0.0\n'
                '${Brand.developerBrand} · ${Brand.developerName}',
                subject: Brand.displayName,
              );
            },
            child: Text(LocaleStrings.get('share', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleStrings.get('ok', lang)),
          ),
        ],
      ),
    );
  }

  void _showDeveloperDialog(BuildContext context, WidgetRef ref) {
    final lang = _langOf(ref);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          LocaleStrings.get('about_developer', lang),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Brand.developerHeadline,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  Brand.developerBio,
                  style: GoogleFonts.outfit(
                    fontSize: 13.2,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${LocaleStrings.get('developer_label', lang)}: ${Brand.developerName}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${LocaleStrings.get('developer_country_label', lang)}: ${Brand.developerCountry}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  Brand.developerMotto,
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ShareHelper.share(
                '${Brand.developerHeadline}\n\n'
                '${Brand.developerBio}\n\n'
                'Developer: ${Brand.developerName}\n'
                'Country: ${Brand.developerCountry}\n\n'
                '${Brand.developerMotto}',
                subject: Brand.developerHeadline,
              );
            },
            child: Text(LocaleStrings.get('share', lang)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleStrings.get('ok', lang)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCalendarSources(BuildContext context) async {
    final sources = await CalendarDataCatalog.sources();
    final list = (sources['sources'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    if (!context.mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Calendar sources',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Research · verify · integrate',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.sizeOf(ctx).height * 0.55,
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => Divider(height: 1),
                    itemBuilder: (context, i) {
                      final s = list[i];
                      final verification = '${s['verification'] ?? 'reviewed'}';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${s['name']}',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s['role']}',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  height: 1.3,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              CalendarProvenanceBadge(
                                verification: verification,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _langName(String code) {
    final lang = AppLanguage.fromString(code);
    if (lang.nativeName == lang.displayName) return lang.nativeName;
    return '${lang.nativeName} · ${lang.displayName}';
  }

  static String _themeName(String mode, AppLanguage lang) {
    switch (mode) {
      case 'LIGHT':
        return LocaleStrings.get('theme_light', lang);
      case 'DARK':
        return LocaleStrings.get('theme_dark', lang);
      case 'AMOLED':
        return LocaleStrings.get('theme_amoled', lang);
      default:
        return LocaleStrings.get('theme_auto', lang);
    }
  }

  static String _paletteShort(String palette) {
    switch (palette) {
      case 'GOLD_EMERALD':
        return 'Gold';
      case 'ROYAL_INDIGO':
        return 'Sapphire';
      case 'CRIMSON':
        return 'Crimson';
      case 'TERRACOTTA':
        return 'Clay';
      case 'LALIBELA_PURPLE':
        return 'Amethyst';
      default:
        return 'Crimson';
    }
  }
}

// —— Shared settings UI pieces ——

class _BrandHero extends StatelessWidget {
  final Color accent;
  const _BrandHero({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceElevated,
            AppColors.surface,
            Color.lerp(AppColors.surface, accent, 0.08) ?? AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          EthioCalLogo(size: 56),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Brand.displayName,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  Brand.tagline,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _HeroPill(
                      icon: Icons.verified_user_outlined,
                      label: 'Private',
                      color: AppColors.ethioEmerald,
                    ),
                    _HeroPill(
                      icon: Icons.offline_bolt_outlined,
                      label: 'Offline',
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _HeroPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: AppColors.surfaceBorder);
  }
}

class _ValueChip extends StatelessWidget {
  final String label;
  const _ValueChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 21, color: accent),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 8),
                trailing!,
              ] else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary.withValues(alpha: 0.8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: SwitchListTile(
          secondary: Icon(icon, color: iconColor),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: Theme.of(context).colorScheme.primary,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Block({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final opt in options)
          GestureDetector(
            onTap: () => onChanged(opt.$1),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: selected == opt.$1
                    ? accent.withValues(alpha: 0.18)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: selected == opt.$1
                      ? accent
                      : AppColors.surfaceBorder,
                  width: selected == opt.$1 ? 1.4 : 1,
                ),
              ),
              child: Text(
                opt.$2,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected == opt.$1
                      ? accent
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelect;

  const _ThemeGrid({
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final gap = 8.0;
        final w = (box.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final preset in AppTheme.presets)
              SizedBox(
                width: w,
                child: _ThemeSwatch(
                  preset: preset,
                  selected: selectedId == preset.id,
                  onTap: () => onSelect(preset.id),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 180),
          padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
          decoration: BoxDecoration(
            color: preset.previewBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? preset.primaryColor : AppColors.surfaceBorder,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: preset.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      preset.icon,
                      size: 15,
                      color: preset.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: preset.primaryColor,
                    ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                preset.nameEnglish,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _Dot(preset.primaryColor),
                  const SizedBox(width: 4),
                  _Dot(preset.secondaryColor),
                  const SizedBox(width: 4),
                  _Dot(preset.accentGlow),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
