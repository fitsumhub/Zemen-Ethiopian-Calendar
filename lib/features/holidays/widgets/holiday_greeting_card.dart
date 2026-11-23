import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/brand/brand.dart';
import '../../shared/components/ethiocal_logo.dart';

/// Premium greeting card designed for WhatsApp / Telegram / Instagram share.
///
/// Fixed 4:5 social ratio so captures look intentional, not cropped.
class HolidayGreetingCard extends StatelessWidget {
  final List<Color> gradient;
  final String titleAmharic;
  final String titleEnglish;
  final String message;
  final String? recipient;
  final String? dateLine;
  final String? subtitleLine;
  final String? symbol;
  final GlobalKey? boundaryKey;

  const HolidayGreetingCard({
    super.key,
    required this.gradient,
    required this.titleAmharic,
    required this.titleEnglish,
    required this.message,
    this.recipient,
    this.dateLine,
    this.subtitleLine,
    this.symbol,
    this.boundaryKey,
  });

  static const gold = Color(0xFFE8B84A);
  static const ethioGreen = Color(0xFF078930);
  static const ethioYellow = Color(0xFFFCDD09);
  static const ethioRed = Color(0xFFDA121A);

  @override
  Widget build(BuildContext context) {
    final card = AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: gradient.length >= 2
                ? gradient
                : [gradient.first, gradient.first],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Soft vignette
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.2),
                    radius: 1.15,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.28),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.14),
                  ),
                ),
              ),
              Positioned(
                bottom: -55,
                left: -45,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ethioGreen.withValues(alpha: 0.12),
                  ),
                ),
              ),
              // Inner gold frame
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              // Tricolor top ribbon
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 5, color: ethioGreen)),
                    Expanded(child: Container(height: 5, color: ethioYellow)),
                    Expanded(child: Container(height: 5, color: ethioRed)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const EthioCalLogo(size: 44, showGlow: false),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Brand.shortName,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                Brand.productLine,
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dateLine != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: gold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: gold.withValues(alpha: 0.55),
                              ),
                            ),
                            child: Text(
                              dateLine!,
                              style: GoogleFonts.outfit(
                                color: gold,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    if (symbol != null) ...[
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          symbol!,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      titleAmharic,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: gold,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      titleEnglish,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    if (subtitleLine != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitleLine!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (recipient != null && recipient!.trim().isNotEmpty) ...[
                      Text(
                        'ለ፦ ${recipient!.trim()}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.34),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        message.trim().isEmpty
                            ? 'እንኳን በሰላም አደረሳችሁ!'
                            : message.trim(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Container(height: 1, color: Colors.white24),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            Brand.tagline,
                            style: GoogleFonts.outfit(
                              color: Colors.white54,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(height: 1, color: Colors.white24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Brand.displayNameBilingual,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: gold.withValues(alpha: 0.92),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 4, color: ethioGreen)),
                    Expanded(child: Container(height: 4, color: ethioYellow)),
                    Expanded(child: Container(height: 4, color: ethioRed)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (boundaryKey == null) return card;
    return RepaintBoundary(key: boundaryKey, child: card);
  }
}

/// Shared gradient themes for greeting cards.
class GreetingCardThemes {
  static const labels = [
    'Imperial Indigo',
    'Emerald Gold',
    'Demera Crimson',
    'Adey Amber',
    'Lake Cyan',
  ];

  static const gradients = <List<Color>>[
    [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF0F172A)],
    [Color(0xFF06221A), Color(0xFF0B3D2E), Color(0xFF060C16)],
    [Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF1C1917)],
    [Color(0xFF451A03), Color(0xFF92400E), Color(0xFF1C1917)],
    [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
  ];
}
