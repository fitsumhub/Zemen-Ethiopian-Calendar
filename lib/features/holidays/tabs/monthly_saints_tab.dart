import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/calendar/geez_numeral.dart';
import '../../../core/holidays/holiday_engine.dart';

class MonthlySaintsTab extends StatefulWidget {
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const MonthlySaintsTab({super.key, this.onNavigateToCalendar});

  @override
  State<MonthlySaintsTab> createState() => _MonthlySaintsTabState();
}

class _MonthlySaintsTabState extends State<MonthlySaintsTab> {
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayEth = EthiopianCalendarEngine.todayEthiopian();
    final saints = HolidayEngine.monthlySaints;

    final filtered = saints.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          s.nameAmharic.toLowerCase().contains(q) ||
          s.nameEnglish.toLowerCase().contains(q) ||
          s.day.toString() == q;
    }).toList();

    return Column(
      children: [
        // Search Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'ጽላቶችን በስም ወይም በቀን ይፈልጉ (Search Saints 1-30)...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
          ),
        ),

        // 1 to 30 Saints List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final saint = filtered[index];
              final isToday = saint.day == todayEth.day;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: isToday ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isToday
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${saint.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          GeezNumeral.toGeez(saint.day),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isToday ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          saint.nameAmharic,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      if (isToday)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('የዛሬ ጽላት', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${saint.nameEnglish} • ${saint.description}',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month, size: 20),
                    tooltip: 'በካላንደር እይ',
                    onPressed: () {
                      final targetDate = EthiopianDate(todayEth.year, todayEth.month, saint.day);
                      widget.onNavigateToCalendar?.call(targetDate);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
