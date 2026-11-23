import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiocal/core/localization/app_language.dart';
import 'package:ethiocal/core/localization/app_localizations_setup.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/features/shared/providers.dart';
import 'package:ethiocal/main.dart';

class _TestUserSettingsNotifier extends UserSettingsNotifier {
  final UserSettings _initial;
  _TestUserSettingsNotifier(this._initial);
  @override
  UserSettings build() => _initial;
}

void main() {
  test('Global* delegates from material_ui/cupertino_ui cover catalog languages', () {
    for (final lang in AppLanguage.values) {
      final isSupportedMat =
          GlobalMaterialLocalizations.delegate.isSupported(lang.locale);
      final isSupportedWid =
          GlobalWidgetsLocalizations.delegate.isSupported(lang.locale);
      final isSupportedCup =
          GlobalCupertinoLocalizations.delegate.isSupported(lang.locale);
      // om / ti rely on fallbacks; others should be first-class Global support.
      if (lang == AppLanguage.oromo || lang == AppLanguage.tigrinya) {
        expect(isSupportedMat, isFalse, reason: '${lang.name} Material');
        expect(isSupportedCup, isFalse, reason: '${lang.name} Cupertino');
      } else {
        expect(isSupportedMat, isTrue, reason: '${lang.name} Material');
        expect(isSupportedWid, isTrue, reason: '${lang.name} Widgets');
        expect(isSupportedCup, isTrue, reason: '${lang.name} Cupertino');
      }
    }
  });

  test('AppLocalizationsSetup fallbacks support every AppLanguage locale', () {
    for (final lang in AppLanguage.values) {
      final mat = AppLocalizationsSetup.delegates
          .whereType<LocalizationsDelegate<MaterialLocalizations>>()
          .any((d) => d.isSupported(lang.locale));
      final cup = AppLocalizationsSetup.delegates
          .whereType<LocalizationsDelegate<CupertinoLocalizations>>()
          .any((d) => d.isSupported(lang.locale));
      final wid = AppLocalizationsSetup.delegates
          .whereType<LocalizationsDelegate<WidgetsLocalizations>>()
          .any((d) => d.isSupported(lang.locale));
      expect(mat, isTrue, reason: '${lang.name} Material covered');
      expect(cup, isTrue, reason: '${lang.name} Cupertino covered');
      expect(wid, isTrue, reason: '${lang.name} Widgets covered');

      final legacyMat = AppLocalizationsSetup.legacyDelegates
          .any((d) => d.isSupported(lang.locale));
      expect(legacyMat, isTrue, reason: '${lang.name} legacy delegates covered');
    }
  });

  testWidgets(
    'EthioCalApp boots and opens drawer in all languages including Oromo and Tigrinya without error',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      for (final lang in AppLanguage.values) {
        UserPreferencesRepository.resetForTest();
        SharedPreferences.setMockInitialValues({
          'pref_onboarding_completed': true,
          'pref_language': lang.preferenceValue,
        });
        await UserPreferencesRepository.initialize();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              userSettingsProvider.overrideWith(
                () => _TestUserSettingsNotifier(
                  UserSettings(
                    onboardingCompleted: true,
                    language: lang.name,
                  ),
                ),
              ),
              currentAppLanguageProvider.overrideWith((ref) => lang),
            ],
            child: const EthioCalApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Boot in ${lang.name} failed',
        );

        tester.state<ScaffoldState>(find.byType(Scaffold).first).openDrawer();
        await tester.pumpAndSettle();
        expect(find.byType(Drawer), findsOneWidget, reason: 'Drawer rendered in ${lang.name}');

        expect(
          tester.takeException(),
          isNull,
          reason: 'Opening drawer in ${lang.name} failed',
        );
      }
    },
  );
}
