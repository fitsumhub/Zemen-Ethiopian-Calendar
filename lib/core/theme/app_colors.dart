import 'package:material_ui/material_ui.dart';

/// Zemen: Ethiopian Calendar — dynamic design tokens supporting 5 Ethiopian heritage
/// palettes across Light, Dark, AMOLED, and Auto/System modes.
class AppColors {
  // —— Active Dynamic Theme State ——
  static Color _canvas = const Color(0xFFF5F7FA);
  static Color _surface = const Color(0xFFFFFFFF);
  static Color _surfaceElevated = const Color(0xFFEBF0F5);
  static Color _surfaceBorder = const Color(0xFFD3DAE3);
  static Color _textPrimary = const Color(0xFF111827);
  static Color _textSecondary = const Color(0xFF4B5565);
  static Color _textTertiary = const Color(0xFF8B95A5);
  static Color _accent = const Color(0xFF0F8A54);
  static Color _accentSoft = const Color(0xFFE0F4EA);
  static Color _accentDeep = const Color(0xFF063D27);
  static bool _isDark = false;
  static bool _isAmoled = false;
  static String _activePalette = 'ZEMEN_EMERALD';
  static String _activeMode = 'LIGHT';

  // —— Canonical dynamic getters (used across the entire app) ——
  static Color get canvas => _canvas;
  static Color get surface => _surface;
  static Color get surfaceElevated => _surfaceElevated;
  static Color get surfaceBorder => _surfaceBorder;
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get textTertiary => _textTertiary;
  static Color get accent => _accent;
  static Color get accentSoft => _accentSoft;
  static Color get accentDeep => _accentDeep;

  /// Text / icon colour that stays readable on a solid [accent] fill.
  /// Bright accents (emerald, gold) need dark ink; deep ones need white.
  static Color get onAccent =>
      ThemeData.estimateBrightnessForColor(_accent) == Brightness.dark
          ? Colors.white
          : const Color(0xFF06140C);

  /// Gold that stays legible as text: bright on dark surfaces, deep on light.
  static Color get goldText => _isDark ? ethioGoldLight : ethioGoldDark;

  /// Emerald that stays legible as text on the current surface.
  static Color get emeraldText => _isDark ? ethioEmeraldLight : ethioEmeraldDark;
  static bool get isDark => _isDark;
  static bool get isAmoled => _isAmoled;
  static String get activePalette => _activePalette;
  static String get activeMode => _activeMode;

  // Dark aliases → dynamic tokens for backward compatibility
  static Color get darkBg => _canvas;
  static Color get darkCard => _surface;
  static Color get darkCardElevated => _surfaceElevated;
  static Color get darkBorder => _surfaceBorder;
  static Color get darkTextHigh => _textPrimary;
  static Color get darkTextMed => _textSecondary;
  static Color get darkTextLow => _textTertiary;

  /// Updates the active dynamic palette tokens across the whole app.
  static void setDynamicTheme({
    required bool isDark,
    required bool isAmoled,
    required Color canvas,
    required Color surface,
    required Color surfaceElevated,
    required Color surfaceBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color accent,
    required Color accentSoft,
    required Color accentDeep,
    String activeMode = 'LIGHT',
    String activePalette = 'ZEMEN_EMERALD',
  }) {
    _isDark = isDark;
    _isAmoled = isAmoled;
    _canvas = canvas;
    _surface = surface;
    _surfaceElevated = surfaceElevated;
    _surfaceBorder = surfaceBorder;
    _textPrimary = textPrimary;
    _textSecondary = textSecondary;
    _textTertiary = textTertiary;
    _accent = accent;
    _accentSoft = accentSoft;
    _accentDeep = accentDeep;
    _activeMode = activeMode;
    _activePalette = activePalette;
  }

  // Flag heritage (refined, not neon)
  static const Color ethioGreen = Color(0xFF0D6B4C);
  static const Color ethioYellow = Color(0xFFC9A227);
  static const Color ethioRed = Color(0xFFB42318);

  /// High-contrast flag gold for Ethiopian government / public holiday dates.
  static const Color govHolidayRing = Color(0xFFFACC15);
  static const Color govHolidayFill = Color(0xFFEAB308);
  static const Color govHolidayGlow = Color(0xFFFDE047);

  // Brass gold (primary identity)
  static const Color ethioGoldPrimary = Color(0xFFC9A227);
  static const Color ethioGoldDark = Color(0xFF8B6914);
  static const Color ethioGoldLight = Color(0xFFE8D48B);
  static const Color ethioGoldMuted = Color(0xFFB8952F);

