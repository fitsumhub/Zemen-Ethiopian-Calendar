import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization/app_language.dart';

class UserSettings {
  final String language; // ENGLISH, AMHARIC, OROMO, TIGRINYA, FRENCH
  final String numeralType; // ARABIC, GEEZ
  final String calendarFormat; // ETHIOPIAN, GREGORIAN
  final String themeMode; // SYSTEM, LIGHT, DARK, AMOLED
  final String accentPalette; // ZEMEN_EMERALD (default), GOLD_EMERALD, CRIMSON, ROYAL_INDIGO, TERRACOTTA, LALIBELA_PURPLE
  final String firstDayOfWeek; // SUNDAY, MONDAY
  final bool showFasting;
  final bool showMonthlySaints;
  final bool showFootball;
  final bool notificationsEnabled;
  final bool onboardingCompleted;

  const UserSettings({
    this.language = 'ENGLISH',
    this.numeralType = 'ARABIC',
    this.calendarFormat = 'ETHIOPIAN',
    this.themeMode = 'LIGHT',
    this.accentPalette = 'ZEMEN_EMERALD',
    this.firstDayOfWeek = 'MONDAY',
    this.showFasting = true,
    this.showMonthlySaints = true,
    this.showFootball = false,
    this.notificationsEnabled = true,
    this.onboardingCompleted = false,
  });

  UserSettings copyWith({
    String? language,
    String? numeralType,
    String? calendarFormat,
    String? themeMode,
    String? accentPalette,
    String? firstDayOfWeek,
    bool? showFasting,
    bool? showMonthlySaints,
    bool? showFootball,
    bool? notificationsEnabled,
    bool? onboardingCompleted,
  }) {
    return UserSettings(
      language: language ?? this.language,
      numeralType: numeralType ?? this.numeralType,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      themeMode: themeMode ?? this.themeMode,
      accentPalette: accentPalette ?? this.accentPalette,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      showFasting: showFasting ?? this.showFasting,
      showMonthlySaints: showMonthlySaints ?? this.showMonthlySaints,
      showFootball: showFootball ?? this.showFootball,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }
}

class UserPreferencesRepository {
  static const String keyLanguage = 'pref_language';
  static const String keyNumeralType = 'pref_numeral_type';
  static const String keyCalendarFormat = 'pref_calendar_format';
  static const String keyTheme = 'pref_theme';
  static const String keyAccent = 'pref_accent';
  static const String keyFirstDayWeek = 'pref_first_day_week';
  static const String keyShowFasting = 'pref_show_fasting';
  static const String keyShowSaints = 'pref_show_saints';
  static const String keyShowFootball = 'pref_show_football';
  static const String keyNotifications = 'pref_notifications';
  static const String keyOnboardingCompleted = 'pref_onboarding_completed';
  static const String keyWidgetStyle = 'pref_widget_style';

  static UserPreferencesRepository? _instance;

  static UserPreferencesRepository get instance {
    final existing = _instance;
    if (existing == null) {
      throw StateError(
        'UserPreferencesRepository not initialized. Call initialize() in main().',
      );
    }
    return existing;
  }

  static Future<UserPreferencesRepository> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return _instance ??= UserPreferencesRepository(prefs);
  }

  /// Test-only: clear singleton so a new SharedPreferences mock can bind.
  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  final SharedPreferences _prefs;

  UserPreferencesRepository(this._prefs);

  UserSettings getSettings() {
    return UserSettings(
      language: AppLanguage.normalizePreference(_prefs.getString(keyLanguage)),
      numeralType: _prefs.getString(keyNumeralType) ?? 'ARABIC',
      calendarFormat: _prefs.getString(keyCalendarFormat) ?? 'ETHIOPIAN',
      themeMode: _prefs.getString(keyTheme) ?? 'LIGHT',
      accentPalette: _prefs.getString(keyAccent) ?? 'ZEMEN_EMERALD',
      firstDayOfWeek: _prefs.getString(keyFirstDayWeek) ?? 'MONDAY',
      showFasting: _prefs.getBool(keyShowFasting) ?? true,
      showMonthlySaints: _prefs.getBool(keyShowSaints) ?? true,
      showFootball: _prefs.getBool(keyShowFootball) ?? false,
      notificationsEnabled: _prefs.getBool(keyNotifications) ?? true,
      onboardingCompleted: _prefs.getBool(keyOnboardingCompleted) ?? false,
    );
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(keyOnboardingCompleted, completed);
  }

  Future<void> setLanguage(String language) async {
    await _prefs.setString(keyLanguage, AppLanguage.normalizePreference(language));
  }

  Future<void> setNumeralType(String numeralType) async {
    await _prefs.setString(keyNumeralType, numeralType);
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyTheme, mode);
  }

  Future<void> setAccentPalette(String palette) async {
    await _prefs.setString(keyAccent, palette);
  }

  Future<void> setFirstDayOfWeek(String firstDay) async {
    await _prefs.setString(keyFirstDayWeek, firstDay);
  }

  Future<void> setShowFasting(bool enabled) async {
    await _prefs.setBool(keyShowFasting, enabled);
  }

  Future<void> setShowMonthlySaints(bool enabled) async {
    await _prefs.setBool(keyShowSaints, enabled);
  }

  Future<void> setShowFootball(bool enabled) async {
    await _prefs.setBool(keyShowFootball, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(keyNotifications, enabled);
  }

  Future<void> setCalendarFormat(String format) async {
    await _prefs.setString(keyCalendarFormat, format);
  }

  int getWidgetStyle() => _prefs.getInt(keyWidgetStyle) ?? 0;

  Future<void> setWidgetStyle(int index) async {
    await _prefs.setInt(keyWidgetStyle, index);
  }
}
