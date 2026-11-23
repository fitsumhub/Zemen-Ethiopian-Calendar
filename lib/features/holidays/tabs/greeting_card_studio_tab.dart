import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/ads/ad_frequency_controller.dart';
import '../../../core/brand/brand.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/card_image_exporter.dart';
import '../../../core/utils/share_helper.dart';
import '../widgets/holiday_greeting_card.dart';

class GreetingCardStudioTab extends StatefulWidget {
  final Holiday? initialHoliday;

  const GreetingCardStudioTab({super.key, this.initialHoliday});

  @override
  State<GreetingCardStudioTab> createState() => _GreetingCardStudioTabState();
}

class _GreetingCardStudioTabState extends State<GreetingCardStudioTab> {
  final GlobalKey _cardKey = GlobalKey();
  int _selectedPreset = 0;
  int _selectedGradient = 1;
  bool _sharing = false;
  late TextEditingController _recipientController;
  late TextEditingController _messageController;

  final List<Map<String, String>> _presets = const [
    {
      'titleAmharic': 'መልካም አዲስ ዓመት (እንቁጣጣሽ)',
      'titleEnglish': 'Happy Ethiopian New Year',
      'symbol': '🌼',
      'defaultMessage':
          'እንኳን ከአሮጌው ዓመት ወደ አዲሱ ዓመት በሰላም አሸጋገራችሁ! አዲሱ ዓመት የሰላም፣ የፍቅርና የበረከት ይሁንላችሁ!',
      'match': 'እንቁጣጣሽ|New Year|Enkutatash',
    },
    {
      'titleAmharic': 'መልካም የመስቀል በዓል',
      'titleEnglish': 'Happy Meskel',
      'symbol': '🔥',
      'defaultMessage':
          'እንኳን ለብርሃነ መስቀሉ በዓል በሰላም አደረሳችሁ! የመስቀሉ ፍቅርና በረከት ከሁላችን ጋር ይሁን!',
      'match': 'መስቀል|Meskel',
    },
    {
      'titleAmharic': 'መልካም የገና በዓል',
      'titleEnglish': 'Merry Genna (Christmas)',
      'symbol': '🎄',
      'defaultMessage':
          'እንኳን ለጌታችን ለመድኃኒታችን ለኢየሱስ ክርስቶስ የልደት በዓል በሰላም አደረሳችሁ! መልካም የገና በዓል!',
      'match': 'ገና|Genna|Christmas',
    },
    {
      'titleAmharic': 'መልካም የጥምቀት በዓል',
      'titleEnglish': 'Happy Timket',
      'symbol': '🕊️',
      'defaultMessage':
          'እንኳን ለብርሃነ ጥምቀቱ በዓል በሰላም አደረሳችሁ! የጥምቀቱ በረከትና ረድኤት አይለያችሁ!',
      'match': 'ጥምቀት|Timket|Epiphany',
    },
    {
      'titleAmharic': 'መልካም የትንሣኤ በዓል (ፋሲካ)',
      'titleEnglish': 'Happy Fasika (Easter)',
      'symbol': '🕯️',
      'defaultMessage':
          'እንኳን ለብርሃነ ትንሣኤው በሰላም አደረሳችሁ! ክርስቶስ ተንሥአ እሙታን! በዓሉ የሰላምና የደስታ ይሁንላችሁ!',
      'match': 'ፋሲካ|Fasika|Easter|ትንሣኤ',
    },
    {
      'titleAmharic': 'ዒድ ሙባረክ',
      'titleEnglish': 'Eid Mubarak',
      'symbol': '🌙',
      'defaultMessage':
          'እንኳን ለዒድ በዓል በሰላም አደረሳችሁ! ኩሉ ዓም ወአንቱም ቢኸይር! ዒድ ሙባረክ!',
      'match': 'ዒድ|Eid',
    },
    {
      'titleAmharic': 'ባጋም ገዳ ዒሬቻ ገሴስቱ!',
      'titleEnglish': 'Happy Irreecha',
      'symbol': '🌾',
      'defaultMessage':
          'እንኳን ለምስጋናው እና ለእርቅ በዓል ለዒሬቻ በሰላም አደረሳችሁ! ሆራ ፊንፊኔ በረከት ይሁንልን!',
      'match': 'ዒሬቻ|Irreecha',
    },
    {
      'titleAmharic': 'መልካም በዓል',
      'titleEnglish': 'Blessed Holiday',
      'symbol': '✨',
      'defaultMessage': 'እንኳን በሰላም አደረሳችሁ! መልካም ዕለትና በረከት ይሁንላችሁ!',
      'match': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: 'ለሁሉም ወዳጅ ዘመዶቼ');
    _applyHoliday(widget.initialHoliday);
    _messageController = TextEditingController(
      text: _presets[_selectedPreset]['defaultMessage']!,
    );
  }

