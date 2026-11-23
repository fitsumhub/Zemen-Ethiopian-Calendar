import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppThemePreset {
  final String id;
  final String nameAmharic;
  final String nameEnglish;
  final String subtitleAmharic;
  final String subtitleEnglish;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentGlow;
  final Color accentDeep;
  final Color previewBackground;
  final IconData icon;

  const AppThemePreset({
    required this.id,
    required this.nameAmharic,
    required this.nameEnglish,
    required this.subtitleAmharic,
    required this.subtitleEnglish,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentGlow,
    required this.accentDeep,
    required this.previewBackground,
    required this.icon,
  });
}

class AppTheme {
  /// Palette used for new installs, resets, and unknown ids: the brand colours.
  static const String defaultPaletteId = 'ZEMEN_EMERALD';

  static List<AppThemePreset> presets = [
    AppThemePreset(
      id: 'ZEMEN_EMERALD',
      nameAmharic: 'ዘመን ኤመራልድ',
      nameEnglish: 'Zemen Emerald',
      subtitleAmharic: 'የዘመን መለያ አረንጓዴና ወርቅ',
      subtitleEnglish: 'Signature emerald & gold on deep black',
      primaryColor: AppColors.brandEmerald,
      secondaryColor: AppColors.brandGold,
      accentGlow: Color(0xFF8CF0B4),
      accentDeep: AppColors.brandDeepGreen,
      previewBackground: Color(0xFF08120C),
      icon: Icons.calendar_month_rounded,
    ),
    AppThemePreset(
      id: 'GOLD_EMERALD',
      nameAmharic: 'ንጉሣዊ ወርቅ',
      nameEnglish: 'Imperial Gold',
      subtitleAmharic: 'የቀዳማዊ ወርቅና የደጋው ለምለም ኤመራልድ',
      subtitleEnglish: 'Classic royal gold & highland emerald',
      primaryColor: AppColors.ethioGoldPrimary,
      secondaryColor: AppColors.ethioEmerald,
      accentGlow: AppColors.ethioGoldLight,
      accentDeep: AppColors.ethioGoldDark,
      previewBackground: Color(0xFF14120C),
      icon: Icons.military_tech_rounded,
    ),
    AppThemePreset(
      id: 'CRIMSON',
      nameAmharic: 'አክሱም ቀይ',
      nameEnglish: 'Axum Crimson',
      subtitleAmharic: 'የጥንታዊው አክሱም ጽናትና ደማቅ ቀይ',
      subtitleEnglish: 'Historic Axumite crimson & coral radiance',
      primaryColor: AppColors.ethioCrimsonPrimary,
      secondaryColor: AppColors.govHolidayRing,
      accentGlow: AppColors.ethioCrimsonLight,
      accentDeep: AppColors.ethioCrimsonDark,
      previewBackground: Color(0xFF160D0F),
      icon: Icons.local_fire_department_rounded,
    ),
    AppThemePreset(
      id: 'ROYAL_INDIGO',
      nameAmharic: 'አቢሲኒያ ሰማያዊ',
      nameEnglish: 'Abyssinian Sapphire',
      subtitleAmharic: 'የጣና ሐይቅ ጥልቅ ሰማያዊና የሰማይ ግርማ',
      subtitleEnglish: 'Lake Tana deep sapphire & celestial blue',
      primaryColor: AppColors.ethioIndigoPrimary,
      secondaryColor: AppColors.ethioGoldPrimary,
      accentGlow: AppColors.ethioIndigoLight,
      accentDeep: AppColors.ethioIndigoDark,
      previewBackground: Color(0xFF0C121E),
      icon: Icons.water_drop_rounded,
    ),
    AppThemePreset(
      id: 'TERRACOTTA',
      nameAmharic: 'ስሜን ሸክላ',
      nameEnglish: 'Simien Terracotta',
      subtitleAmharic: 'የስሜን ተራሮች የተፈጥሮ ሸክላና ሞቃት አፈር',
      subtitleEnglish: 'Warm highland earth & Simien mountain clay',
      primaryColor: AppColors.ethioTerracottaPrimary,
      secondaryColor: AppColors.ethioEmerald,
      accentGlow: AppColors.ethioTerracottaLight,
      accentDeep: AppColors.ethioTerracottaDark,
      previewBackground: Color(0xFF18100C),
      icon: Icons.landscape_rounded,
    ),
    AppThemePreset(
      id: 'LALIBELA_PURPLE',
      nameAmharic: 'ላሊበላ ሐምራዊ',
      nameEnglish: 'Lalibela Amethyst',
      subtitleAmharic: 'የተቀረጹት አብያተ ክርስቲያናት ጥልቅ ሐምራዊ ክብር',
      subtitleEnglish: 'Mystical rock-hewn royal amethyst & rose',
      primaryColor: AppColors.ethioAmethystPrimary,
      secondaryColor: Color(0xFFF59E0B),
      accentGlow: AppColors.ethioAmethystLight,
      accentDeep: AppColors.ethioAmethystDark,
      previewBackground: Color(0xFF140D1E),
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static AppThemePreset getPreset(String paletteId) {
    for (final p in presets) {
      if (p.id == paletteId) return p;
    }
    return presets.firstWhere((p) => p.id == defaultPaletteId);
  }
  static List<String> get ethiopicFontFallbacks => [
    GoogleFonts.notoSansEthiopic().fontFamily ?? 'Noto Sans Ethiopic',
    'Noto Sans Ethiopic',
    'Abyssinica SIL',
    'Nyala',
    'Ebrima',
    'sans-serif',
  ];

  static TextTheme _textTheme(Brightness brightness) {
    final onSurface = brightness == Brightness.dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final muted = brightness == Brightness.dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final fallbacks = ethiopicFontFallbacks;

    TextStyle display(double size, FontWeight weight, {double spacing = -0.3}) =>
        GoogleFonts.outfit(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: onSurface,
          height: 1.15,
        ).copyWith(fontFamilyFallback: fallbacks);

    TextStyle ui(double size, FontWeight weight, {Color? color, double height = 1.4, double spacing = 0}) =>
        GoogleFonts.outfit(
          fontSize: size,
          fontWeight: weight,
          letterSpacing: spacing,
          color: color ?? onSurface,
          height: height,
        ).copyWith(fontFamilyFallback: fallbacks);

    return TextTheme(
      displayLarge: display(48, FontWeight.w700, spacing: -0.5),
      displayMedium: display(40, FontWeight.w700),
      displaySmall: display(32, FontWeight.w600),
      headlineLarge: display(28, FontWeight.w700, spacing: -0.4),
      headlineMedium: display(24, FontWeight.w600),
      headlineSmall: display(20, FontWeight.w600),
      titleLarge: ui(18, FontWeight.w600, spacing: -0.2),
      titleMedium: ui(16, FontWeight.w600),
      titleSmall: ui(14, FontWeight.w600),
      bodyLarge: ui(16, FontWeight.w400, height: 1.45),
      bodyMedium: ui(14, FontWeight.w400, color: muted),
      bodySmall: ui(12, FontWeight.w400, color: muted, height: 1.35),
      labelLarge: ui(13, FontWeight.w600, spacing: 0.2),
      labelMedium: ui(12, FontWeight.w600, color: muted),
      labelSmall: ui(11, FontWeight.w500, color: muted, spacing: 0.3),
    );
  }

  static ColorScheme createDarkColorScheme(String accentPalette, {bool isAmoled = false}) {
    final surface = isAmoled ? AppColors.amoledSurface : AppColors.darkSurface;

    switch (accentPalette) {
      case 'ZEMEN_EMERALD':
        return ColorScheme.dark(
          primary: AppColors.brandEmerald,
          onPrimary: Color(0xFF06140C),
          primaryContainer: AppColors.brandDeepGreen,
          onPrimaryContainer: Color(0xFFB7F5D0),
          secondary: AppColors.brandGold,
          onSecondary: Color(0xFF1A1400),
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
      case 'ROYAL_INDIGO':
        return ColorScheme.dark(
          primary: AppColors.ethioIndigoPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioIndigoDark,
          onPrimaryContainer: AppColors.ethioIndigoLight,
          secondary: AppColors.ethioGoldPrimary,
          onSecondary: Color(0xFF1A1400),
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
      case 'CRIMSON':
        return ColorScheme.dark(
          primary: AppColors.ethioCrimsonPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioCrimsonDark,
          onPrimaryContainer: AppColors.ethioCrimsonLight,
          secondary: AppColors.ethioGoldPrimary,
          onSecondary: Color(0xFF1A1400),
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
      case 'TERRACOTTA':
        return ColorScheme.dark(
          primary: AppColors.ethioTerracottaPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioTerracottaDark,
          onPrimaryContainer: AppColors.ethioTerracottaLight,
          secondary: AppColors.ethioEmerald,
          onSecondary: Color(0xFF041A12),
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
      case 'LALIBELA_PURPLE':
        return ColorScheme.dark(
          primary: AppColors.ethioAmethystPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioAmethystDark,
          onPrimaryContainer: AppColors.ethioAmethystLight,
          secondary: Color(0xFFF59E0B),
          onSecondary: Color(0xFF1A1400),
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
      default: // GOLD_EMERALD
        return ColorScheme.dark(
          primary: AppColors.ethioGoldPrimary,
          onPrimary: Color(0xFF1A1400),
          primaryContainer: Color(0xFF3D3010),
          onPrimaryContainer: AppColors.ethioGoldLight,
          secondary: AppColors.ethioEmerald,
          onSecondary: Color(0xFF041A12),
          secondaryContainer: AppColors.ethioEmeraldDark,
          onSecondaryContainer: AppColors.ethioEmeraldLight,
          surface: surface,
          onSurface: AppColors.darkTextPrimary,
          surfaceContainerHighest: AppColors.darkSurfaceElevated,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkSurfaceBorder,
          outlineVariant: AppColors.darkSurfaceBorder.withValues(alpha: 0.6),
        );
    }
  }

  static ColorScheme createLightColorScheme(String accentPalette) {
    switch (accentPalette) {
      case 'ZEMEN_EMERALD':
        return ColorScheme.light(
          primary: AppColors.brandEmeraldOnLight,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFCDEFD9),
          onPrimaryContainer: AppColors.brandDeepGreen,
          secondary: AppColors.ethioGoldDark,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
      case 'ROYAL_INDIGO':
        return ColorScheme.light(
          primary: AppColors.ethioIndigoDark,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioIndigoLight,
          onPrimaryContainer: AppColors.ethioIndigoDark,
          secondary: AppColors.ethioGoldDark,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
      case 'CRIMSON':
        return ColorScheme.light(
          primary: AppColors.ethioCrimsonPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioCrimsonLight,
          onPrimaryContainer: AppColors.ethioCrimsonDark,
          secondary: AppColors.ethioGoldDark,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
      case 'TERRACOTTA':
        return ColorScheme.light(
          primary: AppColors.ethioTerracottaPrimary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.ethioTerracottaLight,
          onPrimaryContainer: AppColors.ethioTerracottaDark,
          secondary: AppColors.ethioEmeraldDark,
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
      case 'LALIBELA_PURPLE':
        return ColorScheme.light(
          primary: Color(0xFF7C3AED),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFEDE9FE),
          onPrimaryContainer: Color(0xFF4C1D95),
          secondary: Color(0xFFD97706),
          onSecondary: Colors.white,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
      default: // GOLD_EMERALD
        return ColorScheme.light(
          primary: AppColors.ethioGoldDark,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF3E8C4),
          onPrimaryContainer: Color(0xFF3D2E08),
          secondary: AppColors.ethioEmeraldDark,
          onSecondary: Colors.white,
          secondaryContainer: AppColors.ethioEmeraldLight,
          onSecondaryContainer: Color(0xFF063D2C),
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightTextPrimary,
          surfaceContainerHighest: AppColors.lightSurfaceElevated,
          onSurfaceVariant: AppColors.lightTextSecondary,
          outline: AppColors.lightSurfaceBorder,
        );
    }
  }

  /// Updates AppColors dynamically to match the current mode and palette.
  static void updateAppColors({
    required String themeMode,
    required String accentPalette,
    required Brightness systemBrightness,
  }) {
    final bool isDark = themeMode == 'SYSTEM'
        ? systemBrightness == Brightness.dark
        : themeMode != 'LIGHT';
    final bool isAmoled = themeMode == 'AMOLED';

    final preset = getPreset(accentPalette);

    if (!isDark) {
      // Light Mode dynamic tokens (high legibility, contrast-tuned accents)
      final Color lightAccent;
      final Color lightAccentSoft;
      final Color lightAccentDeep;

      switch (accentPalette) {
        case 'ZEMEN_EMERALD':
          lightAccent = AppColors.brandEmeraldOnLight;
          lightAccentSoft = const Color(0xFFD3F3DE);
          lightAccentDeep = AppColors.brandDeepGreen;
          break;
        case 'GOLD_EMERALD':
          lightAccent = const Color(0xFF9E7714);
          lightAccentSoft = const Color(0xFFF6E8BF);
          lightAccentDeep = const Color(0xFF755507);
          break;
        case 'ROYAL_INDIGO':
          lightAccent = const Color(0xFF1C52A4);
          lightAccentSoft = const Color(0xFFD6E4FA);
          lightAccentDeep = const Color(0xFF12366E);
          break;
        case 'TERRACOTTA':
          lightAccent = const Color(0xFFB5471B);
          lightAccentSoft = const Color(0xFFF9DDD1);
          lightAccentDeep = const Color(0xFF822F0D);
          break;
        case 'LALIBELA_PURPLE':
          lightAccent = Color(0xFF7C3AED);
          lightAccentSoft = Color(0xFFEDE9FE);
          lightAccentDeep = Color(0xFF581C87);
          break;
        case 'CRIMSON':
        default:
          lightAccent = Color(0xFFB91C1C);
          lightAccentSoft = Color(0xFFFEE2E2);
          lightAccentDeep = Color(0xFF7F1D1D);
          break;
      }

      AppColors.setDynamicTheme(
        isDark: false,
        isAmoled: false,
        canvas: const Color(0xFFF5F7FA),
        surface: Color(0xFFFFFFFF),
        surfaceElevated: Color(0xFFEBF0F5),
        surfaceBorder: Color(0xFFD3DAE3),
        textPrimary: Color(0xFF111827),
        textSecondary: Color(0xFF4B5565),
        textTertiary: Color(0xFF8B95A5),
        accent: lightAccent,
        accentSoft: lightAccentSoft,
        accentDeep: lightAccentDeep,
        activeMode: themeMode,
        activePalette: accentPalette,
      );
    } else if (isAmoled) {
      // AMOLED Pure Black dynamic tokens
      AppColors.setDynamicTheme(
        isDark: true,
        isAmoled: true,
        canvas: const Color(0xFF000000),
        surface: Color(0xFF070709),
        surfaceElevated: Color(0xFF121216),
        surfaceBorder: Color(0xFF22222A),
        textPrimary: Color(0xFFFFFFFF),
        textSecondary: Color(0xFFA5B0BF),
        textTertiary: Color(0xFF6F7988),
        accent: preset.primaryColor,
        accentSoft: preset.accentGlow,
        accentDeep: preset.accentDeep,
        activeMode: themeMode,
        activePalette: accentPalette,
      );
    } else {
      // Standard Slate Dark dynamic tokens
      AppColors.setDynamicTheme(
        isDark: true,
        isAmoled: false,
        canvas: const Color(0xFF0C0E12),
        surface: const Color(0xFF15181F),
        surfaceElevated: const Color(0xFF1A1D26),
        surfaceBorder: const Color(0xFF262B36),
        textPrimary: const Color(0xFFF5F5F7),
        textSecondary: const Color(0xFF8B93A3),
        textTertiary: const Color(0xFF6B7385),
        accent: preset.primaryColor,
        accentSoft: preset.accentGlow,
        accentDeep: preset.accentDeep,
        activeMode: themeMode,
        activePalette: accentPalette,
      );
    }
  }

  static ThemeData getTheme({
    required String themeMode,
    required String accentPalette,
    required Brightness systemBrightness,
  }) {
    updateAppColors(
      themeMode: themeMode,
      accentPalette: accentPalette,
      systemBrightness: systemBrightness,
    );

    final bool isDark = themeMode == 'SYSTEM'
        ? systemBrightness == Brightness.dark
        : themeMode != 'LIGHT';
    final bool isAmoled = themeMode == 'AMOLED';

    final colorScheme = isDark
        ? createDarkColorScheme(accentPalette, isAmoled: isAmoled)
        : createLightColorScheme(accentPalette);

    final scaffoldBg = isDark
        ? (isAmoled ? AppColors.amoledBackground : Color(0xFF0C0E12))
        : const Color(0xFFF5F7FA);

    final textTheme = _textTheme(isDark ? Brightness.dark : Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.outfit().fontFamily,
      fontFamilyFallback: ethiopicFontFallbacks,
      scaffoldBackgroundColor: scaffoldBg,
      dividerColor: colorScheme.outline.withValues(alpha: 0.35),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg.withValues(alpha: 0.92),
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.7)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightTextPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.96),
        elevation: 0,
        height: 68,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.85),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 22);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: GoogleFonts.outfit().fontFamily,
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            letterSpacing: 0.1,
          );
        }),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(textTheme.labelSmall),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
