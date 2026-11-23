import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/holidays/holiday_engine.dart';

class FastingGuideTab extends StatelessWidget {
  final int selectedYear;

  const FastingGuideTab({super.key, required this.selectedYear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayEth = EthiopianCalendarEngine.todayEthiopian();
    final todayFasting = HolidayEngine.isFastingDay(todayEth);
    final canonicalFasts = HolidayEngine.getCanonicalFastsForYear(selectedYear);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Today's Fasting Status Banner
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: todayFasting.isFasting ? const Color(0xFF1E3A2B) : theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: todayFasting.isFasting
                        ? const Color(0xFF34D399).withValues(alpha: 0.2)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.restaurant,
                    color: todayFasting.isFasting ? const Color(0xFF34D399) : theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'የዛሬ የጾም ሁኔታ (Today\'s Status)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: todayFasting.isFasting ? const Color(0xFF34D399) : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayFasting.reason,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: todayFasting.isFasting ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        todayFasting.isFasting
                            ? 'ደረጃ: ${todayFasting.level.amharic} (${todayFasting.level.description})'
                            : 'የፍስክ ቀን ነው (Non-fasting day)',
                        style: TextStyle(
                          fontSize: 11,
                          color: todayFasting.isFasting ? Colors.white70 : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Canonical Fasts Header
        const Text(
          'ሰባቱ የኢትዮጵያ ኦርቶዶክስ ተዋሕዶ አጽዋማት (The 7 Canonical Fasts):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 10),

        ...canonicalFasts.map((fast) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.church, size: 20, color: Color(0xFF10B981)),
              ),
              title: Text(fast.nameAmharic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${fast.nameEnglish} • ${fast.totalDays} ቀናት',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fast.description,
                        style: TextStyle(fontSize: 12, height: 1.4, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ጠቅላላ ቀናት: ${fast.totalDays}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
