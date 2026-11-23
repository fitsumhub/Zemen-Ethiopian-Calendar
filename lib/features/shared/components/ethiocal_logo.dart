import 'package:material_ui/material_ui.dart';
import '../../../core/brand/brand.dart';

/// Zemen brand mark (kept type name for call-site compatibility).
class EthioCalLogo extends StatelessWidget {
  final double size;
  final bool showGlow;

  const EthioCalLogo({
    super.key,
    this.size = 34.0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Brand.displayNameBilingual,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.28),
                    blurRadius: size * 0.22,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.22),
          child: Image.asset(
            Brand.logoAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                _ZemenFallbackMark(size: size),
          ),
        ),
      ),
    );
  }
}

class _ZemenFallbackMark extends StatelessWidget {
  final double size;
  const _ZemenFallbackMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06221A), Color(0xFF0B1526), Color(0xFF060C16)],
        ),
      ),
      child: Text(
        'Z',
        style: TextStyle(
          color: const Color(0xFFEAB308),
          fontSize: size * 0.48,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
