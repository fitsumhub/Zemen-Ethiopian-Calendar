import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_colors.dart';
import 'ad_config.dart';
import 'ad_manager.dart';
import 'ad_platform.dart';
import 'consent_manager.dart';

/// Reusable, Policy-Compliant Adaptive Banner Ad Widget.
///
/// Complies with Google AdMob Best Practices:
/// - Pre-calculates anchored adaptive banner size to fit device width.
/// - Reserves layout space to prevent Cumulative Layout Shift (CLS / jumping UI).
/// - Positioned away from critical navigation buttons to prevent accidental clicks.
/// - Safely disposes ad instances on widget unmount.
/// - Renders clean empty space when offline or on load failure.
class BannerAdWidget extends StatefulWidget {
  final String? customAdUnitId;
  final bool showAdLabel;
  final EdgeInsetsGeometry margin;
  final bool reserveSpaceWhileLoading;

  const BannerAdWidget({
    super.key,
    this.customAdUnitId,
    this.showAdLabel = true,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.reserveSpaceWhileLoading = true,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  AnchoredAdaptiveBannerAdSize? _adaptiveSize;
  bool _isLoaded = false;
  bool _hasFailed = false;
  bool _isInitializing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitializing && _bannerAd == null) {
      _loadAdaptiveBanner();
    }
  }

  Future<void> _loadAdaptiveBanner() async {
    if (!AdPlatform.supportsMobileAds) return;
    if (!AdConfig.canRequestAds || !AdConfig.enableBannerAds) return;
    if (!ConsentManager.instance.canRequestAds) {
      debugPrint('BannerAdWidget: Deferred loading (consent pending).');
      return;
    }

    _isInitializing = true;
    final width = MediaQuery.sizeOf(context).width.truncate();

    try {
      // 1. Get Google-recommended Anchored Adaptive Banner size
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      if (!mounted) return;

      if (size == null) {
        debugPrint('BannerAdWidget: Unable to compute adaptive size for width $width');
        setState(() => _hasFailed = true);
        return;
      }

      setState(() {
        _adaptiveSize = size;
      });

      // 2. Instantiate BannerAd with explicit lifecycle listeners
      final adUnitId = widget.customAdUnitId ?? AdConfig.bannerAdUnitId;
      if (adUnitId.isEmpty) return;

      final ad = BannerAd(
        adUnitId: adUnitId,
        size: size,
        request: AdManager.instance.createAdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _isLoaded = true;
              _hasFailed = false;
            });
            debugPrint('BannerAdWidget: Loaded successfully ($size).');
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAdWidget: Failed to load: [${error.code}] ${error.message}');
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _isLoaded = false;
              _hasFailed = true;
              _bannerAd = null;
            });
          },
          onAdOpened: (ad) => debugPrint('BannerAdWidget: Ad clicked/opened.'),
          onAdClosed: (ad) => debugPrint('BannerAdWidget: Ad closed.'),
        ),
      );

      _bannerAd = ad;
      await ad.load();
    } catch (e) {
      debugPrint('BannerAdWidget: Error loading banner: $e');
      if (mounted) {
        setState(() => _hasFailed = true);
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdPlatform.supportsMobileAds ||
        !AdConfig.canRequestAds ||
        !AdConfig.enableBannerAds ||
        _hasFailed) {
      return const SizedBox.shrink();
    }

    final size = _adaptiveSize;

    // While loading, reserve space to prevent sudden UI jump (CLS)
    if (!_isLoaded) {
      if (!widget.reserveSpaceWhileLoading) {
        return const SizedBox.shrink();
      }
      final reservedHeight = size?.height.toDouble() ?? 50.0;
      return Container(
        height: reservedHeight,
        margin: widget.margin,
        color: Colors.transparent,
      );
    }

    if (_bannerAd == null || size == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: widget.margin,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showAdLabel)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              margin: EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'AD / ማስታወቂያ',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          SizedBox(
            width: size.width.toDouble(),
            height: size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }
}
