import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_language.dart';
import 'home_widget_engine.dart';
import 'widget_theme.dart';

/// Persists live widget payload and talks to the Android AppWidget host.
class HomeWidgetSync {
  HomeWidgetSync._();

  static const _channel = MethodChannel('com.ethiocal/home_widget');

  static const keyShowFasting = 'pref_widget_show_fasting';
  static const keyShowGeez = 'pref_widget_show_geez';
  static const keyShowSaint = 'pref_widget_show_saint';
  static const keySize = 'pref_widget_size';
  static const keyThemeFamily = 'pref_widget_theme_family';
  static const keyThemeAuto = 'pref_widget_theme_auto';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<HomeWidgetSnapshot> sync({
    required int styleIndex,
    AppLanguage lang = AppLanguage.amharic,
    bool? showFasting,
    bool? showGeez,
    bool? showSaint,
    String? size,
    WidgetThemeFamily? themeFamily,
    bool? themeAuto,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final fasting = showFasting ?? prefs.getBool(keyShowFasting) ?? true;
    final geez = showGeez ?? prefs.getBool(keyShowGeez) ?? true;
    final saint = showSaint ?? prefs.getBool(keyShowSaint) ?? true;
    final widgetSize = size ?? prefs.getString(keySize) ?? 'compact';
    final auto = themeAuto ?? prefs.getBool(keyThemeAuto) ?? true;

    final kind = HomeWidgetKindX.fromIndex(styleIndex);
    final resolvedFamily = auto
        ? WidgetTheme.familyForKind(kind)
        : (themeFamily ??
            WidgetThemeFamilyX.fromId(prefs.getString(keyThemeFamily)));

    final snapshot = HomeWidgetEngine.build(kind, lang: lang);
    final firstDay = prefs.getString('pref_first_day_week') ?? 'MONDAY';
    final map = HomeWidgetEngine.toPreferenceMap(
      snapshot,
      showFasting: fasting,
      showGeez: geez,
      showSaint: saint,
      size: widgetSize,
      firstDayOfWeek: firstDay,
      themeFamily: resolvedFamily.id,
    );

    // Keep Flutter prefs in sync for in-app UI / fallbacks.
    for (final entry in map.entries) {
      await prefs.setString(entry.key, entry.value);
    }
    await prefs.setInt(
      'pref_widget_style',
      styleIndex.clamp(0, HomeWidgetKindX.lastIndex),
    );
    await prefs.setBool(keyShowFasting, fasting);
    await prefs.setBool(keyShowGeez, geez);
    await prefs.setBool(keyShowSaint, saint);
    await prefs.setString(keySize, widgetSize);
    await prefs.setBool(keyThemeAuto, auto);
    await prefs.setString(keyThemeFamily, resolvedFamily.id);

    if (_isAndroid) {
      try {
        // Push payload directly into native SharedPreferences so the
        // AppWidgetHost process never depends on FlutterSharedPreferences.
        await _channel.invokeMethod<void>('updateWidgets', map);
      } catch (e, st) {
        debugPrint('HomeWidgetSync.updateWidgets failed: $e\n$st');
      }
    }
    return snapshot;
  }

  static Future<Map<String, Object>> loadOptions() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'showFasting': prefs.getBool(keyShowFasting) ?? true,
      'showGeez': prefs.getBool(keyShowGeez) ?? true,
      'showSaint': prefs.getBool(keyShowSaint) ?? true,
      'size': prefs.getString(keySize) ?? 'compact',
      'themeAuto': prefs.getBool(keyThemeAuto) ?? true,
      'themeFamily':
          prefs.getString(keyThemeFamily) ?? WidgetThemeFamily.coralStudio.id,
    };
  }

  static Future<String> requestPin() async {
    if (kIsWeb) return 'web_preview';
    if (!_isAndroid) return 'unsupported';
    try {
      final result = await _channel.invokeMethod<String>('requestPin');
      return result ?? 'unknown';
    } on PlatformException catch (e) {
      return e.code;
    } catch (_) {
      return 'error';
    }
  }

  static Future<bool> areWidgetsPinned() async {
    if (!_isAndroid) return false;
    try {
      final count = await _channel.invokeMethod<int>('widgetCount') ?? 0;
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getInitialDestination() async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('getInitialDestination');
    } catch (_) {
      return null;
    }
  }

  static void setDestinationHandler(void Function(String) onDestination) {
    if (!_isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDestinationChanged') {
        final dest = call.arguments as String?;
        if (dest != null) onDestination(dest);
      }
    });
  }
}
