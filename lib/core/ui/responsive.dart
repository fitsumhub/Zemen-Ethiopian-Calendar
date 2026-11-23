import 'package:material_ui/material_ui.dart';

/// Shared breakpoints for Zemen: Ethiopian Calendar (phone / tablet / desktop web).
class AppBreakpoints {
  static const double compact = 480;
  static const double medium = 840;
  static const double expanded = 1200;
}

class AppResponsive {
  final Size size;
  final EdgeInsets padding;

  AppResponsive(BuildContext context)
      : size = MediaQuery.sizeOf(context),
        padding = MediaQuery.paddingOf(context);

  double get width => size.width;
  double get height => size.height;

  bool get isCompact => width < AppBreakpoints.compact;
  bool get isMedium => width >= AppBreakpoints.compact && width < AppBreakpoints.medium;
  bool get isExpanded => width >= AppBreakpoints.medium;
  bool get isShort => height < 700;
  bool get isVeryShort => height < 560;

  /// Horizontal content inset that grows slightly on wide screens.
  EdgeInsets get pageInsets {
    final h = isExpanded
        ? (width * 0.08).clamp(24.0, 72.0)
        : isCompact
            ? 12.0
            : 16.0;
    return EdgeInsets.fromLTRB(h, 0, h, 0);
  }

  double get maxContentWidth => isExpanded ? 960.0 : width;

  /// Scales a base font size down slightly on very narrow widths.
  double font(double base) {
    if (width < 360) return base * 0.9;
    if (width > 1100) return base * 1.05;
    return base;
  }
}

/// Centers child and constrains width on large screens.
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveBody({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final r = AppResponsive(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: r.maxContentWidth),
        child: Padding(
          padding: padding ?? r.pageInsets,
          child: child,
        ),
      ),
    );
  }
}
