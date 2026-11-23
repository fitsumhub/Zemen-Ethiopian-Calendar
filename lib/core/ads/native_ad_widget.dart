import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_colors.dart';
import 'ad_config.dart';
import 'ad_manager.dart';
import 'ad_platform.dart';
import 'consent_manager.dart';

/// Policy-Compliant Native Ad Widget for Zemen: Ethiopian Calendar.
///
/// Complies with Google AdMob Native Ad Policies:
/// - Visually distinct from application content (border, elevation, contrast).
/// - Prominently labeled with "Ad / ማስታወቂያ" badge.
/// - Cannot be mistaken for Ethiopian calendar events, fasting days, or holidays.
/// - Safely disposes platform views and native ad instances on unmount.
/// - Renders zero height on load failures without leaving broken layouts.
class NativeAdWidget extends StatefulWidget {
  final String? customAdUnitId;
  final TemplateType templateType;
  final EdgeInsetsGeometry margin;

  const NativeAdWidget({
    super.key,
    this.customAdUnitId,
    this.templateType = TemplateType.small,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  Future<void> _loadNativeAd() async {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableNativeAds) return;
    if (!ConsentManager.instance.canRequestAds) {
      debugPrint('NativeAdWidget: Loading deferred (consent pending).');
      return;
    }

    final adUnitId = widget.customAdUnitId ?? AdConfig.nativeAdUnitId;
    if (adUnitId.isEmpty) return;

    try {
      final ad = NativeAd(
        adUnitId: adUnitId,
        request: AdManager.instance.createAdRequest(),
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _isLoaded = true;
              _hasFailed = false;
            });
            debugPrint('NativeAdWidget: Native ad loaded.');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('NativeAdWidget: Failed to load: [${error.code}] ${error.message}');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _isLoaded = false;
              _hasFailed = true;
              _nativeAd = null;
            });
          },
          onAdOpened: (ad) => debugPrint('NativeAdWidget: Ad opened.'),
          onAdClosed: (ad) => debugPrint('NativeAdWidget: Ad closed.'),
        ),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: widget.templateType,
          mainBackgroundColor: AppColors.surface,
          cornerRadius: 12.0,
          callToActionTextStyle: NativeTemplateTextStyle(
            textColor: Colors.white,
            backgroundColor: AppColors.accent,
            style: NativeTemplateFontStyle.bold,
            size: 14.0,
          ),
          primaryTextStyle: NativeTemplateTextStyle(
            textColor: AppColors.textPrimary,
            style: NativeTemplateFontStyle.bold,
            size: 14.5,
          ),
          secondaryTextStyle: NativeTemplateTextStyle(
            textColor: AppColors.textSecondary,
            style: NativeTemplateFontStyle.normal,
            size: 12.5,
          ),
          tertiaryTextStyle: NativeTemplateTextStyle(
            textColor: AppColors.textSecondary.withValues(alpha: 0.8),
            style: NativeTemplateFontStyle.normal,
            size: 11.5,
          ),
        ),
      );

      _nativeAd = ad;
      await ad.load();
    } catch (e) {
      debugPrint('NativeAdWidget: Error loading native ad: $e');
      if (mounted) {
        setState(() => _hasFailed = true);
      }
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdPlatform.supportsMobileAds ||
        !AdConfig.canRequestAds ||
        !AdConfig.enableNativeAds ||
        _hasFailed ||
        !_isLoaded ||
        _nativeAd == null) {
      return const SizedBox.shrink();
    }

    // Small template height ~90-120dp; medium template height ~300-360dp
    final height = widget.templateType == TemplateType.small ? 100.0 : 340.0;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.surfaceBorder.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mandatory AdMob Policy Label: Must clearly distinguish from app content
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.surfaceBorder.withValues(alpha: 0.4),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Text(
              'SPONSORED / ማስታወቂያ',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            height: height,
            child: AdWidget(ad: _nativeAd!),
          ),
        ],
      ),
    );
  }
}
