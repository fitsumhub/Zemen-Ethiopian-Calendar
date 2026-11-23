import 'package:material_ui/material_ui.dart';
import '../../../core/theme/app_colors.dart';

/// Premium dual-date cell — Mastercard-inspired circular hierarchy & soft depth.
class DualDateDayCell extends StatelessWidget {
  final String primaryText;
  final String secondaryText;
  final bool isToday;
  final bool isSelected;
  final bool isSunday;
  final bool isPublicHoliday;
  final bool hasReligiousHoliday;
  final bool hasEvents;
  final bool isFasting;
  final bool showFasting;
  final bool compactGeez;
  final VoidCallback onTap;

  const DualDateDayCell({
    super.key,
    required this.primaryText,
    required this.secondaryText,
    required this.isToday,
    required this.isSelected,
    required this.isSunday,
    required this.isPublicHoliday,
    required this.hasReligiousHoliday,
    required this.hasEvents,
    required this.isFasting,
    required this.showFasting,
    required this.onTap,
    this.compactGeez = false,
  });

  static const _sundayRed = Color(0xFFDC2626);
  static const _govHoliday = AppColors.govHolidayRing;
  static const _govHolidayFill = AppColors.govHolidayFill;
  static const _govHolidayGlow = AppColors.govHolidayGlow;
  static const _eventRed = Color(0xFFEF4444);
  static const _fastGreen = Color(0xFF0D6B4C);
  static const _feastTeal = Color(0xFF1B4B7A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emphasize = isToday || isSelected;
    final primary = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary.withValues(alpha: 0.22),
                      primary.withValues(alpha: 0.08),
                    ],
                  )
                : isToday
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withValues(alpha: 0.14),
                          primary.withValues(alpha: 0.04),
                        ],
                      )
                    : isPublicHoliday
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _govHolidayGlow.withValues(alpha: 0.42),
                              _govHolidayFill.withValues(alpha: 0.18),
                            ],
                          )
                        : hasEvents
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _eventRed.withValues(alpha: 0.15),
                                  _eventRed.withValues(alpha: 0.04),
                                ],
                              )
                            : null,
            color: emphasize || isPublicHoliday || hasEvents ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              width: emphasize ? 1.5 : (hasEvents ? 1.2 : 0.8),
              color: isSelected
                  ? primary.withValues(alpha: 0.85)
                  : isToday
                      ? primary.withValues(alpha: 0.45)
                      : hasEvents
                          ? _eventRed.withValues(alpha: 0.6)
                          : theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // Mastercard-style overlapping circle watermark on selected/today
              if (emphasize)
                Positioned(
                  right: -6,
                  bottom: -8,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 34,
                      height: 22,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.secondary.withValues(alpha: 0.16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Container(
                    width: isPublicHoliday && !isToday ? 36 : 32,
                    height: isPublicHoliday && !isToday ? 36 : 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isToday
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary,
                                Color.lerp(primary, AppColors.ethioGoldPrimary, 0.25) ?? primary,
                              ],
                            )
                          : isPublicHoliday
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _govHolidayGlow,
                                    _govHoliday,
                                    _govHolidayFill,
                                  ],
                                )
                              : null,
                      color: isToday || isPublicHoliday
                          ? null
                          : isSelected
                              ? primary.withValues(alpha: 0.16)
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: !isToday && isPublicHoliday
                          ? Border.all(color: Colors.white, width: 2.8)
                          : null,
                      boxShadow: isToday
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : isPublicHoliday
                              ? [
                                  BoxShadow(
                                    color: _govHolidayGlow.withValues(alpha: 0.85),
                                    blurRadius: 14,
                                    spreadRadius: 1.5,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                    ),
                    child: Text(
                      primaryText,
                      style: TextStyle(
                        fontSize: compactGeez
                            ? 12
                            : (isPublicHoliday ? 16 : 14),
                        fontWeight: emphasize || isPublicHoliday
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: emphasize ? -0.2 : 0,
                        height: 1,
                        color: isToday
                            ? theme.colorScheme.onPrimary
                            : isPublicHoliday
                                ? const Color(0xFF1A1200)
                                : isSelected
                                    ? primary
                                    : isSunday
                                        ? _sundayRed
                                        : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    secondaryText,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isPublicHoliday
                          ? FontWeight.w900
                          : FontWeight.w600,
                      letterSpacing: 0.2,
                      color: isToday
                          ? primary
                          : isSelected
                              ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.9)
                              : isPublicHoliday
                                  ? _govHolidayGlow
                                  : isSunday
                                      ? _sundayRed.withValues(alpha: 0.72)
                                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPublicHoliday) _dot(_govHolidayGlow, size: 6.5),
                      if (hasReligiousHoliday) _dot(_feastTeal),
                      if (hasEvents) _dot(_eventRed, size: 3.6),
                      if (showFasting && isFasting) _dot(_fastGreen, size: 3.2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _dot(Color color, {double size = 4}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.symmetric(horizontal: 1.2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
