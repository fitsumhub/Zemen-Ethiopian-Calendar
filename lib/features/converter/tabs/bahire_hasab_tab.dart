import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/bahire_hasab.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';

class BahireHasabTab extends StatefulWidget {
  final AppLanguage currentLang;

  const BahireHasabTab({super.key, required this.currentLang});

  @override
  State<BahireHasabTab> createState() => _BahireHasabTabState();
}

class _BahireHasabTabState extends State<BahireHasabTab> {
  int _selectedYear = 2017;

  @override
  void initState() {
    super.initState();
    _selectedYear = EthiopianCalendarEngine.todayEthiopian().year;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final computus = BahireHasab.calculate(_selectedYear);
    final feasts = BahireHasab.getAllFeastsForYear(_selectedYear);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Year Stepper Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_double_arrow_left),
                      onPressed: () => setState(() => _selectedYear = (_selectedYear - 10).clamp(1, 9999)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _selectedYear = (_selectedYear - 1).clamp(1, 9999)),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '$_selectedYear ዓ.ም',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ወንጌላዊ: ${computus.evangelist}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _selectedYear = _selectedYear + 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_double_arrow_right),
                      onPressed: () => setState(() => _selectedYear = _selectedYear + 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Mathematical Computus Grid
        const Text('የቀመር መሠረቶች (Computus Properties):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _ComputusPropertyCard(title: 'ዓመተ ዓለም', value: '${computus.ameteAlem}'),
            _ComputusPropertyCard(title: 'መደብ', value: '${computus.medeb}'),
            _ComputusPropertyCard(title: 'ወንበር', value: '${computus.wenber}'),
            _ComputusPropertyCard(title: 'አበቅቴ', value: '${computus.abeqte}'),
            _ComputusPropertyCard(title: 'መጥቅዕ', value: '${computus.metqi}'),
            _ComputusPropertyCard(title: 'መባጃ ሐመር', value: '${computus.mebajaHamer}'),
          ],
        ),
        const SizedBox(height: 16),

        // 11 Movable Feasts & Fasts List
        const Text('ተንቀሳቃሽ አጽዋማት እና በዓላት (Movable Feasts):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...feasts.map((feast) {
          final gDate = EthiopianCalendarEngine.toGregorian(feast.ethiopianDate);
          final monthName = LocaleStrings.getMonthName(feast.ethiopianDate.month, widget.currentLang);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.church, size: 20, color: theme.colorScheme.primary),
              ),
              title: Text(feast.amharicName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '$monthName ${feast.ethiopianDate.day} (${feast.dayOfWeekName}) • ${gDate.day}/${gDate.month}/${gDate.year} G.C.',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                feast.englishName,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ComputusPropertyCard extends StatelessWidget {
  final String title;
  final String value;

  const _ComputusPropertyCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
