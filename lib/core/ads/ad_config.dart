import 'package:flutter/foundation.dart';

import 'ad_platform.dart';

/// Centralized Google AdMob Configuration for Zemen: Ethiopian Calendar.
///
/// Production safety rules:
/// - Debug/QA may use Google sample test unit IDs.
/// - Release serves ads ONLY when real production unit IDs are configured
///   (placeholders keep ads off so Play Store builds stay policy-safe).
/// - Set [forceTestAds] true only for pre-launch QA builds.
/// - Flutter Web never requests native AdMob/UMP (no plugin implementation).
class AdConfig {
  AdConfig._();

  /// Master switch. When false, no ad requests are made anywhere.
  /// Temporarily off while polishing the product (no Google test ads in debug).
  static const bool adsEnabled = false;

  /// Force Google sample test ads (debug/QA only). Must be false for Play release.
  static const bool forceTestAds = false;

  /// Whether current run should use Google test ad unit IDs.
  static bool get isTestMode => forceTestAds || kDebugMode;

  /// True when production AdMob unit IDs are configured (not placeholders).
  static bool get hasProductionUnits {
    return !_isPlaceholder(prodAndroidBannerId) &&
        !_isPlaceholder(prodAndroidInterstitialId) &&
        !_isPlaceholder(prodAndroidAppOpenId) &&
        !_isPlaceholder(prodAndroidNativeId);
  }

  /// Effective gate used by every ad loader / manager.
  /// Release without real AdMob IDs → ads stay off (ad-free compliant build).
  /// Web / desktop → always off (MissingPluginException prevention).
  static bool get canRequestAds {
    if (!AdPlatform.supportsMobileAds) return false;
    if (!adsEnabled) return false;
    if (isTestMode) return true;
    return hasProductionUnits;
  }

  // ===========================================================================
  // OFFICIAL GOOGLE ADMOB TEST AD UNIT IDS (Sample IDs)
  // ===========================================================================
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidAppOpenId = 'ca-app-pub-3940256099942544/9257390320';
  static const String testAndroidNativeId = 'ca-app-pub-3940256099942544/2247696110';

  static const String testIosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String testIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';
  static const String testIosAppOpenId = 'ca-app-pub-3940256099942544/5575463023';
  static const String testIosNativeId = 'ca-app-pub-3940256099942544/3986624511';

  // ===========================================================================
  // PRODUCTION ADMOB AD UNIT IDS
  // Prefer --dart-define / --dart-define-from-file (see admob_defines.json.example).
  // Until real IDs are supplied, release builds remain ad-free via [canRequestAds].
  // ===========================================================================
  static const String prodAndroidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/BANNER_ID',
  );
  static const String prodAndroidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/INTERSTITIAL_ID',
  );
  static const String prodAndroidAppOpenId = String.fromEnvironment(
    'ADMOB_ANDROID_APP_OPEN',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/APP_OPEN_ID',
  );
  static const String prodAndroidNativeId = String.fromEnvironment(
    'ADMOB_ANDROID_NATIVE',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/NATIVE_ID',
  );

  static const String prodIosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/IOS_BANNER_ID',
  );
  static const String prodIosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/IOS_INTERSTITIAL_ID',
  );
  static const String prodIosAppOpenId = String.fromEnvironment(
    'ADMOB_IOS_APP_OPEN',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/IOS_APP_OPEN_ID',
  );
  static const String prodIosNativeId = String.fromEnvironment(
    'ADMOB_IOS_NATIVE',
    defaultValue: 'ca-app-pub-YOUR_ADMOB_ACCOUNT_ID/IOS_NATIVE_ID',
  );

  // ===========================================================================
  // AD UNIT ID RESOLVERS
  // ===========================================================================

  static bool get _isAndroid =>
      defaultTargetPlatform == TargetPlatform.android;

  /// Resolves configured unit IDs (test or production).
  /// Callers must still gate on [canRequestAds] / [AdPlatform.supportsMobileAds]
  /// before invoking native AdMob APIs.
  static String get bannerAdUnitId {
    if (isTestMode) {
      return _isAndroid ? testAndroidBannerId : testIosBannerId;
    }
    final prodId = _isAndroid ? prodAndroidBannerId : prodIosBannerId;
    return _isPlaceholder(prodId) ? '' : prodId;
  }

  static String get interstitialAdUnitId {
    if (isTestMode) {
      return _isAndroid ? testAndroidInterstitialId : testIosInterstitialId;
    }
    final prodId =
        _isAndroid ? prodAndroidInterstitialId : prodIosInterstitialId;
    return _isPlaceholder(prodId) ? '' : prodId;
  }

  static String get appOpenAdUnitId {
    if (isTestMode) {
      return _isAndroid ? testAndroidAppOpenId : testIosAppOpenId;
    }
    final prodId = _isAndroid ? prodAndroidAppOpenId : prodIosAppOpenId;
    return _isPlaceholder(prodId) ? '' : prodId;
  }

  static String get nativeAdUnitId {
    if (isTestMode) {
      return _isAndroid ? testAndroidNativeId : testIosNativeId;
    }
    final prodId = _isAndroid ? prodAndroidNativeId : prodIosNativeId;
    return _isPlaceholder(prodId) ? '' : prodId;
  }

  static bool _isPlaceholder(String id) {
    return id.contains('YOUR_ADMOB_ACCOUNT_ID') ||
        id.contains('XXXXXXXX') ||
        id.isEmpty;
  }

  // ===========================================================================
  // POLICY COMPLIANCE & FREQUENCY CAPPING
  // ===========================================================================

  static const Duration interstitialCooldown = Duration(minutes: 3);
  static const int minActionsBeforeInterstitial = 3;
  static const Duration initialLaunchGracePeriod = Duration(seconds: 45);
  static const Duration appOpenCooldown = Duration(hours: 4);
  static const Duration minBackgroundDurationForAppOpen = Duration(minutes: 5);

  static const bool enableAppOpenAds = true;
  static const bool enableBannerAds = true;
  static const bool enableInterstitialAds = true;
  static const bool enableNativeAds = true;

  static const List<String> testDeviceIds = <String>[];

  /// Hosted privacy policy (required by Play Console + AdMob).
  /// Live on the football proxy Worker; override with PRIVACY_POLICY_URL if needed.
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://zemen-football-proxy.aplusethiopia1.workers.dev/privacy-policy.html',
  );
}
