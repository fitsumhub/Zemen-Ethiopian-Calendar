import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/share_helper.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/calendar/ethiopian_season.dart';
import '../../../core/calendar/geez_numeral.dart';
import '../../../core/calendar/gregorian_date.dart';
import '../../../core/calendar/leap_year_calculator.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';

class DateConverterTab extends StatefulWidget {
  final AppLanguage currentLang;
  final ValueChanged<EthiopianDate>? onNavigateToCalendar;

  const DateConverterTab({
    super.key,
    required this.currentLang,
    this.onNavigateToCalendar,
  });

  @override
  State<DateConverterTab> createState() => _DateConverterTabState();
}

class _DateConverterTabState extends State<DateConverterTab> {
  bool _isEthToGreg = true;

  // Ethiopian Inputs
  int _ethYear = 2017;
  int _ethMonth = 1;
  int _ethDay = 1;

  // Gregorian Inputs
  int _gregYear = 2024;
  int _gregMonth = 9;
  int _gregDay = 11;

  @override
  void initState() {
    super.initState();
    final todayEth = EthiopianCalendarEngine.todayEthiopian();
    final todayGreg = EthiopianCalendarEngine.todayGregorian();
    _ethYear = todayEth.year;
    _ethMonth = todayEth.month;
    _ethDay = todayEth.day;
    _gregYear = todayGreg.year;
    _gregMonth = todayGreg.month;
    _gregDay = todayGreg.day;
  }