  // Highland emerald
  static const Color ethioEmerald = Color(0xFF1FA87A);
  static const Color ethioEmeraldDark = Color(0xFF0D6B4C);
  static const Color ethioEmeraldLight = Color(0xFFB7EBD6);

  // Deep sapphire (ROYAL_INDIGO key — navy, not purple)
  static const Color ethioIndigoPrimary = Color(0xFF2F6FED);
  static const Color ethioIndigoDark = Color(0xFF1B4B7A);
  static const Color ethioIndigoLight = Color(0xFFC5D7F5);

  // Zemen brand: emerald + gold on deep black
  static const Color brandEmerald = Color(0xFF00C853);
  static const Color brandEmeraldOnLight = Color(0xFF007F39);
  static const Color brandGold = Color(0xFFFFD700);
  static const Color brandDeepGreen = Color(0xFF063D27);

  // Axum crimson
  static const Color ethioCrimsonPrimary = Color(0xFFC4332B);
  static const Color ethioCrimsonDark = Color(0xFF8F1F1A);
  static const Color ethioCrimsonLight = Color(0xFFF3C5C2);

  // Simien clay
  static const Color ethioTerracottaPrimary = Color(0xFFC45C26);
  static const Color ethioTerracottaDark = Color(0xFF8E3D14);
  static const Color ethioTerracottaLight = Color(0xFFF2D2BF);

  // Lalibela Amethyst
  static const Color ethioAmethystPrimary = Color(0xFF9D4EDD);
  static const Color ethioAmethystDark = Color(0xFF581C87);
  static const Color ethioAmethystLight = Color(0xFFE9D5FF);

  // Dark — ink slate
  static const Color darkBackground = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF121821);
  static const Color darkSurfaceElevated = Color(0xFF1A2230);
  static const Color darkSurfaceBorder = Color(0xFF2A3548);
  static const Color darkTextPrimary = Color(0xFFF4F6F8);
  static const Color darkTextSecondary = Color(0xFF9AA6B5);
  static const Color darkTextTertiary = Color(0xFF6B7788);

  // AMOLED
  static const Color amoledBackground = Color(0xFF000000);
  static const Color amoledSurface = Color(0xFF080808);

  // Light — cool stone (not warm cream)
  static const Color lightBackground = Color(0xFFF2F4F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFE8ECF1);
  static const Color lightSurfaceBorder = Color(0xFFD5DCE5);
  static const Color lightTextPrimary = Color(0xFF12171F);
  static const Color lightTextSecondary = Color(0xFF4A5565);
  static const Color lightTextTertiary = Color(0xFF8793A3);

  // Atmosphere gradients
  static const Color atmosphereDarkTop = Color(0xFF101820);
  static const Color atmosphereDarkBottom = Color(0xFF0A0E14);
  static const Color atmosphereLightTop = Color(0xFFE9EEF4);
  static const Color atmosphereLightBottom = Color(0xFFF2F4F7);

  // —— Calendar data provenance theme (never mix approximate into verified UI) ——
  static Color verifyVerified = Color(0xFF1FA87A);
  static Color verifyCrossChecked = Color(0xFF2F6FED);
  static Color verifyCalculated = Color(0xFFC9A227);
  static Color verifyApproximate = Color(0xFFC45C26);
  static Color verifyExcluded = Color(0xFF6B7385);
}

/// Semantic colors for calendar dataset / event verification badges.
class CalendarDataTheme {
  static Color colorFor(String verification) {
    switch (verification) {
      case 'verified':
        return AppColors.verifyVerified;
      case 'cross_checked':
        return AppColors.verifyCrossChecked;
      case 'calculated_bahire_hasab':
      case 'calculated_from_fixed_rule':
      case 'calculated_hijri_to_ethiopian':
        return AppColors.verifyCalculated;
      case 'approximate':
      case 'approximate_rule':
      case 'approximate_calculated':
        return AppColors.verifyApproximate;
      case 'excluded_from_offline_core':
      case 'reviewed_not_copied':
        return AppColors.verifyExcluded;
      default:
        return AppColors.textSecondary;
    }
  }

  static String labelFor(String verification) {
    switch (verification) {
      case 'verified':
        return 'Verified';
      case 'cross_checked':
        return 'Cross-checked';
      case 'approximate_calculated':
        return 'Approximate (calculated)';
      case 'approximate_rule':
        return 'Approximate rule';
      case 'approximate':
        return 'Approximate';
      case 'excluded_from_offline_core':
        return 'Excluded (API)';
      case 'reviewed_not_copied':
        return 'Reviewed only';
      default:
        return verification.replaceAll('_', ' ');
    }
  }
}
