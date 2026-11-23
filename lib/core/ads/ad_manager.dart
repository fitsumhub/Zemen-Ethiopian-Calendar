import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_platform.dart';
import 'consent_manager.dart';
import 'interstitial_ad_manager.dart';
import 'app_open_ad_manager.dart';

/// Central entry point for Google Mobile Ads initialization and lifecycle in Zemen: Ethiopian Calendar.
class AdManager {
  static final AdManager instance = AdManager._internal();
  AdManager._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes AdMob with Google UMP Consent flow and preloads critical units.
  ///
  /// Call this in `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
  /// No-ops on Flutter Web / desktop — native plugins are unavailable there.
  Future<void> initialize({bool simulateEeaConsent = false}) async {
    if (!AdPlatform.supportsMobileAds) {
      debugPrint('AdManager: Skipping Mobile Ads init (unsupported platform).');
      return;
    }

    if (!AdConfig.canRequestAds) {
      debugPrint('AdManager: Ads are globally disabled via AdConfig.');
      return;
    }

    if (_isInitialized) {
      debugPrint('AdManager: Already initialized. Skipping.');
      return;
    }

    try {
      // 1. Gather GDPR / UMP Consent before requesting any ads
      await ConsentManager.instance.gatherConsent(simulateEea: simulateEeaConsent);

      // 2. Configure Test Devices and Target Audience parameters
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: AdConfig.testDeviceIds,
        maxAdContentRating: MaxAdContentRating.g, // Family friendly / General audience
        ageRestrictedTreatment: AgeRestrictedTreatment.unspecified,
      );
      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      // 3. Initialize Mobile Ads SDK
      final initStatus = await MobileAds.instance.initialize();
      _isInitialized = true;

      if (kDebugMode) {
        initStatus.adapterStatuses.forEach((adapter, status) {
          debugPrint('AdMob Adapter [$adapter]: state=${status.state}, latency=${status.latency}ms');
        });
      }

      // 4. Preload initial full-screen ad units if enabled and consent allows
      if (ConsentManager.instance.canRequestAds) {
        if (AdConfig.enableInterstitialAds) {
          InterstitialAdManager.instance.preload();
        }
        if (AdConfig.enableAppOpenAds) {
          AppOpenAdManager.instance.initialize();
        }
      }
    } catch (e, stack) {
      debugPrint('AdManager: Initialization error: $e\n$stack');
      // Gracefully allow app to run without ads if initialization fails (e.g., offline)
    }
  }

  /// Factory method to generate compliant AdRequest instances.
  AdRequest createAdRequest() {
    return const AdRequest(
      // Non-personalized ads flags are automatically governed by the UMP consent string,
      // but additional keywords can guide relevant category matching.
      keywords: <String>[
        'calendar',
        'ethiopia',
        'events',
        'utilities',
        'productivity',
        'sports',
      ],
    );
  }
}
