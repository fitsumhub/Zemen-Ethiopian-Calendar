import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/brand/brand.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/card_image_exporter.dart';
import '../../../core/utils/share_helper.dart';
import '../widgets/holiday_greeting_card.dart';

class HolidayCardShareDialog extends StatefulWidget {
  final EthiopianDate currentDate;
  final AppLanguage currentLanguage;
  final Holiday? holiday;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenStudio;

  const HolidayCardShareDialog({
    super.key,
    required this.currentDate,
    this.currentLanguage = AppLanguage.amharic,
    this.holiday,
    required this.onDismiss,
    this.onOpenStudio,
  });

  @override
  State<HolidayCardShareDialog> createState() => _HolidayCardShareDialogState();
}

class _HolidayCardShareDialogState extends State<HolidayCardShareDialog> {
  final GlobalKey _cardKey = GlobalKey();
  late TextEditingController _messageController;
  int _selectedGradient = 1;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    final h = widget.holiday;
    _messageController = TextEditingController(
      text: h != null
          ? 'እንኳን ለ${h.titleAmharic} በሰላም አደረሳችሁ! መልካም በዓል ይሁንላችሁ! 🇪🇹✨'
          : 'እንኳን ለዚህ የተቀደሰ ቀን በሰላም አደረሳችሁ! መልካም ዕለት ይሁንላችሁ! 🇪🇹✨',
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final file = await CardImageExporter.capture(
        _cardKey,
        filePrefix: 'zemen_day_card',
      );
      final monthName = LocaleStrings.getMonthName(
        widget.currentDate.month,
        widget.currentLanguage,
      );
      final caption = widget.holiday != null
          ? '✨ ${widget.holiday!.titleAmharic}\n'
              '${widget.holiday!.titleEnglish}\n\n'
              '${_messageController.text.trim()}\n\n'
              '— ${Brand.displayNameBilingual}'
          : '✨ ${widget.currentDate.day} $monthName '
              '${widget.currentDate.year} ዓ.ም\n\n'
              '${_messageController.text.trim()}\n\n'
              '— ${Brand.displayNameBilingual}';
      if (file != null) {
        await ShareHelper.shareImageFile(
          file,
          text: caption,
          subject: widget.holiday?.titleEnglish ?? Brand.displayName,
        );
      } else {
        await ShareHelper.share(caption);
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dow = EthiopianCalendarEngine.getDayOfWeek(widget.currentDate);
    final gDate = EthiopianCalendarEngine.toGregorian(widget.currentDate);
    final monthName = LocaleStrings.getMonthName(
      widget.currentDate.month,
      widget.currentLanguage,
    );
    final weekdayName =
        LocaleStrings.getWeekdayLong(dow, widget.currentLanguage);
    final holiday = widget.holiday;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Share greeting card',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                    onPressed: widget.onDismiss,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              HolidayGreetingCard(
                boundaryKey: _cardKey,
                gradient: GreetingCardThemes.gradients[_selectedGradient],
                titleAmharic: holiday?.titleAmharic ??
                    '$monthName ${widget.currentDate.day}',
                titleEnglish: holiday?.titleEnglish ??
                    '${widget.currentDate.year} ዓ.ም',
                symbol: holiday != null ? '🎉' : '📅',
                message: _messageController.text,
                dateLine: '${widget.currentDate.year} ዓ.ም',
                subtitleLine:
                    '$weekdayName · ${gDate.day}/${gDate.month}/${gDate.year} G.C.',
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  GreetingCardThemes.gradients.length,
                  (i) {
                    final selected = _selectedGradient == i;
                    return InkWell(
                      onTap: () => setState(() => _selectedGradient = i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: GreetingCardThemes.gradients[i],
                          ),
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: AppColors.textPrimary,
                                  width: 2.4,
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.outfit(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Blessing message',
                  labelStyle:
                      GoogleFonts.outfit(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.canvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(
                  _sharing ? 'Preparing…' : 'Share as image',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (widget.onOpenStudio != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: widget.onOpenStudio,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(
                    'Customize in Studio',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