  void _swapDirection() {
    setState(() {
      _isEthToGreg = !_isEthToGreg;
      if (_isEthToGreg) {
        // Sync Eth from current Greg
        final eth = EthiopianCalendarEngine.toEthiopian(GregorianDate(_gregYear, _gregMonth, _gregDay));
        _ethYear = eth.year;
        _ethMonth = eth.month;
        _ethDay = eth.day;
      } else {
        // Sync Greg from current Eth
        final greg = EthiopianCalendarEngine.toGregorian(EthiopianDate(_ethYear, _ethMonth, _ethDay));
        _gregYear = greg.year;
        _gregMonth = greg.month;
        _gregDay = greg.day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxEthDays = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
    if (_ethDay > maxEthDays) _ethDay = maxEthDays;

    final convertedGreg = EthiopianCalendarEngine.toGregorian(EthiopianDate(_ethYear, _ethMonth, _ethDay));
    final convertedEth = EthiopianCalendarEngine.toEthiopian(GregorianDate(_gregYear, _gregMonth, _gregDay));

    final ethSeason = EthiopianSeason.fromMonth(_isEthToGreg ? _ethMonth : convertedEth.month);
    final evangelist = LeapYearCalculator.getEvangelist(_isEthToGreg ? _ethYear : convertedEth.year);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Direction Header with Swap Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isEthToGreg
                    ? '🇪🇹 ኢትዮጵያ ➔ 🌍 ፈረንጅ (Eth ➔ Greg)'
                    : '🌍 ፈረንጅ ➔ 🇪🇹 ኢትዮጵያ (Greg ➔ Eth)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.swap_vert, size: 20),
                onPressed: _swapDirection,
                tooltip: 'አቅጣጫ ቀይር (Swap)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Input Selector Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEthToGreg ? 'የኢትዮጵያ ቀን ይምረጡ:' : 'የፈረንጅ ቀን ይምረጡ:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 12),
              if (_isEthToGreg) ...[
                // Ethiopian Pickers (Month, Day, Year)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('ethMonth_$_ethMonth'),
                        initialValue: _ethMonth,
                        decoration: const InputDecoration(labelText: 'ወር', border: OutlineInputBorder()),
                        items: List.generate(13, (i) => i + 1).map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text(LocaleStrings.getMonthName(m, widget.currentLang), style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _ethMonth = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('ethDay_$_ethDay'),
                        initialValue: _ethDay,
                        decoration: const InputDecoration(labelText: 'ቀን', border: OutlineInputBorder()),
                        items: List.generate(maxEthDays, (i) => i + 1).map((d) {
                          return DropdownMenuItem(
                            value: d,
                            child: Text('$d', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _ethDay = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('ethYear_$_ethYear'),
                        initialValue: _ethYear,
                        decoration: const InputDecoration(labelText: 'ዓመት', border: OutlineInputBorder()),
                        items: List.generate(20, (i) => _ethYear - 10 + i).map((y) {
                          return DropdownMenuItem(
                            value: y,
                            child: Text('$y', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _ethYear = val ?? 2017),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Gregorian Pickers (Month, Day, Year)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('gregMonth_$_gregMonth'),
                        initialValue: _gregMonth,
                        decoration: const InputDecoration(labelText: 'Month', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('January')),
                          DropdownMenuItem(value: 2, child: Text('February')),
                          DropdownMenuItem(value: 3, child: Text('March')),
                          DropdownMenuItem(value: 4, child: Text('April')),
                          DropdownMenuItem(value: 5, child: Text('May')),
                          DropdownMenuItem(value: 6, child: Text('June')),
                          DropdownMenuItem(value: 7, child: Text('July')),
                          DropdownMenuItem(value: 8, child: Text('August')),
                          DropdownMenuItem(value: 9, child: Text('September')),
                          DropdownMenuItem(value: 10, child: Text('October')),
                          DropdownMenuItem(value: 11, child: Text('November')),
                          DropdownMenuItem(value: 12, child: Text('December')),
                        ],
                        onChanged: (val) => setState(() => _gregMonth = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('gregDay_$_gregDay'),
                        initialValue: _gregDay,
                        decoration: const InputDecoration(labelText: 'Day', border: OutlineInputBorder()),
                        items: List.generate(31, (i) => i + 1).map((d) {
                          return DropdownMenuItem(value: d, child: Text('$d'));
                        }).toList(),
                        onChanged: (val) => setState(() => _gregDay = val ?? 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey('gregYear_$_gregYear'),
                        initialValue: _gregYear,
                        decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
                        items: List.generate(20, (i) => _gregYear - 10 + i).map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y'));
                        }).toList(),
                        onChanged: (val) => setState(() => _gregYear = val ?? 2024),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Conversion Result Display Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEthToGreg ? 'የተቀየረበት የፈረንጅ ቀን (G.C.)' : 'የተቀየረበት የኢትዮጵያ ቀን (ዓ.ም)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        evangelist.amharicName,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_isEthToGreg) ...[
                  Text(
                    '${_weekdayNameFromGreg(convertedGreg)}፣ ${convertedGreg.day} ${_monthNameGreg(convertedGreg.month)} ${convertedGreg.year} G.C.',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ISO: ${convertedGreg.year}-${convertedGreg.month.toString().padLeft(2, '0')}-${convertedGreg.day.toString().padLeft(2, '0')} • ወቅት: ${ethSeason.amharicName}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ] else ...[
                  Text(
                    '${LocaleStrings.getWeekdayLong(EthiopianCalendarEngine.getDayOfWeek(convertedEth), widget.currentLang)}፣ ${convertedEth.day} ${LocaleStrings.getMonthName(convertedEth.month, widget.currentLang)} ${convertedEth.year} ዓ.ም',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ግዕዝ አኃዝ: ${GeezNumeral.toGeez(convertedEth.day)}/${GeezNumeral.toGeez(convertedEth.month)}/${GeezNumeral.toGeez(convertedEth.year)} ዓ.ም',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'የዕለቱ ጽላት: ${HolidayEngine.monthlySaints.firstWhere((s) => s.day == convertedEth.day).nameAmharic}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.secondary, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: 16),

                // Action buttons (Copy, Share, View on Calendar)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('ኮፒ (Copy)'),
                        onPressed: () {
                          final text = _isEthToGreg
                              ? '${convertedGreg.day}/${convertedGreg.month}/${convertedGreg.year} G.C.'
                              : '${convertedEth.day} ${LocaleStrings.getMonthName(convertedEth.month, widget.currentLang)} ${convertedEth.year} ዓ.ም';
                          Clipboard.setData(ClipboardData(text: text));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ቀኑ ኮፒ ተደርጓል')));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('አጋራ'),
                        onPressed: () {
                          final text = _isEthToGreg
                              ? '🇪🇹 $_ethDay ${LocaleStrings.getMonthName(_ethMonth, widget.currentLang)} $_ethYear ዓ.ም ➔ 🌍 ${convertedGreg.day}/${convertedGreg.month}/${convertedGreg.year} G.C.'
                              : '🌍 $_gregDay/$_gregMonth/$_gregYear G.C. ➔ 🇪🇹 ${convertedEth.day} ${LocaleStrings.getMonthName(convertedEth.month, widget.currentLang)} ${convertedEth.year} ዓ.ም';
                          ShareHelper.share('$text\n\n— ከኢትዮጵያ ካላንደር (Zemen: Ethiopian Calendar)');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.calendar_month, size: 20),
                      tooltip: 'በካላንደር እይ',
                      onPressed: () {
                        final target = _isEthToGreg ? EthiopianDate(_ethYear, _ethMonth, _ethDay) : convertedEth;
                        widget.onNavigateToCalendar?.call(target);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _weekdayNameFromGreg(GregorianDate g) {
    final dt = DateTime(g.year, g.month, g.day);
    const names = ['ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'ዓርብ', 'ቅዳሜ', 'እሑድ'];
    return names[dt.weekday - 1];
  }

  String _monthNameGreg(int m) {
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return (m >= 1 && m <= 12) ? names[m - 1] : '';
  }
}
