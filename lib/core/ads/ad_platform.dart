import 'package:flutter/foundation.dart';

/// Platform gates for Google Mobile Ads / UMP.
///
/// Native AdMob + UMP plugins are not available on Flutter Web (or desktop).
/// Calling them there throws [MissingPluginException] and floods the console.
class AdPlatform {
  AdPlatform._();

  /// True only where `google_mobile_ads` has a native implementation.
  static bool get supportsMobileAds {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }
}
