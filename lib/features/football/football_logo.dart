import 'package:material_ui/material_ui.dart';
import 'football_data.dart';
import 'football_network_config.dart';

/// Official crest image (network or asset) with letter fallback.
///
/// On Flutter Web, remote badge URLs are rewritten through
/// [FootballNetworkConfig.imageUrl] so TheSportsDB / ESPN CDNs are not
/// blocked by CORS.
class FootballLogo extends StatelessWidget {
  final String? assetPath;
  final String? networkUrl;
  final String fallbackLetters;
  final Color fallbackColor;
  final double size;
  final bool circle;
  final bool elevated;

  const FootballLogo({
    super.key,
    required this.assetPath,
    required this.fallbackLetters,
    required this.fallbackColor,
    this.networkUrl,
    this.size = 40,
    this.circle = false,
    this.elevated = false,
  });

  factory FootballLogo.team(
    FootballTeam team, {
    double size = 28,
    bool circle = true,
    bool elevated = false,
  }) {
    return FootballLogo(
      assetPath: team.logoAsset,
      networkUrl: team.logoUrl,
      fallbackLetters: team.mark.letters,
      fallbackColor: Color(team.mark.colorValue),
      size: size,
      circle: circle,
      elevated: elevated,
    );
  }

  factory FootballLogo.league(
    FootballLeague league, {
    double size = 44,
    bool elevated = true,
  }) {
    return FootballLogo(
      assetPath: league.logoAsset,
      networkUrl: league.logoUrl,
      fallbackLetters: league.mark.letters,
      fallbackColor: Color(league.mark.colorValue),
      size: size,
      circle: false,
      elevated: elevated,
    );
  }

  factory FootballLogo.competition(
    Competition competition, {
    double size = 44,
    bool elevated = true,
  }) {
    return FootballLogo(
      assetPath: competition.logoAsset,
      networkUrl: competition.logoUrl,
      fallbackLetters: competition.shortName.isNotEmpty
          ? competition.shortName
          : (competition.name.isNotEmpty ? competition.name.substring(0, 1) : 'L'),
      fallbackColor: const Color(0xFF1B5E20),
      size: size,
      circle: false,
      elevated: elevated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pixel = (size * MediaQuery.devicePixelRatioOf(context)).round().clamp(48, 512);
    final resolvedUrl = FootballNetworkConfig.imageUrl(networkUrl);
    final fallback = _FallbackBadge(
      letters: fallbackLetters,
      color: fallbackColor,
      size: size * 0.88,
      circle: circle,
    );

    Widget image;
    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      image = Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Image.network(
          resolvedUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: pixel,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            if (assetPath != null) {
              return Image.asset(
                assetPath!,
                width: size,
                height: size,
                fit: BoxFit.contain,
                cacheWidth: pixel,
                errorBuilder: (_, _, _) => fallback,
              );
            }
            return SizedBox(
              width: size * 0.5,
              height: size * 0.5,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, _, _) {
            if (assetPath != null) {
              return Image.asset(
                assetPath!,
                width: size,
                height: size,
                fit: BoxFit.contain,
                cacheWidth: pixel,
                errorBuilder: (_, _, _) => fallback,
              );
            }
            return fallback;
          },
        ),
      );
    } else if (assetPath != null) {
      image = Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          assetPath!,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: pixel,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    } else {
      image = fallback;
    }

    final borderColor = isDark ? const Color(0x28FFFFFF) : const Color(0x18000000);
    final fill = isDark ? const Color(0xFFF8FAFC) : Colors.white;
    final shell = circle
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: fill,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: elevated
                  ? [
                      BoxShadow(
                        color: isDark
                            ? const Color(0x50000000)
                            : const Color(0x18000000),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: image,
          )
        : Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(size * 0.2),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: elevated
                  ? [
                      BoxShadow(
                        color: isDark
                            ? const Color(0x50000000)
                            : const Color(0x16000000),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: image,
          );

    return SizedBox(width: size, height: size, child: shell);
  }
}

class _FallbackBadge extends StatelessWidget {
  final String letters;
  final Color color;
  final double size;
  final bool circle;

  const _FallbackBadge({
    required this.letters,
    required this.color,
    required this.size,
    required this.circle,
  });

  @override
  Widget build(BuildContext context) {
    if (!circle && (letters == 'ET' || letters == 'EPL')) {
      return CustomPaint(
        size: Size(size, size),
        painter: _EthiopiaLeaguePainter(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        letters.length > 3 ? letters.substring(0, 3) : letters,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * (circle ? 0.28 : 0.26),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EthiopiaLeaguePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(8),
    );
    canvas.drawRRect(r, Paint()..color = Colors.white);
    canvas.drawRRect(
      r,
      Paint()
        ..color = const Color(0xFF1B5E20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final stripeH = size.height * 0.18;
    final colors = [const Color(0xFF078930), const Color(0xFFFCDD09), const Color(0xFFDA121A)];
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(4, 4 + i * stripeH * 0.55, size.width - 8, stripeH * 0.45),
        Paint()..color = colors[i],
      );
    }

    final cx = size.width / 2;
    final cy = size.height * 0.62;
    canvas.drawCircle(Offset(cx, cy), size.width * 0.18, Paint()..color = const Color(0xFF1B5E20));
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.18,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
