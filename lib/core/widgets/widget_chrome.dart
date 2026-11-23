import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widget_theme.dart';

/// Shared premium chrome — Z mark, ticks, foil rules, typography helpers.
class WidgetChrome {
  WidgetChrome._();

  /// Product (coral) cards use bold Outfit; luxury families keep Cinzel display.
  static bool _product(WidgetThemePalette p) =>
      p.family == WidgetThemeFamily.coralStudio;

  static TextStyle brandStyle(WidgetThemePalette p) => _product(p)
      ? GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: p.accent,
        )
      : GoogleFonts.cinzel(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.6,
          color: p.accent,
        );

  static TextStyle dayStyle(WidgetThemePalette p, {double size = WidgetThemeTokens.dayNumeral}) =>
      _product(p)
          ? GoogleFonts.outfit(
              fontSize: size,
              fontWeight: FontWeight.w900,
              height: 0.9,
              color: p.dayNumeral,
              letterSpacing: -1.2,
            )
          : GoogleFonts.cinzel(
              fontSize: size,
              fontWeight: FontWeight.w900,
              height: 0.88,
              color: p.dayNumeral,
            );

  static TextStyle headingStyle(WidgetThemePalette p, {double size = 14}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: p.textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle bodyStyle(WidgetThemePalette p, {double size = 11}) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: p.textMuted,
      );

  static TextStyle labelStyle(WidgetThemePalette p) => GoogleFonts.outfit(
        fontSize: _product(p) ? 11 : 10,
        fontWeight: FontWeight.w900,
        letterSpacing: _product(p) ? 0.2 : 1.6,
        color: p.accent,
      );
}

class WidgetBrandMark extends StatelessWidget {
  final WidgetThemePalette palette;
  final String label;

  const WidgetBrandMark({
    super.key,
    required this.palette,
    this.label = 'ZEMEN',
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: WidgetThemeTokens.brandMark,
          height: WidgetThemeTokens.brandMark,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.accent.withValues(alpha: 0.7)),
          ),
          child: Text(
            'Z',
            style: GoogleFonts.cinzel(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: p.accent,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: WidgetChrome.brandStyle(p),
          ),
        ),
      ],
    );
  }
}

class WidgetFoilRule extends StatelessWidget {
  final WidgetThemePalette palette;
  final double? width;
  final bool expand;

  const WidgetFoilRule({
    super.key,
    required this.palette,
    this.width = 36,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = palette.accent;
    final bar = Container(
      width: expand ? null : width,
      height: WidgetThemeTokens.hairline,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [c.withValues(alpha: 0), c, c.withValues(alpha: 0)],
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: bar) : bar;
  }
}

class WidgetCornerFrame extends StatelessWidget {
  final WidgetThemePalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showTicks;

  const WidgetCornerFrame({
    super.key,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(WidgetThemeTokens.pad),
    this.showTicks = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final product = p.family == WidgetThemeFamily.coralStudio;
    return Container(
      decoration: BoxDecoration(
        color: product ? p.canvas : null,
        gradient: product ? null : p.backgroundGradient,
        border: Border.all(color: p.border.withValues(alpha: 0.95)),
      ),
      child: Stack(
        children: [
          if (showTicks && !product) ...[
            Positioned(top: 7, left: 7, child: _Tick(color: p.accent)),
            Positioned(
              top: 7,
              right: 7,
              child: Transform.rotate(angle: 1.5708, child: _Tick(color: p.accent)),
            ),
            Positioned(
              bottom: 7,
              left: 7,
              child: Transform.rotate(angle: -1.5708, child: _Tick(color: p.accent)),
            ),
            Positioned(
              bottom: 7,
              right: 7,
              child: Transform.rotate(angle: 3.1416, child: _Tick(color: p.accent)),
            ),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  final Color color;
  const _Tick({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: WidgetThemeTokens.cornerTick,
      height: WidgetThemeTokens.cornerTick,
      child: CustomPaint(painter: _TickPainter(color.withValues(alpha: 0.7))),
    );
  }
}

class _TickPainter extends CustomPainter {
  final Color color;
  _TickPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.15
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class WidgetStatusDot extends StatelessWidget {
  final WidgetThemePalette palette;
  final bool active;

  const WidgetStatusDot({
    super.key,
    required this.palette,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final c = active ? WidgetTheme.emerald : palette.accent;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c,
        boxShadow: [
          BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 5),
        ],
      ),
    );
  }
}

class WidgetProgressBar extends StatelessWidget {
  final WidgetThemePalette palette;
  final double value;

  const WidgetProgressBar({
    super.key,
    required this.palette,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 3.5,
        backgroundColor: palette.progressTrack,
        color: palette.progressFill,
      ),
    );
  }
}

/// Selected-card shell for the atelier grid.
BoxDecoration widgetCardShell({
  required WidgetThemePalette palette,
  required bool selected,
}) {
  final product = palette.family == WidgetThemeFamily.coralStudio;
  return BoxDecoration(
    color: product ? palette.canvas : null,
    gradient: product ? null : palette.backgroundGradient,
    borderRadius: BorderRadius.circular(WidgetThemeTokens.radiusCard),
    border: Border.all(
      color: selected ? palette.accent : palette.border,
      width: selected ? 1.8 : 1,
    ),
    boxShadow: [
      BoxShadow(
        color: selected
            ? palette.accent.withValues(alpha: product ? 0.18 : 0.22)
            : Colors.black.withValues(alpha: palette.isLight ? 0.06 : 0.35),
        blurRadius: selected ? 16 : 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
