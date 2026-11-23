import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_frequency_controller.dart';
import 'ad_manager.dart';
import 'ad_platform.dart';
import 'consent_manager.dart';

/// Manages App Open Ads displayed when the app returns from the background.
///
/// AdMob Policy Guarantees:
/// - Never shown on cold app launch.
/// - Never shown if the app was only backgrounded for a few seconds.
/// - Frequency capped to prevent spamming returning users.
/// - Respects user consent.
class AppOpenAdManager with WidgetsBindingObserver {
  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  bool get isAdAvailable {
    final ad = _appOpenAd;
    final loadTime = _appOpenLoadTime;
    if (ad == null || loadTime == null) return false;
    // App open ads expire after 4 hours per AdMob documentation
    return DateTime.now().difference(loadTime) < const Duration(hours: 4);
  }

  /// Initializes lifecycle observer.
  void initialize() {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableAppOpenAds) return;
    WidgetsBinding.instance.addObserver(this);
    preload();
  }

  /// Preloads an App Open ad.
  Future<void> preload() async {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableAppOpenAds) return;
    if (_isLoading || isAdAvailable) return;
    if (!ConsentManager.instance.canRequestAds) return;

    final adUnitId = AdConfig.appOpenAdUnitId;
    if (adUnitId.isEmpty) return;

    _isLoading = true;

    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: AdManager.instance.createAdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAdManager: App open ad loaded successfully.');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoading = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('AppOpenAdManager: Failed to load: [${error.code}] ${error.message}');
          _appOpenAd = null;
          _isLoading = false;
        },
      ),
    );
  }

  /// Evaluates app lifecycle transitions.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableAppOpenAds) return;

    if (state == AppLifecycleState.paused) {
      AdFrequencyController.instance.recordAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    if (_isShowingAd) return;

    // Check if App Open ad is permitted by policy & cooldown
    if (!AdFrequencyController.instance.canShowAppOpen()) {
      return;
    }

    if (!isAdAvailable) {
      preload();
      return;
    }

    showAdIfAvailable();
  }

  /// Shows the loaded App Open ad if available.
  void showAdIfAvailable() {
    final ad = _appOpenAd;
    if (ad == null || _isShowingAd) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('AppOpenAdManager: App Open Ad showed.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAdManager: App Open Ad dismissed.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        AdFrequencyController.instance.markAppOpenShown();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('AppOpenAdManager: Failed to show: [${error.code}] ${error.message}');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        preload();
      },
    );

    ad.show();
  }

  /// Cleans up observer and active ad.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoading = false;
    _isShowingAd = false;
  }
}
