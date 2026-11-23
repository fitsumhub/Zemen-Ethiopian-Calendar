import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widgets/home_widget_engine.dart';
import '../../../core/widgets/widget_chrome.dart';
import '../../../core/widgets/widget_theme.dart';

export '../../../core/widgets/widget_theme.dart';
export '../../../core/widgets/widget_chrome.dart';

/// Legacy alias kept so older call sites keep compiling during migration.
class WidgetAtelier {
  static Color get champagne => WidgetTheme.champagne;
  static Color get champagneSoft => WidgetTheme.champagneSoft;
  static Color get emerald => WidgetTheme.emerald;
  static Color get muted => const Color(0xFF9AA3B2);
  static Color get ivory => WidgetTheme.ivory;
  static Color get hairline => const Color(0xFF2E3542);
  static Color get noir => WidgetTheme.noir;

  static LinearGradient foilGradient({bool soft = false}) =>
      WidgetTheme.paletteFor(WidgetThemeFamily.noirGold).backgroundGradient;

  static BoxDecoration cardShell({required bool selected}) => widgetCardShell(
        palette: WidgetTheme.paletteFor(WidgetThemeFamily.noirGold),
        selected: selected,
      );
}

WidgetThemePalette _p(
  HomeWidgetKind kind,
  WidgetThemeFamily? overrideFamily,
) =>
    WidgetTheme.palette(kind: kind, overrideFamily: overrideFamily);

// ─── Layout 0 — Basic date (reference product card) ──────────────────────────

class LuxuryBasicDatePreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool showFasting;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const LuxuryBasicDatePreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.showFasting,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.basicDate, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      showTicks: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.chipFill,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              snapshot.weekdayName,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.accent,
              ),
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '${snapshot.eth.day}',
                style: WidgetChrome.dayStyle(p, size: 46),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.monthName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.textMuted,
                      ),
                    ),
                    Text(
                      showGeez
                          ? '${snapshot.eth.year} · ${snapshot.geezDay}'
                          : '${snapshot.eth.year}',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(height: 1, color: p.border),
          const SizedBox(height: 8),
          Text(
            snapshot.gregLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 1 — Classic date (coral header ribbon) ───────────────────────────

class LuxuryClassicDatePreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool showFasting;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const LuxuryClassicDatePreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.showFasting,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.classicDate, familyOverride);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.accent, WidgetTheme.coralDeep],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            snapshot.weekdayName,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: p.canvas,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  snapshot.monthName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.textPrimary,
                  ),
                ),
                Text(
                  '${snapshot.eth.day}',
                  style: GoogleFonts.outfit(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: p.textPrimary,
                    letterSpacing: -1.5,
                  ),
                ),
                Text(
                  showGeez
                      ? '${snapshot.geezDay} · ${snapshot.eth.year}'
                      : '${snapshot.eth.year}',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Layout 2 — Prophets / PRO tracker ───────────────────────────────────────

class LuxuryProphetsPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const LuxuryProphetsPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.prophetsFast, familyOverride);
    final active =
        snapshot.prophetsDayIndex != null && snapshot.prophetsDayIndex! > 0;
    final number =
        active ? '${snapshot.prophetsDayIndex}' : '${snapshot.daysUntilAdvent ?? 0}';

    return WidgetCornerFrame(
      palette: p,
      showTicks: false,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: Color(0xFF43A047),
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PRO',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(number, style: WidgetChrome.dayStyle(p, size: 42)),
              const SizedBox(width: 4),
              Text(
                'ቀን',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            active ? 'ጾመ ነቢያት' : 'ጾመ ነቢያት ይጀምራል',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.textPrimary,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Layout 3 — Nativity / countdown ─────────────────────────────────────────

class LuxuryNativityPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const LuxuryNativityPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.nativityCountdown, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      showTicks: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${snapshot.daysUntilGenna ?? 0}',
                style: WidgetChrome.dayStyle(p, size: 46),
              ),
              const SizedBox(width: 4),
              Text(
                'ቀን',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ቀናት ቀርተዋል',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'የገና ቆጣሪ',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: p.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 4 — Imperial gold focal day ──────────────────────────────────────

class ImperialGoldPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool showSaint;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const ImperialGoldPreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.showSaint,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.imperialGold, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetBrandMark(palette: p, label: 'IMPERIAL'),
          const SizedBox(height: 10),
          Text(snapshot.weekdayName, style: WidgetChrome.bodyStyle(p)),
          const Spacer(),
          Text('${snapshot.eth.day}', style: WidgetChrome.dayStyle(p, size: 48)),
          Text(
            '${snapshot.monthName}  ·  ${showGeez ? snapshot.geezYear : snapshot.eth.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.headingStyle(p, size: 12.5),
          ),
          const Spacer(),
          WidgetFoilRule(palette: p, width: 44),
          const SizedBox(height: 6),
          Text(
            showSaint ? snapshot.saintName : snapshot.gregLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 5 — Saint focus ──────────────────────────────────────────────────

class ObsidianSaintPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const ObsidianSaintPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.obsidianSaint, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.accent),
                  color: p.chipFill,
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 14, color: p.accent),
              ),
              const SizedBox(width: 8),
              Text('ቅዱስ', style: WidgetChrome.labelStyle(p)),
            ],
          ),
          const Spacer(),
          Text(
            snapshot.saintName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.headingStyle(p, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.saintNameEn,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
          const Spacer(),
          WidgetFoilRule(palette: p, width: 48),
          const SizedBox(height: 6),
          Text(
            '${snapshot.monthName} ${snapshot.eth.day}',
            style: WidgetChrome.headingStyle(p, size: 11.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 6 — Dual clock ───────────────────────────────────────────────────

class AtelierClockPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const AtelierClockPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.atelierClock, familyOverride);
    final eth =
        snapshot.formattedEthTime.isEmpty ? '—' : snapshot.formattedEthTime;
    final greg =
        snapshot.formattedGregTime.isEmpty ? '—' : snapshot.formattedGregTime;

    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetBrandMark(palette: p, label: 'TIME'),
          const Spacer(),
          Text(eth, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: WidgetChrome.headingStyle(p, size: 16)),
          Text('Ethiopian hour', style: WidgetChrome.bodyStyle(p, size: 9.5)),
          const SizedBox(height: 10),
          WidgetFoilRule(palette: p, expand: true),
          const SizedBox(height: 10),
          Text(greg, style: WidgetChrome.dayStyle(p, size: 22)),
          Text(
            '${snapshot.weekdayName} · ${snapshot.monthName} ${snapshot.eth.day}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// ─── Layout 7 — Feast countdown ──────────────────────────────────────────────

class FeastAtelierPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const FeastAtelierPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.feastAtelier, familyOverride);
    final title = (snapshot.upcomingTitleAm?.isNotEmpty ?? false)
        ? snapshot.upcomingTitleAm!
        : (snapshot.upcomingTitleEn ?? 'Next feast');
    final days = snapshot.daysUntilUpcoming ?? 0;

    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WidgetBrandMark(palette: p, label: 'FEAST'),
          const Spacer(),
          Text('$days', style: WidgetChrome.dayStyle(p, size: 42)),
          Text(
            days == 0 ? 'TODAY · ዛሬ' : 'DAYS REMAINING',
            style: WidgetChrome.labelStyle(p),
          ),
          const Spacer(),
          WidgetFoilRule(palette: p, width: 44),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.headingStyle(p, size: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 8 — Dual EC/GC stack ─────────────────────────────────────────────

class DualStackPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const DualStackPreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.dualStack, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      padding: const EdgeInsets.all(WidgetThemeTokens.padCompact),
      child: Column(
        children: [
          WidgetBrandMark(palette: p, label: 'DUAL'),
          const SizedBox(height: 10),
          _DualRow(
            palette: p,
            badge: 'EC',
            title: '${snapshot.monthName} ${snapshot.eth.day}',
            subtitle: showGeez
                ? '${snapshot.geezDay} · ${snapshot.eth.year}'
                : '${snapshot.eth.year} ዓ.ም',
            emphasize: true,
          ),
          const SizedBox(height: 8),
          WidgetFoilRule(palette: p, expand: true),
          const SizedBox(height: 8),
          _DualRow(
            palette: p,
            badge: 'GC',
            title: snapshot.gregLabel,
            subtitle: snapshot.weekdayName,
            emphasize: false,
          ),
        ],
      ),
    );
  }
}

class _DualRow extends StatelessWidget {
  final WidgetThemePalette palette;
  final String badge;
  final String title;
  final String subtitle;
  final bool emphasize;

  const _DualRow({
    required this.palette,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.emphasize,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: p.accent.withValues(alpha: 0.65)),
            color: p.chipFill,
          ),
          child: Text(badge, style: WidgetChrome.brandStyle(p)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WidgetChrome.headingStyle(p, size: emphasize ? 14.5 : 12.5),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WidgetChrome.bodyStyle(p, size: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Layout 9 — Emerald glass ────────────────────────────────────────────────

class EmeraldGlassPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool showFasting;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const EmeraldGlassPreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.showFasting,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.emeraldGlass, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: WidgetBrandMark(palette: p, label: 'EMERALD')),
              if (showFasting)
                WidgetStatusDot(palette: p, active: snapshot.isFasting),
            ],
          ),
          const Spacer(),
          Text('${snapshot.eth.day}', style: WidgetChrome.dayStyle(p, size: 46)),
          Text(snapshot.monthName, style: WidgetChrome.headingStyle(p, size: 15)),
          const Spacer(),
          Text(
            showGeez
                ? '${snapshot.weekdayName} · ${snapshot.geezDay}'
                : snapshot.gregLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 10 — Parchment scroll ────────────────────────────────────────────

class ParchmentScrollPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showGeez;
  final bool showSaint;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const ParchmentScrollPreview({
    super.key,
    required this.snapshot,
    required this.showGeez,
    required this.showSaint,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.parchmentScroll, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        children: [
          Text(
            snapshot.weekdayName.toUpperCase(),
            style: WidgetChrome.labelStyle(p),
          ),
          const SizedBox(height: 6),
          WidgetFoilRule(palette: p, width: 40),
          const Spacer(),
          Text('${snapshot.eth.day}', style: WidgetChrome.dayStyle(p)),
          Text(
            '${snapshot.monthName} ${snapshot.eth.year}',
            style: WidgetChrome.headingStyle(p, size: 13),
          ),
          if (showGeez)
            Text(
              snapshot.geezDay,
              style: GoogleFonts.notoSansEthiopic(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: p.accentSoft,
              ),
            ),
          const Spacer(),
          Text(
            showSaint ? snapshot.saintName : snapshot.gregLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 11 — Ge'ez monument ──────────────────────────────────────────────

class GeezMonumentPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const GeezMonumentPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.geezMonument, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        children: [
          WidgetBrandMark(palette: p, label: 'ግዕዝ'),
          const Spacer(),
          Text(
            snapshot.geezDay,
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 54,
              fontWeight: FontWeight.w900,
              color: p.dayNumeral,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            snapshot.geezYear,
            style: GoogleFonts.notoSansEthiopic(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: p.accentSoft,
            ),
          ),
          const Spacer(),
          WidgetFoilRule(palette: p, width: 40),
          const SizedBox(height: 6),
          Text(
            '${snapshot.monthName} ${snapshot.eth.day}',
            style: WidgetChrome.bodyStyle(p, size: 11.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 12 — Fasting status ──────────────────────────────────────────────

class MidnightFastPreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const MidnightFastPreview({
    super.key,
    required this.snapshot,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.midnightFast, familyOverride);
    final fasting = snapshot.isFasting;
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fasting ? Icons.spa_rounded : Icons.restaurant_rounded,
                size: 16,
                color: p.accent,
              ),
              const SizedBox(width: 8),
              Text(
                fasting ? 'ጾም' : 'ፍስክ',
                style: WidgetChrome.labelStyle(p),
              ),
            ],
          ),
          const Spacer(),
          Text(
            fasting ? 'Fasting Day' : 'Feast Day',
            style: WidgetChrome.headingStyle(p, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            fasting
                ? (snapshot.fastingReason.isEmpty
                    ? 'Observance today'
                    : snapshot.fastingReason)
                : 'Regular / feast meal',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p),
          ),
          const Spacer(),
          WidgetFoilRule(palette: p, width: 36),
          const SizedBox(height: 6),
          Text(
            '${snapshot.weekdayName} · ${snapshot.monthName} ${snapshot.eth.day}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.bodyStyle(p, size: 10.5),
          ),
        ],
      ),
    );
  }
}

// ─── Layout 13 — Month glance ────────────────────────────────────────────────

class MonthGlancePreview extends StatelessWidget {
  final HomeWidgetSnapshot snapshot;
  final bool showSaint;
  final bool previewDark;
  final WidgetThemeFamily? familyOverride;

  const MonthGlancePreview({
    super.key,
    required this.snapshot,
    required this.showSaint,
    required this.previewDark,
    this.familyOverride,
  });

  @override
  Widget build(BuildContext context) {
    final p = _p(HomeWidgetKind.monthGlance, familyOverride);
    return WidgetCornerFrame(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(snapshot.monthName.toUpperCase(), style: WidgetChrome.labelStyle(p)),
          Text('${snapshot.eth.year} ዓ.ም', style: WidgetChrome.bodyStyle(p, size: 10.5)),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${snapshot.eth.day}', style: WidgetChrome.dayStyle(p)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    snapshot.weekdayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: WidgetChrome.headingStyle(p, size: 13.5),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: p.chipFill,
              borderRadius: BorderRadius.circular(WidgetThemeTokens.radiusChip),
              border: Border.all(color: p.border.withValues(alpha: 0.8)),
            ),
            child: Text(
              showSaint
                  ? snapshot.saintName
                  : (snapshot.upcomingTitleAm ?? snapshot.gregLabel),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WidgetChrome.bodyStyle(p, size: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Maps style index → unique layout preview.
Widget buildHomeWidgetPreview({
  required int styleIndex,
  required HomeWidgetSnapshot snapshot,
  required bool showGeez,
  required bool showFasting,
  required bool showSaint,
  required bool previewDark,
  WidgetThemeFamily? familyOverride,
}) {
  switch (styleIndex) {
    case 1:
      return LuxuryClassicDatePreview(
        snapshot: snapshot,
        showGeez: showGeez,
        showFasting: showFasting,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 2:
      return LuxuryProphetsPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 3:
      return LuxuryNativityPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 4:
      return ImperialGoldPreview(
        snapshot: snapshot,
        showGeez: showGeez,
        showSaint: showSaint,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 5:
      return ObsidianSaintPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 6:
      return AtelierClockPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 7:
      return FeastAtelierPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 8:
      return DualStackPreview(
        snapshot: snapshot,
        showGeez: showGeez,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 9:
      return EmeraldGlassPreview(
        snapshot: snapshot,
        showGeez: showGeez,
        showFasting: showFasting,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 10:
      return ParchmentScrollPreview(
        snapshot: snapshot,
        showGeez: showGeez,
        showSaint: showSaint,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 11:
      return GeezMonumentPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 12:
      return MidnightFastPreview(
        snapshot: snapshot,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    case 13:
      return MonthGlancePreview(
        snapshot: snapshot,
        showSaint: showSaint,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
    default:
      return LuxuryBasicDatePreview(
        snapshot: snapshot,
        showGeez: showGeez,
        showFasting: showFasting,
        previewDark: previewDark,
        familyOverride: familyOverride,
      );
  }
}

String homeWidgetStyleTitle(int styleIndex) => switch (styleIndex) {
      1 => 'Classic date',
      2 => 'Prophets PRO',
      3 => 'Nativity countdown',
      4 => 'Imperial Gold',
      5 => 'Obsidian Saint',
      6 => 'Atelier Clock',
      7 => 'Feast Atelier',
      8 => 'Dual Stack',
      9 => 'Emerald Glass',
      10 => 'Parchment Scroll',
      11 => 'Ge\'ez Monument',
      12 => 'Midnight Fast',
      13 => 'Month Glance',
      _ => 'Basic date',
    };

String homeWidgetStyleLabel(int styleIndex) => switch (styleIndex) {
      1 => 'Classic date',
      2 => 'Prophets PRO',
      3 => 'Nativity countdown',
      4 => 'Imperial Gold',
      5 => 'Obsidian Saint',
      6 => 'Atelier Clock',
      7 => 'Feast Atelier',
      8 => 'Dual Stack',
      9 => 'Emerald Glass',
      10 => 'Parchment',
      11 => 'ግዕዝ Monument',
      12 => 'Midnight Fast',
      13 => 'Month Glance',
      _ => 'Basic date',
    };

Color homeWidgetAccentFor(int styleIndex, {WidgetThemeFamily? familyOverride}) {
  final kind = HomeWidgetKindX.fromIndex(styleIndex);
  return WidgetTheme.palette(kind: kind, overrideFamily: familyOverride).accent;
}

bool homeWidgetIsLuxury(int styleIndex) => true;
