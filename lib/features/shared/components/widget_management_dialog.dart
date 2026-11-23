import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/widgets/home_widget_engine.dart';
import '../../../core/widgets/home_widget_sync.dart';
import '../../../data/preferences/user_preferences_repository.dart';
import 'home_widget_luxury_previews.dart';

/// Shows the redesigned, theme-aware EthioCal home-widget picker with live calendar payloads.
void showWidgetPickerSheet(BuildContext context, AppLanguage lang) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WidgetPickerSheet(currentLanguage: lang),
  );
}

class WidgetManagementDialog extends StatelessWidget {
  final AppLanguage currentLanguage;
  const WidgetManagementDialog({super.key, required this.currentLanguage});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: WidgetPickerSheet(currentLanguage: currentLanguage),
    );
  }
}

class WidgetPickerSheet extends StatefulWidget {
  final AppLanguage currentLanguage;
  const WidgetPickerSheet({super.key, required this.currentLanguage});

  @override
  State<WidgetPickerSheet> createState() => _WidgetPickerSheetState();
}

class _WidgetPickerSheetState extends State<WidgetPickerSheet> {
  int _selected = 0;
  bool _busy = false;
  bool _pinned = false;
  bool _showFasting = true;
  bool _showGeez = true;
  bool _showSaint = true;
  String _size = 'compact';
  bool _themeAuto = true;
  WidgetThemeFamily _themeFamily = WidgetThemeFamily.coralStudio;
  DateTime _refreshedAt = DateTime.now();

  // Date sandbox stepping
  int _dayOffset = 0;
  bool _previewDark = true;

  late List<HomeWidgetSnapshot> _snapshots;

  WidgetThemeFamily? get _familyOverride =>
      _themeAuto ? null : _themeFamily;

