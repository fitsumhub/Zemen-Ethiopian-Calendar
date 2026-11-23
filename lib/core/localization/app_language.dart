import 'package:flutter/widgets.dart';

enum AppLanguage {
  amharic('am', 'Amharic', 'አማርኛ'),
  english('en', 'English', 'English'),
  oromo('om', 'Afaan Oromoo', 'Afaan Oromoo'),
  tigrinya('ti', 'Tigrinya', 'ትግርኛ'),
  french('fr', 'French', 'Français');

  final String code;
  final String displayName;
  final String nativeName;

  const AppLanguage(this.code, this.displayName, this.nativeName);

  Locale get locale => Locale(code);

  /// Preference key stored in SharedPreferences / Settings.
  String get preferenceValue => switch (this) {
        AppLanguage.amharic => 'AMHARIC',
        AppLanguage.oromo => 'OROMO',
        AppLanguage.tigrinya => 'TIGRINYA',
        AppLanguage.french => 'FRENCH',
        AppLanguage.english => 'ENGLISH',
      };

  /// Short chip label for Settings (script-aware).
  String get shortLabel => switch (this) {
        AppLanguage.amharic => 'አማ',
        AppLanguage.oromo => 'OM',
        AppLanguage.tigrinya => 'ትግ',
        AppLanguage.french => 'FR',
        AppLanguage.english => 'EN',
      };

  static AppLanguage fromString(String? value) {
    if (value == null) return AppLanguage.english;
    switch (value.toUpperCase()) {
      case 'AMHARIC':
      case 'AM':
        return AppLanguage.amharic;
      case 'OROMO':
      case 'OM':
        return AppLanguage.oromo;
      case 'TIGRINYA':
      case 'TI':
        return AppLanguage.tigrinya;
      case 'FRENCH':
      case 'FR':
        return AppLanguage.french;
      case 'ENGLISH':
      case 'EN':
      default:
        return AppLanguage.english;
    }
  }

  /// Canonical preference values used by Settings dropdowns / SharedPreferences.
  static const List<String> preferenceValues = [
    'AMHARIC',
    'ENGLISH',
    'OROMO',
    'TIGRINYA',
    'FRENCH',
  ];

  /// Ordered catalog for pickers: preference, native, English.
  static List<(String preference, String native, String english)> get catalog =>
      AppLanguage.values
          .map((l) => (l.preferenceValue, l.nativeName, l.displayName))
          .toList(growable: false);

  /// Normalize legacy short codes (`EN`, `AM`, …) to preference values.
  static String normalizePreference(String? value) =>
      fromString(value).preferenceValue;
}
