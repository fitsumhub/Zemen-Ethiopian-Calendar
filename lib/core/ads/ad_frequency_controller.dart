import 'package:flutter/foundation.dart';
import 'ad_config.dart';

/// Centralized frequency capping, cooldown controller, and policy compliance guard.
///
/// Ensures:
/// 1. Interstitials are never shown immediately on app launch (grace period).
/// 2. Interstitials require a minimum number of deliberate user interactions.
/// 3. Interstitials respect strict cooldown duration between appearances.
/// 4. App Open ads are not shown on every background-to-foreground switch.
/// 5. No disruptive popups during sensitive calendar operations.
class AdFrequencyController {
  static final AdFrequencyController instance = AdFrequencyController._internal();
  AdFrequencyController._internal() {
    _appStartTime = DateTime.now();
  }

  late DateTime _appStartTime;
  DateTime? _lastInterstitialTime;
  DateTime? _lastAppOpenTime;
  DateTime? _appPausedTime;
  int _userActionCount = 0;

  int get userActionCount => _userActionCount;
  DateTime? get lastInterstitialTime => _lastInterstitialTime;

  /// Records a significant user interaction (e.g., date conversion, card share, match viewed).
  void recordUserAction([String? actionName]) {
    _userActionCount++;
    if (kDebugMode && actionName != null) {
      debugPrint('AdFrequencyController: action "$actionName" recorded (count: $_userActionCount)');
    }
  }

  /// Evaluates whether an Interstitial Ad is policy-compliant and eligible to show.
  bool canShowInterstitial() {
    if (!AdConfig.canRequestAds || !AdConfig.enableInterstitialAds) {
      return false;
    }

    final now = DateTime.now();

    // 1. Enforce initial launch grace period (Never interrupt user right after launch)
    if (now.difference(_appStartTime) < AdConfig.initialLaunchGracePeriod) {
      if (kDebugMode) {
        final remaining = AdConfig.initialLaunchGracePeriod - now.difference(_appStartTime);
        debugPrint('AdFrequencyController: Interstitial blocked by launch grace period (${remaining.inSeconds}s left)');
      }
      return false;
    }

    // 2. Enforce minimum user interactions threshold
    if (_userActionCount < AdConfig.minActionsBeforeInterstitial) {
      if (kDebugMode) {
        debugPrint('AdFrequencyController: Interstitial blocked by action threshold ($_userActionCount / ${AdConfig.minActionsBeforeInterstitial})');
      }
      return false;
    }

    // 3. Enforce cooldown between interstitials
    if (_lastInterstitialTime != null) {
      final elapsed = now.difference(_lastInterstitialTime!);
      if (elapsed < AdConfig.interstitialCooldown) {
        if (kDebugMode) {
          final remaining = AdConfig.interstitialCooldown - elapsed;
          debugPrint('AdFrequencyController: Interstitial blocked by cooldown (${remaining.inSeconds}s left)');
        }
        return false;
      }
    }

    return true;
  }

  /// Marks that an interstitial ad was successfully displayed, resetting the action counter
  /// and starting the cooldown timer.
  void markInterstitialShown() {
    _lastInterstitialTime = DateTime.now();
    _userActionCount = 0;
    if (kDebugMode) {
      debugPrint('AdFrequencyController: Interstitial displayed at $_lastInterstitialTime. Cooldown started.');
    }
  }

  /// Records when the app transitions into the background.
  void recordAppPaused() {
    _appPausedTime = DateTime.now();
  }

  /// Evaluates whether an App Open ad is permitted upon returning to the foreground.
  bool canShowAppOpen() {
    if (!AdConfig.canRequestAds || !AdConfig.enableAppOpenAds) {
      return false;
    }

    final now = DateTime.now();

    // Do not show App Open ad during initial app launch
    if (now.difference(_appStartTime) < AdConfig.initialLaunchGracePeriod) {
      return false;
    }

    // Check if app was backgrounded for minimum required duration
    if (_appPausedTime != null) {
      final backgroundDuration = now.difference(_appPausedTime!);
      if (backgroundDuration < AdConfig.minBackgroundDurationForAppOpen) {
        if (kDebugMode) {
          debugPrint('AdFrequencyController: App Open ad skipped (app was backgrounded only for ${backgroundDuration.inSeconds}s)');
        }
        return false;
      }
    } else {
      return false;
    }

    // Check cooldown between App Open ads
    if (_lastAppOpenTime != null) {
      final elapsed = now.difference(_lastAppOpenTime!);
      if (elapsed < AdConfig.appOpenCooldown) {
        if (kDebugMode) {
          debugPrint('AdFrequencyController: App Open ad skipped (cooldown ${elapsed.inMinutes}m / ${AdConfig.appOpenCooldown.inMinutes}m)');
        }
        return false;
      }
    }

    return true;
  }

  /// Marks that an App Open ad was successfully displayed.
  void markAppOpenShown() {
    _lastAppOpenTime = DateTime.now();
    _appPausedTime = null;
    if (kDebugMode) {
      debugPrint('AdFrequencyController: App Open ad displayed at $_lastAppOpenTime.');
    }
  }

  /// Resets controller state (for testing or debugging).
  void reset() {
    _appStartTime = DateTime.now();
    _lastInterstitialTime = null;
    _lastAppOpenTime = null;
    _appPausedTime = null;
    _userActionCount = 0;
  }
}
