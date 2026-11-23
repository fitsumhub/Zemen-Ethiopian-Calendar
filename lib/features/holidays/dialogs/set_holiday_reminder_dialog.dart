import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_time_converter.dart';
import '../../../core/holidays/holiday_engine.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';
import '../../../data/models/event_entity.dart';

class SetHolidayReminderDialog extends StatefulWidget {
  final Holiday holiday;
  final EventEntity? existingEvent;
  final AppLanguage currentLang;
  final VoidCallback onDismiss;
  final void Function(int alertHour, int alertMinute, bool remindOnEve, int reminderMinutesBefore) onSaveReminder;
  final VoidCallback onDeleteReminder;

  const SetHolidayReminderDialog({
    super.key,
    required this.holiday,
    this.existingEvent,
    this.currentLang = AppLanguage.amharic,
    required this.onDismiss,
    required this.onSaveReminder,
    required this.onDeleteReminder,
  });

  @override
  State<SetHolidayReminderDialog> createState() => _SetHolidayReminderDialogState();
}

class _SetHolidayReminderDialogState extends State<SetHolidayReminderDialog> {
  late bool _remindOnEve;
  late int _selectedHour;
  late int _selectedMinute;
  late int _reminderMinutesBefore;

  @override
  void initState() {
    super.initState();
    _remindOnEve = widget.existingEvent?.title.contains('[ዋዜማ') == true;
    _selectedHour = widget.existingEvent?.hour ?? 8;
    _selectedMinute = widget.existingEvent?.minute ?? 0;
    _reminderMinutesBefore = widget.existingEvent?.reminderMinutesBefore ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final holiday = widget.holiday;
    final dow = EthiopianCalendarEngine.getDayOfWeek(holiday.ethiopianDate);
    final monthName = LocaleStrings.getMonthName(holiday.ethiopianDate.month, widget.currentLang);
    final ethTime = EthiopianTimeConverter.gregorianToEthiopian(_selectedHour, _selectedMinute);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('የበዓል ማሳሰቢያ አዘጋጅ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: widget.onDismiss),
                ],
              ),
              const SizedBox(height: 10),

              // Holiday Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(holiday.titleAmharic, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '$dow፣ $monthName ${holiday.ethiopianDate.day}፣ ${holiday.ethiopianDate.year} ዓ.ም',
                            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Eve (ዋዜማ) Switch
              SwitchListTile(
                title: const Text('በዋዜማው ቀን ይደወል (Remind on Eve)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: const Text('ከበዓሉ አንድ ቀን ቀደም ብሎ ማሳሰቢያ ይሰጣል', style: TextStyle(fontSize: 11)),
                value: _remindOnEve,
                onChanged: (val) => setState(() => _remindOnEve = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),

              // Time picker trigger
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedHour = picked.hour;
                      _selectedMinute = picked.minute;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text('የማሳሰቢያ ሰዓት: ${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}'),
                        ],
                      ),
                      Text(
                        '${ethTime.period.amharic} ${ethTime.hour}:${ethTime.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Offset dropdown
              DropdownButtonFormField<int>(
                key: ValueKey('offset_$_reminderMinutesBefore'),
                initialValue: _reminderMinutesBefore,
                decoration: const InputDecoration(labelText: 'የማሳሰቢያ ቅድመ-ጊዜ (Offset)', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('በተጠቀሰው ሰዓት (At time)')),
                  DropdownMenuItem(value: 15, child: Text('ከ 15 ደቂቃ በፊት (15m before)')),
                  DropdownMenuItem(value: 30, child: Text('ከ 30 ደቂቃ በፊት (30m before)')),
                  DropdownMenuItem(value: 60, child: Text('ከ 1 ሰዓት በፊት (1 hour before)')),
                  DropdownMenuItem(value: 1440, child: Text('ከ 1 ቀን በፊት (1 day before)')),
                ],
                onChanged: (val) => setState(() => _reminderMinutesBefore = val ?? 0),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.existingEvent != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                      label: const Text('አጥፋ', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        widget.onDeleteReminder();
                        widget.onDismiss();
                      },
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton(onPressed: widget.onDismiss, child: const Text('ይቅር')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          widget.onSaveReminder(
                            _selectedHour,
                            _selectedMinute,
                            _remindOnEve,
                            _reminderMinutesBefore,
                          );
                          widget.onDismiss();
                        },
                        child: const Text('መዝግብ (Save)'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
