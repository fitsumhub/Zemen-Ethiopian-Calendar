import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Shared Zemen visual tokens & small chrome widgets.
class AppChrome {
  static List<String> get fontFallbacks => AppTheme.ethiopicFontFallbacks;

  static TextStyle display({
    double size = 26,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.15,
    double spacing = -0.3,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: spacing
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static TextStyle title({
    double size = 16,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.25,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: height,
        letterSpacing: -0.2
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: 1.35
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static TextStyle mute({
    double size = 12,
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textSecondary,
        height: 1.3
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static TextStyle label({
    double size = 13,
    FontWeight weight = FontWeight.w600,
    Color? color,
    double spacing = 0.1,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        letterSpacing: spacing
      ).copyWith(fontFamilyFallback: fontFallbacks);

  static List<BoxShadow> get softCard => [
    BoxShadow(
      color: AppColors.isDark
          ? Colors.black.withValues(alpha: 0.35)
          : Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: softCard,
      );
}

/// Primary "add" action. One look everywhere: accent fill, readable icon,
/// 56dp target, tooltip and screen-reader label.
class AppFab extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;

  const AppFab({
    super.key,
    required this.onTap,
    required this.label,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: AppPressable(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.onAccent, size: 28),
          ),
        ),
      ),
    );
  }
}

/// Soft press scale for interactive rows / FAB.
class AppPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.borderRadius == null
        ? widget.child
        : ClipRRect(borderRadius: widget.borderRadius!, child: widget.child);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp:
          widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel:
          widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: child,
      ),
    );
  }
}
