import 'package:cupertino_ui/cupertino_ui.dart' as modern_cupertino;
import 'package:flutter/cupertino.dart' as legacy_cupertino;
import 'package:flutter/material.dart' as legacy_material;
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart' as flutter_loc;
import 'package:material_ui/material_ui.dart' as modern_material;

/// Fallback Material localizations delegate for locales not included in
/// [GlobalMaterialLocalizations] (such as Oromo `om` and Tigrinya `ti`)
/// for modern `material_ui` widgets.
class FallbackMaterialLocalizationsDelegate
    extends LocalizationsDelegate<modern_material.MaterialLocalizations> {
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<modern_material.MaterialLocalizations> load(Locale locale) =>
      modern_material.DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Fallback Widgets localizations delegate for unsupported locales.
class FallbackWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const FallbackWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      DefaultWidgetsLocalizations.load(locale);

  @override
  bool shouldReload(FallbackWidgetsLocalizationsDelegate old) => false;
}

/// Fallback Cupertino localizations for unsupported locales (`om`, `ti`)
/// for modern `cupertino_ui` widgets.
class FallbackCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<modern_cupertino.CupertinoLocalizations> {
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<modern_cupertino.CupertinoLocalizations> load(Locale locale) =>
      modern_cupertino.DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}

/// Fallback legacy Material localizations delegate for Flutter SDK's
/// `package:flutter/material.dart` (used by MaterialUiCompatibilityBridge and plugins).
class FallbackLegacyMaterialLocalizationsDelegate
    extends LocalizationsDelegate<legacy_material.MaterialLocalizations> {
  const FallbackLegacyMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<legacy_material.MaterialLocalizations> load(Locale locale) =>
      legacy_material.DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(FallbackLegacyMaterialLocalizationsDelegate old) => false;
}

/// Fallback legacy Cupertino localizations delegate for Flutter SDK's
/// `package:flutter/cupertino.dart` (used by MaterialUiCompatibilityBridge and plugins).
class FallbackLegacyCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<legacy_cupertino.CupertinoLocalizations> {
  const FallbackLegacyCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<legacy_cupertino.CupertinoLocalizations> load(Locale locale) =>
      legacy_cupertino.DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackLegacyCupertinoLocalizationsDelegate old) => false;
}

/// Central configuration for all localization delegates in Zemen.
abstract final class AppLocalizationsSetup {
  /// Delegates provided to legacy widgets / bridge (`MaterialUiCompatibilityBridge`).
  static const List<LocalizationsDelegate<dynamic>> legacyDelegates = [
    flutter_loc.GlobalMaterialLocalizations.delegate,
    flutter_loc.GlobalWidgetsLocalizations.delegate,
    flutter_loc.GlobalCupertinoLocalizations.delegate,
    FallbackLegacyMaterialLocalizationsDelegate(),
    FallbackLegacyCupertinoLocalizationsDelegate(),
  ];

  /// Full delegates provided to `MaterialApp` at the app root, ensuring both
  /// modern `material_ui` and legacy `flutter/material.dart` scopes are fully satisfied.
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    // Modern delegates (material_ui & cupertino_ui)
    modern_material.GlobalMaterialLocalizations.delegate,
    flutter_loc.GlobalWidgetsLocalizations.delegate,
    modern_cupertino.GlobalCupertinoLocalizations.delegate,
    FallbackMaterialLocalizationsDelegate(),
    FallbackWidgetsLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),

    // Legacy delegates (flutter/material.dart & flutter/cupertino.dart)
    flutter_loc.GlobalMaterialLocalizations.delegate,
    flutter_loc.GlobalCupertinoLocalizations.delegate,
    FallbackLegacyMaterialLocalizationsDelegate(),
    FallbackLegacyCupertinoLocalizationsDelegate(),
  ];

  static Locale? resolveLocale(Locale? locale, Iterable<Locale> supportedLocales) {
    if (locale == null) return const Locale('en');
    for (final supported in supportedLocales) {
      if (supported.languageCode == locale.languageCode) {
        return supported;
      }
    }
    return const Locale('en');
  }
}
