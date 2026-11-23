import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_config.dart';
import 'ad_platform.dart';

/// Manages Google User Messaging Platform (UMP) consent state and privacy options.
///
/// Complies with:
/// - Google EU User Consent Policy (GDPR, UK, Switzerland)
/// - Google US State Privacy Laws (CPRA, Virginia, etc.)
/// - Play Store Data Safety & Consent Requirements
///
/// On Flutter Web / desktop this manager is a no-op: UMP has no web plugin and
/// calling [ConsentInformation] would throw [MissingPluginException].
class ConsentManager {
  static final ConsentManager instance = ConsentManager._internal();
  ConsentManager._internal();

  bool _canRequestAds = false;
  bool get canRequestAds => _canRequestAds;

  PrivacyOptionsRequirementStatus _privacyOptionsStatus =
      PrivacyOptionsRequirementStatus.unknown;
  bool get isPrivacyOptionsRequired =>
      _privacyOptionsStatus == PrivacyOptionsRequirementStatus.required;

  /// Requests consent info update and loads/shows consent form if required.
  ///
  /// Safe to call on every app launch; will only present UI if consent is
  /// required or changed.
  Future<bool> gatherConsent({bool simulateEea = false}) async {
    if (!AdPlatform.supportsMobileAds) {
      _canRequestAds = false;
      return false;
    }

    final completer = Completer<bool>();

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: (AdConfig.isTestMode && simulateEea)
          ? ConsentDebugSettings(
              debugGeography: DebugGeography.debugGeographyEea,
              testIdentifiers: AdConfig.testDeviceIds,
            )
          : null,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          // If a form is required (e.g. EU/EEA user on first run), load and show it.
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
            if (formError != null) {
              debugPrint('ConsentForm error: [${formError.errorCode}] ${formError.message}');
            }

            // Check if ads can now be requested
            _canRequestAds = await ConsentInformation.instance.canRequestAds();
            _privacyOptionsStatus = await ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus();

            if (!completer.isCompleted) {
              completer.complete(_canRequestAds);
            }
          });
        } catch (e) {
          debugPrint('Error presenting consent form: $e');
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
          if (!completer.isCompleted) completer.complete(_canRequestAds);
        }
      },
      (FormError error) async {
        debugPrint('ConsentInfoUpdate failed: [${error.errorCode}] ${error.message}');
        // Fall back to cached or default permission status if network is unavailable
        try {
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
        } catch (_) {
          _canRequestAds = true; // Fallback for standard non-regulated regions offline
        }
        if (!completer.isCompleted) completer.complete(_canRequestAds);
      },
    );

    // Timeout safety fallback: don't let consent check hang app initialization
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () async {
        debugPrint('Consent check timed out, continuing with safe fallback');
        try {
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
        } catch (_) {
          _canRequestAds = true;
        }
        return _canRequestAds;
      },
    );
  }

  /// Presents the Privacy Options form so users can review or change their
  /// ad consent choices at any time from the app Settings.
  ///
  /// Required by Google Play policy for apps serving ads in regulated regions.
  Future<void> showPrivacyOptionsForm({
    void Function(FormError? error)? onDismissed,
  }) async {
    if (!AdPlatform.supportsMobileAds) {
      onDismissed?.call(null);
      return;
    }
    try {
      await ConsentForm.showPrivacyOptionsForm((formError) async {
        if (formError != null) {
          debugPrint('Privacy options error: [${formError.errorCode}] ${formError.message}');
        }
        _canRequestAds = await ConsentInformation.instance.canRequestAds();
        _privacyOptionsStatus = await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus();
        onDismissed?.call(formError);
      });
    } catch (e) {
      debugPrint('Failed to open privacy options: $e');
    }
  }

  /// Resets consent state (useful for QA / debug testing only).
  Future<void> resetConsentForTesting() async {
    if (!AdPlatform.supportsMobileAds) return;
    if (AdConfig.isTestMode) {
      await ConsentInformation.instance.reset();
      _canRequestAds = false;
      _privacyOptionsStatus = PrivacyOptionsRequirementStatus.unknown;
      debugPrint('Consent state reset for testing.');
    }
  }
}
