import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ethiocal/core/ads/ad_config.dart';
import 'package:ethiocal/core/ads/ad_frequency_controller.dart';
import 'package:ethiocal/core/ads/ad_platform.dart';
import 'package:ethiocal/core/ads/interstitial_ad_manager.dart';
import 'package:ethiocal/core/ads/app_open_ad_manager.dart';
import 'package:ethiocal/features/football/football_network_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdConfig Tests', () {
    test('Ads master switch is off for now (no test/prod ad requests)', () {
      expect(AdConfig.adsEnabled, isFalse);
      expect(AdConfig.canRequestAds, isFalse);
    });

    test('Debug unit resolvers still point at Google sample IDs when enabled later', () {
      expect(AdConfig.isTestMode, isTrue);
      expect(AdConfig.bannerAdUnitId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.interstitialAdUnitId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.appOpenAdUnitId, contains('ca-app-pub-3940256099942544'));
      expect(AdConfig.nativeAdUnitId, contains('ca-app-pub-3940256099942544'));
    });

    test('AdPlatform gates Mobile Ads away from web/desktop', () {
      // VM unit tests are never Flutter Web.
      expect(kIsWeb, isFalse);
      // On Windows/macOS/Linux hosts, native AdMob must stay off.
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        expect(AdPlatform.supportsMobileAds, isTrue);
      } else {
        expect(AdPlatform.supportsMobileAds, isFalse);
        expect(AdConfig.canRequestAds, isFalse);
      }
    });

    test('Policy constants satisfy AdMob guidelines', () {
      // Cooldown must be at least 2 minutes (we set 3 minutes)
      expect(AdConfig.interstitialCooldown.inMinutes, greaterThanOrEqualTo(2));
      // Min actions before interstitial must be at least 3
      expect(AdConfig.minActionsBeforeInterstitial, greaterThanOrEqualTo(3));
      // App launch grace period must be at least 30 seconds
      expect(AdConfig.initialLaunchGracePeriod.inSeconds, greaterThanOrEqualTo(30));
      // App open cooldown must be at least 1 hour
      expect(AdConfig.appOpenCooldown.inHours, greaterThanOrEqualTo(1));
    });
  });

  group('FootballNetworkConfig', () {
    test('mobile uses direct SportsDB host (no proxy)', () {
      expect(FootballNetworkConfig.useProxy, isFalse);
      expect(
        FootballNetworkConfig.sportsDbBase,
        'https://www.thesportsdb.com/api/v1/json/123',
      );
      expect(
        FootballNetworkConfig.imageUrl('https://r2.thesportsdb.com/badge.png'),
        'https://r2.thesportsdb.com/badge.png',
      );
    });
  });

  group('AdFrequencyController Tests', () {
    late AdFrequencyController controller;

    setUp(() {
      controller = AdFrequencyController.instance;
      controller.reset();
    });

    test('Blocks interstitial during initial launch grace period', () {
      expect(controller.canShowInterstitial(), isFalse);
    });

    test('Blocks interstitial if user action threshold is not met', () {
      // Record 2 actions (< 3 threshold)
      controller.recordUserAction('action_1');
      controller.recordUserAction('action_2');
      expect(controller.userActionCount, equals(2));
      expect(controller.canShowInterstitial(), isFalse);
    });

    test('Records actions and tracks count accurately', () {
      controller.recordUserAction('test_1');
      controller.recordUserAction('test_2');
      controller.recordUserAction('test_3');
      expect(controller.userActionCount, equals(3));
    });

    test('Blocks App Open ad if app was not backgrounded long enough', () {
      // Without recording background pause, App Open must be false
      expect(controller.canShowAppOpen(), isFalse);
    });
  });

  group('InterstitialAdManager Policy Gating Tests', () {
    test('showIfAllowed calls onDismissed when conditions not met', () {
      var dismissedCalled = false;

      final manager = InterstitialAdManager.instance;
      // Because frequency controller blocks right at launch, it should return false
      // and invoke onDismissed immediately.
      final result = manager.showIfAllowed(
        placement: 'unit_test_placement',
        onDismissed: () {
          dismissedCalled = true;
        },
      );

      expect(result, isFalse);
      expect(dismissedCalled, isTrue);
    });
  });

  group('AppOpenAdManager Lifecycle Tests', () {
    test('Manager initializes and provides availability state', () {
      final appOpen = AppOpenAdManager.instance;
      // Ad is not available on cold boot before loading
      expect(appOpen.isAdAvailable, isFalse);
    });
  });
}