  @override
  void didUpdateWidget(covariant GreetingCardStudioTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialHoliday != oldWidget.initialHoliday &&
        widget.initialHoliday != null) {
      setState(() {
        _applyHoliday(widget.initialHoliday);
        _messageController.text =
            _presets[_selectedPreset]['defaultMessage']!;
      });
    }
  }

  void _applyHoliday(Holiday? holiday) {
    if (holiday == null) return;
    final hay =
        '${holiday.titleAmharic} ${holiday.titleEnglish}'.toLowerCase();
    for (var i = 0; i < _presets.length; i++) {
      final match = _presets[i]['match']!;
      if (match.isEmpty) continue;
      final parts = match.split('|');
      if (parts.any((p) => hay.contains(p.toLowerCase()))) {
        _selectedPreset = i;
        return;
      }
    }
    _selectedPreset = _presets.length - 1;
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final file = await CardImageExporter.capture(
        _cardKey,
        filePrefix: 'zemen_holiday_card',
      );
      final preset = _presets[_selectedPreset];
      final caption =
          '${preset['symbol']} ${preset['titleAmharic']}\n'
          '${preset['titleEnglish']}\n\n'
          '${_messageController.text.trim()}\n\n'
          '— ${Brand.displayNameBilingual}';
      if (file != null) {
        await ShareHelper.shareImageFile(
          file,
          text: caption,
          subject: preset['titleEnglish'],
        );
      } else {
        await ShareHelper.share(caption, subject: preset['titleEnglish']);
      }
      AdFrequencyController.instance.recordUserAction('share_holiday_card');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = _presets[_selectedPreset];
    final today = EthiopianCalendarEngine.todayEthiopian();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Text(
          'Greeting Card Studio',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Design a premium card, then share as an image',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _presets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final selected = _selectedPreset == i;
              return ChoiceChip(
                avatar: Text(_presets[i]['symbol']!),
                label: Text(
                  _presets[i]['titleEnglish']!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _selectedPreset = i;
                    _messageController.text =
                        _presets[i]['defaultMessage']!;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        HolidayGreetingCard(
          boundaryKey: _cardKey,
          gradient: GreetingCardThemes.gradients[_selectedGradient],
          titleAmharic: widget.initialHoliday != null &&
                  _selectedPreset == _presets.length - 1
              ? widget.initialHoliday!.titleAmharic
              : preset['titleAmharic']!,
          titleEnglish: widget.initialHoliday != null &&
                  _selectedPreset == _presets.length - 1
              ? widget.initialHoliday!.titleEnglish
              : preset['titleEnglish']!,
          symbol: preset['symbol'],
          recipient: _recipientController.text,
          message: _messageController.text,
          dateLine: '${today.year} ዓ.ም',
        ),
        const SizedBox(height: 14),

        // Theme picker with labels
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: GreetingCardThemes.gradients.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final selected = _selectedGradient == i;
              return InkWell(
                onTap: () => setState(() => _selectedGradient = i),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: GreetingCardThemes.gradients[i],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: HolidayGreetingCard.gold
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      GreetingCardThemes.labels[i].split(' ').first,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),

        TextField(
          controller: _recipientController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'ተቀባይ · Recipient',
            labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _messageController,
          maxLines: 3,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'የመልካም ምኞት ቃል · Blessing',
            labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _sharing ? null : _shareCard,
          icon: _sharing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.ios_share_rounded),
          label: Text(
            _sharing
                ? 'Preparing image…'
                : 'Share as image · እንደ ምስል አጋራ',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