  @override
  void initState() {
    super.initState();
    try {
      _selected = UserPreferencesRepository.instance
          .getWidgetStyle()
          .clamp(0, HomeWidgetKindX.lastIndex);
    } catch (_) {
      _selected = 0;
    }
    _rebuildSnapshots();
    _loadOptions();
    _checkPinned();
    _syncSilent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _previewDark = Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadOptions() async {
    final opts = await HomeWidgetSync.loadOptions();
    if (!mounted) return;
    setState(() {
      _showFasting = opts['showFasting'] as bool? ?? true;
      _showGeez = opts['showGeez'] as bool? ?? true;
      _showSaint = opts['showSaint'] as bool? ?? true;
      _size = opts['size'] as String? ?? 'compact';
      _themeAuto = opts['themeAuto'] as bool? ?? true;
      _themeFamily = WidgetThemeFamilyX.fromId(
        opts['themeFamily'] as String? ?? WidgetThemeFamily.noirGold.id,
      );
    });
  }

  void _rebuildSnapshots() {
    final lang = widget.currentLanguage;
    final today = EthiopianCalendarEngine.todayEthiopian();
    final targetDate = _dayOffset == 0
        ? today
        : HomeWidgetEngine.shiftDays(today, _dayOffset);

    _snapshots = [
      for (final kind in HomeWidgetKind.values)
        HomeWidgetEngine.build(kind, lang: lang, forDate: targetDate),
    ];
    _refreshedAt = DateTime.now();
  }

  HomeWidgetSnapshot get _active =>
      _snapshots[_selected.clamp(0, _snapshots.length - 1)];

  Future<void> _syncSilent() async {
    await HomeWidgetSync.sync(
      styleIndex: _selected,
      lang: widget.currentLanguage,
      showFasting: _showFasting,
      showGeez: _showGeez,
      showSaint: _showSaint,
      size: _size,
      themeFamily: _themeFamily,
      themeAuto: _themeAuto,
    );
  }

  Future<void> _checkPinned() async {
    final pinned = await HomeWidgetSync.areWidgetsPinned();
    if (mounted) setState(() => _pinned = pinned);
  }

  Future<void> _persist(int index) async {
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
    try {
      await UserPreferencesRepository.instance.setWidgetStyle(index);
    } catch (_) {}
    await _syncSilent();
  }

  Future<void> _toggleOption({
    bool? fasting,
    bool? geez,
    bool? saint,
    String? size,
    bool? themeAuto,
    WidgetThemeFamily? themeFamily,
  }) async {
    HapticFeedback.selectionClick();
    setState(() {
      if (fasting != null) _showFasting = fasting;
      if (geez != null) _showGeez = geez;
      if (saint != null) _showSaint = saint;
      if (size != null) _size = size;
      if (themeAuto != null) _themeAuto = themeAuto;
      if (themeFamily != null) {
        _themeFamily = themeFamily;
        _themeAuto = false;
      }
    });
    await _syncSilent();
  }

  void _stepDate(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _dayOffset += delta;
      _rebuildSnapshots();
    });
  }

  void _resetDate() {
    HapticFeedback.mediumImpact();
    setState(() {
      _dayOffset = 0;
      _rebuildSnapshots();
    });
  }

  Future<void> _refresh() async {
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _rebuildSnapshots();
    });
    await _syncSilent();
    await _checkPinned();
    if (!mounted) return;
    setState(() => _busy = false);
    _toast('ተዘምኗል · ${_active.monthName} ${_active.eth.day}');
  }

  Future<void> _share() async {
    ShareHelper.share(
      HomeWidgetEngine.shareText(_active, lang: widget.currentLanguage),
      subject: 'Zemen: Ethiopian Calendar · Widget',
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(
        text: HomeWidgetEngine.shareText(
          _active,
          lang: widget.currentLanguage,
        ),
      ),
    );
    if (!mounted) return;
    _toast('ወደ ቅንጥብ ተቀድቷል');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addToHome() async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    // Sync payload first, then pin. Keep this sheet open until the system
    // pin dialog appears — closing early can break One UI bind.
    await _syncSilent();
    final status = await HomeWidgetSync.requestPin();
    if (!mounted) return;
    setState(() => _busy = false);

    final message = switch (status) {
      'pin_requested' =>
        'Confirm Add on the system dialog to place Zemen Calendar.',
      'legacy_manual' || 'unsupported' =>
        'Style saved. Long-press home → Widgets → Zemen Calendar.',
      'web_preview' =>
        'Style saved. Pin it from an Android build.',
      'pin_failed' =>
        'Could not open pin dialog. Long-press home → Widgets → Zemen Calendar.',
      _ => 'Widget style saved.',
    };

    // Leave the atelier open while Samsung shows the pin sheet; only dismiss
    // after a short beat so the host still has a foreground activity.
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (status == 'pin_requested') {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }
    Navigator.of(context).pop();
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = _active;

    final sheetBg = isDark ? AppColors.darkCard : Colors.white;
    final sheetBorder = isDark ? AppColors.darkBorder : Color(0xFFE2E8F0);
    final textHigh = isDark ? AppColors.darkTextHigh : Color(0xFF0F172A);
    final textMed = isDark ? AppColors.darkTextMed : Color(0xFF64748B);
    final accent = AppColors.accent;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: sheetBorder, width: 1),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Sheet Title & Actions Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ZEMEN ATELIER',
                        style: GoogleFonts.cinzel(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textHigh,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Iconic home widgets · ${_fmtTime(_refreshedAt)}'
                        '${_pinned ? ' · pinned' : ''}'
                        '${kIsWeb ? ' · preview' : ''}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: textMed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Theme Mode Preview Toggle (Dark/Light preview)
                _ThemedIconChip(
                  icon: _previewDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  tooltip: _previewDark ? 'Dark Preview' : 'Light Preview',
                  onTap: () {
                    setState(() => _previewDark = !_previewDark);
                  },
                ),
                const SizedBox(width: 6),
                _ThemedIconChip(
                  icon: Icons.refresh_rounded,
                  tooltip: 'አድስ (Refresh)',
                  onTap: _busy ? null : _refresh,
                  busy: _busy,
                ),
                const SizedBox(width: 6),
                _ThemedIconChip(
                  icon: Icons.copy_rounded,
                  tooltip: 'ቅዳ (Copy)',
                  onTap: _copy,
                ),
                const SizedBox(width: 6),
                _ThemedIconChip(
                  icon: Icons.ios_share_rounded,
                  tooltip: 'አጋራ (Share)',
                  onTap: _share,
                ),
              ],
            ),
            SizedBox(height: 14),

            // Date Sandbox Stepper: Test widget across different dates!
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated.withValues(alpha: 0.6)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: sheetBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'የቀን ቅድመ-ዕይታ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMed,
                      ),
                    ),
                  ),
                  _MiniStepButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _stepDate(-1),
                  ),
                  InkWell(
                    onTap: _dayOffset != 0 ? _resetDate : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        _dayOffset == 0
                            ? 'ዛሬ'
                            : _dayOffset == -1
                                ? '-1'
                                : _dayOffset == 1
                                    ? '+1'
                                    : '$_dayOffset',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _dayOffset == 0 ? textHigh : accent,
                        ),
                      ),
                    ),
                  ),
                  _MiniStepButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _stepDate(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Active Selected Live Strip
            _SelectedLiveStrip(
              snapshot: s,
              styleIndex: _selected,
              showFasting: _showFasting,
              showGeez: _showGeez,
              showSaint: _showSaint,
              previewDark: _previewDark,
              familyOverride: _familyOverride,
            ),
            const SizedBox(height: 14),

            Text(
              'THEME FAMILY',
              style: GoogleFonts.cinzel(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: textMed,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OptionChip(
                  label: 'Auto · Layout',
                  icon: Icons.auto_awesome_rounded,
                  selected: _themeAuto,
                  onTap: () => _toggleOption(themeAuto: true),
                ),
                for (final family in WidgetThemeFamily.values)
                  _ThemeFamilyChip(
                    family: family,
                    selected: !_themeAuto && _themeFamily == family,
                    onTap: () => _toggleOption(themeFamily: family),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'ICONIC COLLECTION',
              style: GoogleFonts.cinzel(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
                color: textMed,
              ),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: HomeWidgetKind.values.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final kind = HomeWidgetKindX.fromIndex(index);
                final palette = WidgetTheme.palette(
                  kind: kind,
                  overrideFamily: _familyOverride,
                );
                return _WidgetCard(
                  selected: _selected == index,
                  onTap: () => _persist(index),
                  label: homeWidgetStyleLabel(index),
                  palette: palette,
                  child: buildHomeWidgetPreview(
                    styleIndex: index,
                    snapshot: _snapshots[index],
                    showGeez: _showGeez,
                    showFasting: _showFasting,
                    showSaint: _showSaint,
                    previewDark: _previewDark,
                    familyOverride: _familyOverride,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // Size Options (Compact vs Wide)
            Row(
              children: [
                Expanded(
                  child: _SizeChip(
                    label: 'Compact (2×2)',
                    subtitle: 'አነስተኛ ካሬ',
                    selected: _size == 'compact',
                    onTap: () => _toggleOption(size: 'compact'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SizeChip(
                    label: 'Wide (4×2)',
                    subtitle: 'ሰፊ ባነር',
                    selected: _size == 'wide',
                    onTap: () => _toggleOption(size: 'wide'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Feature Filter Chips (Fasting, Geez, Saint)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OptionChip(
                  label: 'ጾም (Fasting)',
                  icon: Icons.spa_rounded,
                  selected: _showFasting,
                  onTap: () => _toggleOption(fasting: !_showFasting),
                ),
                _OptionChip(
                  label: 'ግዕዝ (Ge\'ez)',
                  icon: Icons.translate_rounded,
                  selected: _showGeez,
                  onTap: () => _toggleOption(geez: !_showGeez),
                ),
                _OptionChip(
                  label: 'ጽላት / ቅዱስ (Saint)',
                  icon: Icons.auto_awesome_rounded,
                  selected: _showSaint,
                  onTap: () => _toggleOption(saint: !_showSaint),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Add to Home Screen Action CTA
            Builder(
              builder: (context) {
                final cta = homeWidgetAccentFor(
                  _selected,
                  familyOverride: _familyOverride,
                );
                final onCta = WidgetTheme.palette(
                  kind: HomeWidgetKindX.fromIndex(_selected),
                  overrideFamily: _familyOverride,
                ).isLight
                    ? Colors.white
                    : const Color(0xFF0B0D10);
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cta,
                      foregroundColor: onCta,
                      disabledBackgroundColor: cta.withValues(alpha: 0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.add_to_home_screen_rounded, size: 20),
                    onPressed: _busy ? null : _addToHome,
                    label: Text(
                      kIsWeb
                          ? 'Save Atelier Style'
                          : 'ወደ ስልክ ማያ ጨምር · Add to Home',
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ---------------------------------------------------------------------------
// MINI HELPERS & CHIPS
// ---------------------------------------------------------------------------

class _ThemedIconChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool busy;

  const _ThemedIconChip({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCardElevated : Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      icon,
                      size: 18,
                      color: isDark ? AppColors.darkTextHigh : Color(0xFF334155),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniStepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkCard : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.darkTextHigh : Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.accent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : (isDark ? AppColors.darkCardElevated : Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? accent : (isDark ? AppColors.darkBorder : Color(0xFFE2E8F0)),
            width: selected ? 1.6 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? accent : (isDark ? AppColors.darkTextHigh : Color(0xFF0F172A)),
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMed : Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppColors.accent;

    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        size: 15,
        color: selected ? Colors.white : accent,
      ),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: selected ? Colors.white : (isDark ? AppColors.darkTextHigh : Color(0xFF0F172A)),
        ),
      ),
      selectedColor: accent,
      backgroundColor: isDark ? AppColors.darkCardElevated : Color(0xFFF1F5F9),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: selected ? accent : (isDark ? AppColors.darkBorder : Color(0xFFE2E8F0)),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ---------------------------------------------------------------------------
// SELECTED LIVE STRIP
// ---------------------------------------------------------------------------

class _ThemeFamilyChip extends StatelessWidget {
  final WidgetThemeFamily family;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeFamilyChip({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = WidgetTheme.paletteFor(family);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.16) : p.chipFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? p.accent : p.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.dayNumeral,
                border: Border.all(color: p.accent, width: 1),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              family.label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? p.accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLiveStrip extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final int styleIndex;
  final bool showFasting;
  final bool showGeez;
  final bool showSaint;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const _SelectedLiveStrip({
    required this.snapshot,
    required this.styleIndex,
    required this.showFasting,
    required this.showGeez,
    required this.showSaint,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final kind = HomeWidgetKindX.fromIndex(styleIndex);
    final palette = WidgetTheme.palette(
      kind: kind,
      overrideFamily: familyOverride,
    );
    final accent = palette.accent;
    final styleTitle = homeWidgetStyleTitle(styleIndex);

    String detail;
    double? progress;
    switch (styleIndex) {
      case 2:
        if (snapshot.prophetsDayIndex != null && snapshot.prophetsDayIndex! > 0) {
          detail =
              'ጾመ ነቢያት · ቀን ${snapshot.prophetsDayIndex}/${snapshot.prophetsTotalDays}';
          progress = snapshot.prophetsProgress;
        } else {
          detail = 'ጾመ ነቢያት በ ${snapshot.daysUntilAdvent ?? 0} ቀን ይጀምራል';
          progress = 0;
        }
      case 3:
        detail =
            'ገና · ${snapshot.daysUntilGenna ?? 0} ቀን ቀረ (${snapshot.gennaLabel})';
        progress = snapshot.gennaSeasonProgress;
      case 5:
        detail = snapshot.saintNameEn;
        progress = null;
      case 6:
        detail =
            '${snapshot.formattedEthTime} · ${snapshot.formattedGregTime}';
        progress = null;
      case 7:
        detail =
            '${snapshot.upcomingTitleAm ?? snapshot.upcomingTitleEn ?? ''} · ${snapshot.daysUntilUpcoming ?? 0} ቀን';
        progress = null;
      case 8:
        detail = 'EC · ${snapshot.monthName} ${snapshot.eth.day}  |  GC · ${snapshot.gregLabel}';
        progress = null;
      case 11:
        detail = '${snapshot.geezDay} · ${snapshot.geezYear}';
        progress = null;
      case 12:
        detail = snapshot.isFasting
            ? (snapshot.fastingReason.isEmpty ? 'ጾም' : snapshot.fastingReason)
            : 'ፍስክ · Regular day';
        progress = null;
      case 13:
        detail = showSaint ? snapshot.saintName : snapshot.gregLabel;
        progress = null;
      default:
        detail = showSaint
            ? 'ጽላት · ${snapshot.saintName}'
            : 'Gregorian: ${snapshot.gregLabel}';
        progress = null;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: palette.backgroundGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                styleTitle,
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: accent,
                ),
              ),
              const Spacer(),
              if (showFasting)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: snapshot.isFasting
                        ? WidgetTheme.emerald.withValues(alpha: 0.15)
                        : palette.chipFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: palette.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    snapshot.isFasting ? 'ጾም' : 'ፍስክ',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: snapshot.isFasting
                          ? WidgetTheme.emerald
                          : palette.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${snapshot.weekdayName} · ${snapshot.monthName} ${snapshot.eth.day}'
            '${showGeez ? ' (${snapshot.geezDay})' : ''} · ${snapshot.eth.year} ዓ.ም',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: palette.textMuted,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 8),
            WidgetProgressBar(palette: palette, value: progress),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET CARD WRAPPER
// ---------------------------------------------------------------------------

class _WidgetCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;
  final Widget child;
  final WidgetThemePalette palette;

  const _WidgetCard({
    required this.selected,
    required this.onTap,
    required this.label,
    required this.child,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WidgetThemeTokens.radiusCard),
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              decoration: widgetCardShell(
                palette: palette,
                selected: selected,
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? palette.accent : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
