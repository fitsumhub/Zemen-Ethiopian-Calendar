import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_time_converter.dart';
import '../../../core/calendar/geez_numeral.dart';
import '../../../core/world/world_country_engine.dart';

class TimeConverterTab extends StatefulWidget {
  const TimeConverterTab({super.key});

  @override
  State<TimeConverterTab> createState() => _TimeConverterTabState();
}

class _TimeConverterTabState extends State<TimeConverterTab> {
  bool _isLive = true;
  int _selectedGregHour = 12;
  int _selectedMinute = 0;
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _selectedGregHour = _now.hour;
    _selectedMinute = _now.minute;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isLive && mounted) {
        setState(() {
          _now = DateTime.now();
          _selectedGregHour = _now.hour;
          _selectedMinute = _now.minute;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ethTime = EthiopianTimeConverter.gregorianToEthiopian(_selectedGregHour, _selectedMinute);
    final worldCities = WorldCountryEngine.convertTime(_selectedGregHour, _selectedMinute);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Mode Toggle Header (Live vs Manual)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _isLive
                      ? '🟢 ቀጥታ ሰዓት (Live Clock)'
                      : '⏱️ በእጅ የተመረጠ ሰዓት (Manual)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: _isLive,
                onChanged: (val) {
                  setState(() {
                    _isLive = val;
                    if (val) {
                      _now = DateTime.now();
                      _selectedGregHour = _now.hour;
                      _selectedMinute = _now.minute;
                    }
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Main Dual Time Comparison Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Ethiopian Time Column
                    Expanded(
                      child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🇪🇹 የኢትዮጵያ ሰዓት', style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFF59E0B)),
                          ),
                        ),
                        Text(
                          '${ethTime.period.amharic} (${ethTime.isDaytime ? "ቀን" : "ሌሊት"})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'ግዕዝ: ${GeezNumeral.toGeez(ethTime.hour)} ሰዓት',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    ),
                    Container(height: 80, width: 1, color: theme.colorScheme.outlineVariant),
                    // Gregorian Standard Column
                    Expanded(
                      child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('🌍 ዓለም አቀፍ (24h)', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${_selectedGregHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
                          ),
                        ),
                        Text(
                          _selectedGregHour >= 12 ? 'ከሰዓት (PM)' : 'ጥዋት (AM)',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'EAT (UTC+3)',
                          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
                if (!_isLive) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('የግሪጎሪያን ሰዓት ይምረጡ: ${_selectedGregHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}'),
                  Slider(
                    value: _selectedGregHour.toDouble(),
                    min: 0,
                    max: 23,
                    divisions: 23,
                    label: '$_selectedGregHour:00',
                    onChanged: (val) => setState(() => _selectedGregHour = val.toInt()),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // World Cities Comparison
        const Text('የዓለም ከተሞች ሰዓት ንጽጽር (World Cities):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ...worldCities.take(8).map((city) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Text(city.flag, style: const TextStyle(fontSize: 24)),
              title: Text('${city.cityNameAmharic} (${city.cityNameEnglish})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('${city.countryName} • ${city.isBusinessHours ? "🟢 የሥራ ሰዓት" : "🔴 ዝግ"}', style: const TextStyle(fontSize: 11)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(city.formattedTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(city.formattedOffset, style: TextStyle(fontSize: 10, color: theme.colorScheme.primary)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
