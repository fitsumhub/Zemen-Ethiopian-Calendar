import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/world/world_country_engine.dart';

class CountryComparatorTab extends StatefulWidget {
  const CountryComparatorTab({super.key});

  @override
  State<CountryComparatorTab> createState() => _CountryComparatorTabState();
}

class _CountryComparatorTabState extends State<CountryComparatorTab> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final allCities = WorldCountryEngine.convertTime(now.hour, now.minute);
    final todayEth = EthiopianCalendarEngine.todayEthiopian();
    final todayGreg = EthiopianCalendarEngine.todayGregorian();

    final filtered = allCities.where((c) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          c.cityNameAmharic.toLowerCase().contains(q) ||
          c.cityNameEnglish.toLowerCase().contains(q) ||
          c.countryName.toLowerCase().contains(q);
    }).toList();

    final europeanDetails = WorldCountryEngine.getEuropeanCalendarDetails(todayEth);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Multi-Calendar Overview Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('የቀን መቁጠሪያዎች ንጽጽር (Multi-Calendar)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(6)),
                      child: Text('ዛሬ', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _CalendarRow(name: '🇪🇹 የኢትዮጵያ (Ethiopian):', value: '${todayEth.day} ${todayEth.month}፣ ${todayEth.year} ዓ.ም'),
                _CalendarRow(name: '🌍 ጎርጎሪያን (Gregorian):', value: '${todayGreg.day}/${todayGreg.month}/${todayGreg.year} G.C.'),
                _CalendarRow(name: '🏛️ ጁሊያን (Julian):', value: '${europeanDetails.julianDate.day}/${europeanDetails.julianDate.month}/${europeanDetails.julianDate.year}'),
                _CalendarRow(name: '🇪🇬 ኮፕቲክ (Coptic):', value: '${europeanDetails.copticMonthName} ${europeanDetails.copticDay}፣ ${europeanDetails.copticYear} A.M.'),
                _CalendarRow(name: '☪️ ሂጅሪ (Islamic):', value: '${europeanDetails.hijriMonthName} ${europeanDetails.hijriDay}፣ ${europeanDetails.hijriYear} A.H.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Search Field
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'ሀገር ወይም ከተማ ይፈልጉ (Search City/Country)...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 12),

        // Countries list
        ...filtered.map((city) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Text(city.flag, style: const TextStyle(fontSize: 28)),
              title: Text(
                '${city.cityNameAmharic} (${city.cityNameEnglish})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${city.countryName} • ${city.isBusinessHours ? "🟢 የሥራ ሰዓት (Open)" : "🔴 ዝግ (Closed)"}',
                style: TextStyle(
                  fontSize: 11,
                  color: city.isBusinessHours ? const Color(0xFF10B981) : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(city.formattedTime, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(
                    city.formattedOffset,
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _CalendarRow extends StatelessWidget {
  final String name;
  final String value;

  const _CalendarRow({required this.name, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
