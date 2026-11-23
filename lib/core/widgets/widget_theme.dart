import 'package:material_ui/material_ui.dart';

import 'home_widget_engine.dart';

/// Premium Zemen widget theme families.
enum WidgetThemeFamily {
  /// Clean white cards + coral accent (product reference look).
  coralStudio,
  noirGold,
  emeraldHeritage,
  parchmentClassic,
  minimalModern,
}

extension WidgetThemeFamilyX on WidgetThemeFamily {
  String get id => name;

  String get label => switch (this) {
        WidgetThemeFamily.coralStudio => 'Coral Studio',
        WidgetThemeFamily.noirGold => 'Noir Gold',
        WidgetThemeFamily.emeraldHeritage => 'Emerald Heritage',
        WidgetThemeFamily.parchmentClassic => 'Parchment Classic',
        WidgetThemeFamily.minimalModern => 'Minimal Modern',
      };

  String get subtitle => switch (this) {
        WidgetThemeFamily.coralStudio => 'Clean · bold product cards',
        WidgetThemeFamily.noirGold => 'Luxury · champagne foil',
        WidgetThemeFamily.emeraldHeritage => 'Calm · Ethiopian emerald',
        WidgetThemeFamily.parchmentClassic => 'Editorial · antique gold',
        WidgetThemeFamily.minimalModern => 'Clean · maximum clarity',
      };

  static WidgetThemeFamily fromId(String? id) {
    return WidgetThemeFamily.values.firstWhere(
      (f) => f.name == id,
      orElse: () => WidgetThemeFamily.coralStudio,
    );
  }

  static WidgetThemeFamily fromIndex(int index) =>
      WidgetThemeFamily.values[index.clamp(0, WidgetThemeFamily.values.length - 1)];
}

/// Centralized spacing / radius tokens for widget chrome.
class WidgetThemeTokens {
  static const double radiusCard = 22;
  static const double radiusChip = 10;
  static const double pad = 12;
  static const double padCompact = 10;
  static const double hairline = 1.2;
  static const double cornerTick = 10;
  static const double brandMark = 16;
  static const double dayNumeral = 48;
  static const double dayNumeralCompact = 40;
}

/// Resolved palette for one family — no scattered hardcodes in previews.
class WidgetThemePalette {
  final WidgetThemeFamily family;
  final Color canvas;
  final Color canvasElevated;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color dayNumeral;
  final Color chipFill;
  final Color progressTrack;
  final Color progressFill;
  final bool isLight;
  final List<Color> gradient;

  const WidgetThemePalette({
    required this.family,
    required this.canvas,
    required this.canvasElevated,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.dayNumeral,
    required this.chipFill,
    required this.progressTrack,
    required this.progressFill,
    required this.isLight,
    required this.gradient,
  });

  LinearGradient get backgroundGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient,
      );
}

/// Design-system entry point for Zemen home widgets.
class WidgetTheme {
  WidgetTheme._();

  static const champagne = Color(0xFFD4AF74);
  static const champagneSoft = Color(0xFFF0DFB8);
  static const emerald = Color(0xFF1FA971);
  static const emeraldGlow = Color(0xFF7DDEB3);
  static const coral = Color(0xFFE57373);
  static const coralDeep = Color(0xFFEF5350);
  static const noir = Color(0xFF07090C);
  static const ivory = Color(0xFFF8F3EA);
  static const ink = Color(0xFF241910);
  static const parchment = Color(0xFFF3E6CE);

  /// Canonical family for each of the 14 layout kinds.
  static WidgetThemeFamily familyForKind(HomeWidgetKind kind) {
    return switch (kind) {
      HomeWidgetKind.basicDate => WidgetThemeFamily.coralStudio,
      HomeWidgetKind.classicDate => WidgetThemeFamily.coralStudio,
      HomeWidgetKind.prophetsFast => WidgetThemeFamily.coralStudio,
      HomeWidgetKind.nativityCountdown => WidgetThemeFamily.coralStudio,
      HomeWidgetKind.imperialGold => WidgetThemeFamily.noirGold,
      HomeWidgetKind.obsidianSaint => WidgetThemeFamily.noirGold,
      HomeWidgetKind.atelierClock => WidgetThemeFamily.minimalModern,
      HomeWidgetKind.feastAtelier => WidgetThemeFamily.noirGold,
      HomeWidgetKind.dualStack => WidgetThemeFamily.coralStudio,
      HomeWidgetKind.emeraldGlass => WidgetThemeFamily.emeraldHeritage,
      HomeWidgetKind.parchmentScroll => WidgetThemeFamily.parchmentClassic,
      HomeWidgetKind.geezMonument => WidgetThemeFamily.noirGold,
      HomeWidgetKind.midnightFast => WidgetThemeFamily.emeraldHeritage,
      HomeWidgetKind.monthGlance => WidgetThemeFamily.coralStudio,
    };
  }

