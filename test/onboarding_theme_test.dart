import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiocal/core/theme/app_colors.dart';
import 'package:ethiocal/core/theme/app_theme.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/onboarding/onboarding_screen.dart';
import 'package:ethiocal/features/settings/settings_screen.dart';
import 'package:ethiocal/features/shared/providers.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': false,
      'pref_accent': 'CRIMSON',
      'pref_theme': 'DARK',
      'pref_language': 'AMHARIC',
    });
    UserPreferencesRepository.resetForTest();
    await UserPreferencesRepository.initialize();
  });

  group('Dynamic 5 Themes - Unit Tests', () {
    test('Default theme is LIGHT and typography has Ethiopic fallback chain', () {
      const defaultSettings = UserSettings();
      expect(defaultSettings.themeMode, 'LIGHT');
      expect(AppColors.isDark, isFalse);
      expect(AppTheme.ethiopicFontFallbacks.contains('Noto Sans Ethiopic'), isTrue);
    });

    test('AppTheme.presets contains brand emerald plus 5 heritage themes', () {
      expect(AppTheme.presets.length, 6);

      final expectedIds = [
        'ZEMEN_EMERALD',
        'GOLD_EMERALD',
        'CRIMSON',
        'ROYAL_INDIGO',
        'TERRACOTTA',
        'LALIBELA_PURPLE',
      ];

      final actualIds = AppTheme.presets.map((p) => p.id).toList();
      expect(actualIds, expectedIds);

      // Verify each theme has distinct primary color, names, and cultural tags
      final primaryColors = AppTheme.presets.map((p) => p.primaryColor.toARGB32()).toSet();
      expect(primaryColors.length, 6, reason: 'All themes must have unique primary colors');

      for (final preset in AppTheme.presets) {
        expect(preset.nameAmharic.isNotEmpty, isTrue);
        expect(preset.nameEnglish.isNotEmpty, isTrue);
        expect(preset.subtitleAmharic.isNotEmpty, isTrue);
        expect(preset.subtitleEnglish.isNotEmpty, isTrue);
        expect(preset.accentGlow, isNotNull);
        expect(preset.accentDeep, isNotNull);
        expect(preset.icon, isNotNull);
      }
    });

    test('AppTheme.getPreset retrieves matching preset and handles fallback', () {
      final gold = AppTheme.getPreset('GOLD_EMERALD');
      expect(gold.nameEnglish, 'Imperial Gold');
      expect(gold.primaryColor, AppColors.ethioGoldPrimary);

      final crimson = AppTheme.getPreset('CRIMSON');
      expect(crimson.nameEnglish, 'Axum Crimson');

      final indigo = AppTheme.getPreset('ROYAL_INDIGO');
      expect(indigo.nameEnglish, 'Abyssinian Sapphire');
      expect(indigo.primaryColor, AppColors.ethioIndigoPrimary);

      final terracotta = AppTheme.getPreset('TERRACOTTA');
      expect(terracotta.nameEnglish, 'Simien Terracotta');
      expect(terracotta.primaryColor, AppColors.ethioTerracottaPrimary);

      final amethyst = AppTheme.getPreset('LALIBELA_PURPLE');
      expect(amethyst.nameEnglish, 'Lalibela Amethyst');
      expect(amethyst.primaryColor, AppColors.ethioAmethystPrimary);

      final zemen = AppTheme.getPreset('ZEMEN_EMERALD');
      expect(zemen.nameEnglish, 'Zemen Emerald');
      expect(zemen.primaryColor, AppColors.brandEmerald);

      // Fallback for unknown id → brand default
      final fallback = AppTheme.getPreset('UNKNOWN_PALETTE');
      expect(fallback.id, AppTheme.defaultPaletteId);
    });

    test('Dark and light ColorSchemes support all dynamic themes', () {
      for (final preset in AppTheme.presets) {
        final darkScheme = AppTheme.createDarkColorScheme(preset.id);
        expect(darkScheme.brightness, Brightness.dark);
        expect(darkScheme.primary, isNotNull);

        final lightScheme = AppTheme.createLightColorScheme(preset.id);
        expect(lightScheme.brightness, Brightness.light);
        expect(lightScheme.primary, isNotNull);
      }

      // Verify Lalibela Amethyst scheme
      final darkAmethyst = AppTheme.createDarkColorScheme('LALIBELA_PURPLE');
      expect(darkAmethyst.primary, AppColors.ethioAmethystPrimary);

      final lightAmethyst = AppTheme.createLightColorScheme('LALIBELA_PURPLE');
      expect(lightAmethyst.primary, const Color(0xFF7C3AED));
    });
  });

  group('Onboarding Dynamic Theme Picker - Widget Tests', () {
    Widget buildOnboardingApp({VoidCallback? onFinish}) {
      return ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(userSettingsProvider);
            return MaterialApp(
              theme: AppTheme.getTheme(
                themeMode: settings.themeMode,
                accentPalette: settings.accentPalette,
                systemBrightness: Brightness.dark,
              ),
              home: OnboardingScreen(
                onFinish: onFinish ?? () {},
              ),
            );
          },
        ),
      );
    }

    testWidgets('Onboarding screen displays 5 themes first on Page 0', (tester) async {
      await tester.pumpWidget(buildOnboardingApp());
      await tester.pumpAndSettle();

      // Heading and live date preview are displayed on screen
      expect(find.text('የገጽታ ቀለምዎን ይምረጡ'), findsOneWidget);
      expect(find.text('Choose Your Dynamic Theme'), findsOneWidget);
      expect(find.text('ዛሬ · TODAY'), findsOneWidget);

      // All 5 themes are rendered as interactive cards
      expect(find.textContaining('ንጉሣዊ ወርቅ'), findsOneWidget);
      expect(find.textContaining('አክሱም ቀይ'), findsOneWidget);
      expect(find.textContaining('አቢሲኒያ ሰማያዊ'), findsOneWidget);
      expect(find.textContaining('ስሜን ሸክላ'), findsOneWidget);
      expect(find.textContaining('ላሊበላ ሐምራዊ'), findsOneWidget);
    });

    testWidgets('Tapping a theme card dynamically updates user settings and preview', (tester) async {
      late WidgetRef savedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              savedRef = ref;
              final settings = ref.watch(userSettingsProvider);
              return MaterialApp(
                theme: AppTheme.getTheme(
                  themeMode: settings.themeMode,
                  accentPalette: settings.accentPalette,
                  systemBrightness: Brightness.dark,
                ),
                home: OnboardingScreen(onFinish: () {}),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial theme is CRIMSON
      expect(savedRef.read(userSettingsProvider).accentPalette, 'CRIMSON');

      // Tap Lalibela Amethyst
      final amethystCard = find.textContaining('ላሊበላ ሐምራዊ');
      expect(amethystCard, findsOneWidget);
      await tester.ensureVisible(amethystCard);
      await tester.pumpAndSettle();
      await tester.tap(amethystCard);
      await tester.pumpAndSettle();

      // State immediately updated to LALIBELA_PURPLE
      expect(savedRef.read(userSettingsProvider).accentPalette, 'LALIBELA_PURPLE');
      expect(find.text('Lalibela Amethyst'), findsWidgets);

      // Tap Imperial Gold
      final goldCard = find.textContaining('ንጉሣዊ ወርቅ');
      await tester.ensureVisible(goldCard);
      await tester.pumpAndSettle();
      await tester.tap(goldCard);
      await tester.pumpAndSettle();

      // State immediately updated to GOLD_EMERALD
      expect(savedRef.read(userSettingsProvider).accentPalette, 'GOLD_EMERALD');
      expect(find.text('Imperial Gold'), findsWidgets);

      // Tap Abyssinian Sapphire
      final sapphireCard = find.textContaining('አቢሲኒያ ሰማያዊ');
      await tester.ensureVisible(sapphireCard);
      await tester.pumpAndSettle();
      await tester.tap(sapphireCard);
      await tester.pumpAndSettle();

      // State immediately updated to ROYAL_INDIGO
      expect(savedRef.read(userSettingsProvider).accentPalette, 'ROYAL_INDIGO');
      expect(find.text('Abyssinian Sapphire'), findsWidgets);
    });

    testWidgets('Can navigate through onboarding to completion', (tester) async {
      bool finished = false;
      await tester.pumpWidget(buildOnboardingApp(onFinish: () => finished = true));
      await tester.pumpAndSettle();

      // Page 0: Theme Selection -> Continue
      expect(find.text('ቀጣይ  ·  Continue'), findsOneWidget);
      await tester.tap(find.text('ቀጣይ  ·  Continue'));
      await tester.pumpAndSettle();

      // Page 1: Features -> Continue
      expect(find.text('የሚያስፈልግዎ ሁሉ'), findsOneWidget);
      await tester.tap(find.text('ቀጣይ  ·  Continue'));
      await tester.pumpAndSettle();

      // Page 2: Personalize (has language, numerals, and active theme chips) -> Continue
      expect(find.text('የእርስዎ ምርጫ'), findsOneWidget);
      expect(find.text('Active Theme'), findsOneWidget);
      await tester.tap(find.text('ቀጣይ  ·  Continue'));
      await tester.pumpAndSettle();

      // Page 3: Preferences -> Get Started
      expect(find.text('ሊጨርሱ ነው'), findsOneWidget);
      expect(find.text('ጀምር  ·  Get started'), findsOneWidget);
      await tester.tap(find.text('ጀምር  ·  Get started'));
      await tester.pumpAndSettle();

      expect(finished, isTrue);
    });
  });

  group('SettingsScreen - 5 Themes & Layout', () {
    testWidgets('Settings screen renders on compact mobile (360x640) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360 * 2.5, 640 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gold = find.text('Imperial Gold');
      await tester.scrollUntilVisible(gold, 120);
      expect(gold, findsOneWidget);
      expect(find.text('Axum Crimson'), findsOneWidget);
    });
  });

  group('Full Dynamic Theme Mode System - Verification', () {
    test('AppColors dynamically transitions between Light, Dark, and AMOLED modes', () {
      // 1. Light Mode
      AppTheme.updateAppColors(
        themeMode: 'LIGHT',
        accentPalette: 'CRIMSON',
        systemBrightness: Brightness.light,
      );
      expect(AppColors.isDark, isFalse);
      expect(AppColors.isAmoled, isFalse);
      expect(AppColors.canvas, const Color(0xFFF5F7FA));
      expect(AppColors.surface, const Color(0xFFFFFFFF));
      expect(AppColors.textPrimary, const Color(0xFF111827));
      expect(AppColors.accent, const Color(0xFFB91C1C));

      // 2. AMOLED Mode
      AppTheme.updateAppColors(
        themeMode: 'AMOLED',
        accentPalette: 'CRIMSON',
        systemBrightness: Brightness.dark,
      );
      expect(AppColors.isDark, isTrue);
      expect(AppColors.isAmoled, isTrue);
      expect(AppColors.canvas, const Color(0xFF000000));
      expect(AppColors.surface, const Color(0xFF070709));
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));

      // 3. Dark Mode
      AppTheme.updateAppColors(
        themeMode: 'DARK',
        accentPalette: 'GOLD_EMERALD',
        systemBrightness: Brightness.dark,
      );
      expect(AppColors.isDark, isTrue);
      expect(AppColors.isAmoled, isFalse);
      expect(AppColors.canvas, const Color(0xFF0C0E12));
      expect(AppColors.surface, const Color(0xFF15181F));
      expect(AppColors.accent, AppColors.ethioGoldPrimary);

      // 4. Auto / System Mode (follows system brightness)
      AppTheme.updateAppColors(
        themeMode: 'SYSTEM',
        accentPalette: 'ROYAL_INDIGO',
        systemBrightness: Brightness.light,
      );
      expect(AppColors.isDark, isFalse);
      expect(AppColors.accent, const Color(0xFF1C52A4));

      AppTheme.updateAppColors(
        themeMode: 'SYSTEM',
        accentPalette: 'ROYAL_INDIGO',
        systemBrightness: Brightness.dark,
      );
      expect(AppColors.isDark, isTrue);
      expect(AppColors.accent, AppColors.ethioIndigoPrimary);
    });

    testWidgets('Tapping Theme Mode buttons dynamically changes app theme mode', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.5, 900 * 2.5);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WidgetRef savedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              savedRef = ref;
              final settings = ref.watch(userSettingsProvider);
              return MaterialApp(
                theme: AppTheme.getTheme(
                  themeMode: 'LIGHT',
                  accentPalette: settings.accentPalette,
                  systemBrightness: Brightness.light,
                ),
                darkTheme: AppTheme.getTheme(
                  themeMode: settings.themeMode == 'AMOLED' ? 'AMOLED' : 'DARK',
                  accentPalette: settings.accentPalette,
                  systemBrightness: Brightness.dark,
                ),
                themeMode: settings.themeMode == 'LIGHT'
                    ? ThemeMode.light
                    : (settings.themeMode == 'SYSTEM' ? ThemeMode.system : ThemeMode.dark),
                builder: (context, child) {
                  final actual = Theme.of(context).brightness;
                  AppTheme.updateAppColors(
                    themeMode: settings.themeMode,
                    accentPalette: settings.accentPalette,
                    systemBrightness: actual,
                  );
                  return child!;
                },
                home: const SettingsScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Light button ('ብርሃን') in Theme mode choice row
      final lightBtn = find.text('ብርሃን');
      expect(lightBtn, findsOneWidget);
      await tester.tap(lightBtn);
      await tester.pumpAndSettle();

      expect(savedRef.read(userSettingsProvider).themeMode, 'LIGHT');
      expect(AppColors.isDark, isFalse);
      expect(AppColors.canvas, const Color(0xFFF5F7FA));

      // Tap 'AMOLED' button
      final amoledBtn = find.text('AMOLED');
      await tester.tap(amoledBtn);
      await tester.pumpAndSettle();

      expect(savedRef.read(userSettingsProvider).themeMode, 'AMOLED');
      expect(AppColors.isDark, isTrue);
      expect(AppColors.isAmoled, isTrue);
      expect(AppColors.canvas, const Color(0xFF000000));

      // Tap Dark button ('ጨለማ')
      final darkBtn = find.text('ጨለማ');
      await tester.tap(darkBtn);
      await tester.pumpAndSettle();

      expect(savedRef.read(userSettingsProvider).themeMode, 'DARK');
      expect(AppColors.isDark, isTrue);
      expect(AppColors.isAmoled, isFalse);
      expect(AppColors.canvas, const Color(0xFF0C0E12));
      expect(AppColors.canvas, const Color(0xFF0C0E12));
    });
  });
}
