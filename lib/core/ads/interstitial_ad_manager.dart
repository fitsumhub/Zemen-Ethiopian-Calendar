import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_frequency_controller.dart';
import 'ad_manager.dart';
import 'ad_platform.dart';
import 'consent_manager.dart';

/// Preloads, manages, and safely presents AdMob Interstitial Ads.
///
/// AdMob Policy Guarantees:
/// - Never interrupts critical workflows or conversion inputs.
/// - Frequency capped and cooldown enforced via [AdFrequencyController].
/// - Always calls callback to ensure user can proceed even if ad fails.
/// - Does not leak memory (properly disposes old instances before allocating new ones).
class InterstitialAdManager {
  static final InterstitialAdManager instance = InterstitialAdManager._internal();
  InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  int _retryAttempts = 0;
  static const int _maxRetries = 3;

  bool get isAdReady => _interstitialAd != null;

  /// Preloads an Interstitial Ad in background.
  Future<void> preload() async {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableInterstitialAds) return;
    if (_interstitialAd != null || _isLoading) return;
    if (!ConsentManager.instance.canRequestAds) {
      debugPrint('InterstitialAdManager: Preload deferred (consent pending).');
      return;
    }

    final adUnitId = AdConfig.interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isLoading = true;

    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdManager.instance.createAdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAdManager: Ad successfully loaded.');
          _interstitialAd = ad;
          _isLoading = false;
          _retryAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAdManager: Failed to load: [${error.code}] ${error.message}');
          _interstitialAd = null;
          _isLoading = false;

          if (_retryAttempts < _maxRetries) {
            _retryAttempts++;
            final delaySeconds = 15 * _retryAttempts;
            debugPrint('InterstitialAdManager: Retrying in ${delaySeconds}s (attempt $_retryAttempts/$_maxRetries)...');
            Timer(Duration(seconds: delaySeconds), () => preload());
          }
        },
      ),
    );
  }

  /// Presents the interstitial ad IF policy conditions (grace period, action threshold,
  /// cooldown) are satisfied.
  ///
  /// [placement] identifies the natural transition point (for logging & analytics).
  /// [onDismissed] is guaranteed to be called whether the ad is shown, skipped, or fails.
  ///
  /// Returns `true` if ad presentation started, `false` otherwise.
  bool showIfAllowed({
    required String placement,
    VoidCallback? onDismissed,
  }) {
    if (!AdPlatform.supportsMobileAds ||
        !AdConfig.canRequestAds ||
        !AdConfig.enableInterstitialAds) {
      onDismissed?.call();
      return false;
    }

    // 1. Verify policy conditions (cooldown, action count, launch grace period)
    if (!AdFrequencyController.instance.canShowInterstitial()) {
      debugPrint('InterstitialAdManager: Ad skipped at placement "$placement" (policy capped).');
      onDismissed?.call();
      return false;
    }

    // 2. Check ad availability
    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('InterstitialAdManager: No ad ready at placement "$placement". Preloading for future...');
      onDismissed?.call();
      preload();
      return false;
    }

    // 3. Configure full-screen lifecycle callbacks
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('InterstitialAdManager: Ad displayed for placement "$placement".');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('InterstitialAdManager: Ad dismissed.');
        ad.dispose();
        _interstitialAd = null;
        AdFrequencyController.instance.markInterstitialShown();
        onDismissed?.call();
        // Preload next ad for the next transition point
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, AdError error) {
        debugPrint('InterstitialAdManager: Failed to show: [${error.code}] ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        onDismissed?.call();
        preload();
      },
    );

    ad.show();
    return true;
  }

  /// Cleans up any cached ad instances.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
  }
}
