import 'package:material_ui/material_ui.dart';
import '../../../core/theme/app_colors.dart';

/// Compact verification chip for calendar data provenance theme.
class CalendarProvenanceBadge extends StatelessWidget {
  final String verification;
  final String? subtitle;

  const CalendarProvenanceBadge({
    super.key,
    required this.verification,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = CalendarDataTheme.colorFor(verification);
    final label = CalendarDataTheme.labelFor(verification);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              subtitle == null ? label : '$label · $subtitle',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