  /// Resolve palette. [overrideFamily] forces one family across studio/Android.
  static WidgetThemePalette palette({
    required HomeWidgetKind kind,
    WidgetThemeFamily? overrideFamily,
  }) {
    final family = overrideFamily ?? familyForKind(kind);
    return paletteFor(family);
  }

  static WidgetThemePalette paletteFor(WidgetThemeFamily family) {
    return switch (family) {
      WidgetThemeFamily.coralStudio => const WidgetThemePalette(
          family: WidgetThemeFamily.coralStudio,
          canvas: Color(0xFFFFFFFF),
          canvasElevated: Color(0xFFFAFAFA),
          border: Color(0xFFE5E7EB),
          accent: coral,
          accentSoft: Color(0xFFFFCDD2),
          textPrimary: Color(0xFF111827),
          textSecondary: Color(0xFF374151),
          textMuted: Color(0xFF9CA3AF),
          dayNumeral: coral,
          chipFill: Color(0x26E57373),
          progressTrack: Color(0xFFF3F4F6),
          progressFill: coral,
          isLight: true,
          gradient: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
        ),
      WidgetThemeFamily.noirGold => const WidgetThemePalette(
          family: WidgetThemeFamily.noirGold,
          canvas: Color(0xFF07090C),
          canvasElevated: Color(0xFF12161D),
          border: Color(0xFF3A3224),
          accent: champagne,
          accentSoft: champagneSoft,
          textPrimary: ivory,
          textSecondary: champagneSoft,
          textMuted: Color(0xFF9AA3B2),
          dayNumeral: champagne,
          chipFill: Color(0x1AD4AF74),
          progressTrack: Color(0xFF2E3542),
          progressFill: champagne,
          isLight: false,
          gradient: [
            Color(0xFF1E2533),
            Color(0xFF0A0C10),
            Color(0xFF17120C),
            Color(0xFF0C1016),
          ],
        ),
      WidgetThemeFamily.emeraldHeritage => const WidgetThemePalette(
          family: WidgetThemeFamily.emeraldHeritage,
          canvas: Color(0xFF062218),
          canvasElevated: Color(0xFF0E4A35),
          border: Color(0xFF1F6B4F),
          accent: emeraldGlow,
          accentSoft: Color(0xFFB8F0D4),
          textPrimary: Colors.white,
          textSecondary: emeraldGlow,
          textMuted: Color(0xFF9AD9BC),
          dayNumeral: champagneSoft,
          chipFill: Color(0x1A7DDEB3),
          progressTrack: Color(0xFF0A2E22),
          progressFill: emerald,
          isLight: false,
          gradient: [
            Color(0xFF0E4A35),
            Color(0xFF062218),
            Color(0xFF081A14),
          ],
        ),
      WidgetThemeFamily.parchmentClassic => const WidgetThemePalette(
          family: WidgetThemeFamily.parchmentClassic,
          canvas: Color(0xFFF3E6CE),
          canvasElevated: Color(0xFFF7EDD8),
          border: Color(0xFFC4A574),
          accent: Color(0xFFA67C52),
          accentSoft: Color(0xFF8B6914),
          textPrimary: ink,
          textSecondary: Color(0xFF3D2E22),
          textMuted: Color(0xFF6B4E2E),
          dayNumeral: ink,
          chipFill: Color(0x33A67C52),
          progressTrack: Color(0xFFDCC39A),
          progressFill: Color(0xFFA67C52),
          isLight: true,
          gradient: [
            Color(0xFFF7EDD8),
            Color(0xFFE8D4AE),
            Color(0xFFD9C195),
          ],
        ),
      WidgetThemeFamily.minimalModern => const WidgetThemePalette(
          family: WidgetThemeFamily.minimalModern,
          canvas: Color(0xFF0E1116),
          canvasElevated: Color(0xFF171C24),
          border: Color(0xFF2A303A),
          accent: Color(0xFFE8E6E1),
          accentSoft: Color(0xFFC8C4BC),
          textPrimary: Color(0xFFF4F2EE),
          textSecondary: Color(0xFFD0CBC2),
          textMuted: Color(0xFF8B919C),
          dayNumeral: Color(0xFFF4F2EE),
          chipFill: Color(0x14FFFFFF),
          progressTrack: Color(0xFF2A303A),
          progressFill: Color(0xFFE8E6E1),
          isLight: false,
          gradient: [
            Color(0xFF171C24),
            Color(0xFF0E1116),
            Color(0xFF12151A),
          ],
        ),
    };
  }

  /// Android drawable resource name suffix for family backgrounds.
  static String androidBgSuffix(WidgetThemeFamily family) => switch (family) {
        WidgetThemeFamily.coralStudio => 'coral',
        WidgetThemeFamily.noirGold => 'noir',
        WidgetThemeFamily.emeraldHeritage => 'emerald',
        WidgetThemeFamily.parchmentClassic => 'parchment',
        WidgetThemeFamily.minimalModern => 'minimal',
      };
}
