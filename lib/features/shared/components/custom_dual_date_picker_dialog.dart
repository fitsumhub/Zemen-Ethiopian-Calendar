import 'package:material_ui/material_ui.dart';
import '../../../core/calendar/ethiopian_calendar_engine.dart';
import '../../../core/calendar/ethiopian_date.dart';
import '../../../core/calendar/gregorian_date.dart';
import '../../../core/calendar/leap_year_calculator.dart';
import '../../../core/localization/app_language.dart';
import '../../../core/localization/locale_strings.dart';

class CustomDualDatePickerDialog extends StatefulWidget {
  final EthiopianDate initialDate;
  final String initialFormat; // "ETHIOPIAN" or "GREGORIAN"
  final EthiopianDate todayEthiopian;
  final AppLanguage currentLang;
  final bool isSundayFirst;
  final void Function(EthiopianDate selectedDate, String selectedFormat) onDateSelected;

  /// When true the picker renders as an inline card (Kotlin `CustomDualDatePicker`)
  /// instead of a modal dialog, and closes via [onDismiss] rather than Navigator.pop.
  final bool inline;
  final VoidCallback? onDismiss;

  const CustomDualDatePickerDialog({
    super.key,
    required this.initialDate,
    this.initialFormat = 'ETHIOPIAN',
    required this.todayEthiopian,
    this.currentLang = AppLanguage.amharic,
    this.isSundayFirst = true,
    required this.onDateSelected,
    this.inline = false,
    this.onDismiss,
  });

  @override
  State<CustomDualDatePickerDialog> createState() => _CustomDualDatePickerDialogState();
}

class _CustomDualDatePickerDialogState extends State<CustomDualDatePickerDialog> {
  late String _pickerFormat;
  late int _ethYear;
  late int _ethMonth;
  late int _ethDay;

  late int _gregYear;
  late int _gregMonth;
  late int _gregDay;

  @override
  void initState() {
    super.initState();
    _pickerFormat = widget.initialFormat;
    _ethYear = widget.initialDate.year;
    _ethMonth = widget.initialDate.month;
    _ethDay = widget.initialDate.day;

    final greg = EthiopianCalendarEngine.toGregorian(widget.initialDate);
    _gregYear = greg.year;
    _gregMonth = greg.month;
    _gregDay = greg.day;
  }

  void _syncEthToGreg() {
    final maxDays = EthiopianDate.daysInMonthFor(_ethYear, _ethMonth);
    if (_ethDay > maxDays) _ethDay = maxDays;
    final greg = EthiopianCalendarEngine.toGregorian(EthiopianDate(_ethYear, _ethMonth, _ethDay));
    _gregYear = greg.year;
    _gregMonth = greg.month;
    _gregDay = greg.day;
  }

  void _syncGregToEth() {
    final maxDays = _daysInGregMonth(_gregYear, _gregMonth);
    if (_gregDay > maxDays) _gregDay = maxDays;
    final eth = EthiopianCalendarEngine.toEthiopian(GregorianDate(_gregYear, _gregMonth, _gregDay));
    _ethYear = eth.year;
    _ethMonth = eth.month;
    _ethDay = eth.day;
  }

  int _daysInGregMonth(int year, int month) {
    switch (month) {
      case 1: case 3: case 5: case 7: case 8: case 10: case 12:
        return 31;
      case 4: case 6: case 9: case 11:
        return 30;
      case 2:
        return LeapYearCalculator.isGregorianLeapYear(year) ? 29 : 28;
      default:
        return 30;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEth = _pickerFormat == 'ETHIOPIAN';
    final theme = Theme.of(context);

    final titleMonth = isEth
        ? LocaleStrings.getMonthName(_ethMonth, widget.currentLang)
        : _gregMonthName(_gregMonth);
    final titleYear = isEth ? '$_ethYear ዓ.ም' : '$_gregYear G.C.';

    final currentEthDate = EthiopianDate(_ethYear, _ethMonth, _ethDay);
    final currentGregDate = GregorianDate(_gregYear, _gregMonth, _gregDay);

    return _wrap(
      theme,
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Format Switcher Header
              Row(
                children: [
                  Expanded(
                    child: _FormatToggleBtn(
                      title: '🇪🇹 የኢትዮጵያ (Eth)',
                      isSelected: isEth,
                      onTap: () {
                        setState(() {
                          _pickerFormat = 'ETHIOPIAN';
                          _syncGregToEth();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FormatToggleBtn(
                      title: '🌍 ጎርጎሪያን (Greg)',
                      isSelected: !isEth,
                      onTap: () {
                        setState(() {
                          _pickerFormat = 'GREGORIAN';
                          _syncEthToGreg();
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Month & Year Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        if (isEth) {
                          if (_ethMonth == 1) {
                            _ethMonth = 13;
                            _ethYear--;
                          } else {
                            _ethMonth--;
                          }
                          _syncEthToGreg();
                        } else {
                          if (_gregMonth == 1) {
                            _gregMonth = 12;
                            _gregYear--;
                          } else {
                            _gregMonth--;
                          }
                          _syncGregToEth();
                        }
                      });
                    },
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showMonthYearPicker(context, isEth),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Column(
                        children: [
                          Text(
                            titleMonth,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            titleYear,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        if (isEth) {
                          if (_ethMonth == 13) {
                            _ethMonth = 1;
                            _ethYear++;
                          } else {
                            _ethMonth++;
                          }
                          _syncEthToGreg();
                        } else {
                          if (_gregMonth == 12) {
                            _gregMonth = 1;
                            _gregYear++;
                          } else {
                            _gregMonth++;
                          }
                          _syncGregToEth();
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Weekday Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _buildWeekdayHeaders(widget.currentLang, widget.isSundayFirst),
              ),
              const SizedBox(height: 8),

              // 4. Days Grid
              SizedBox(
                height: 240,
                child: _buildDaysGrid(isEth, theme),
              ),
              const SizedBox(height: 12),

              // 5. Synchronized Dual Preview Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${LocaleStrings.getMonthName(currentEthDate.month, widget.currentLang)} ${currentEthDate.day}፣ ${currentEthDate.year} ዓ.ም',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.swap_horiz, size: 16),
                    Text(
                      '${_gregMonthName(currentGregDate.month)} ${currentGregDate.day}, ${currentGregDate.year} G.C.',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _close,
                    child: const Text('ይቅር (Cancel)'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      widget.onDateSelected(
                        EthiopianDate(_ethYear, _ethMonth, _ethDay),
                        _pickerFormat,
                      );
                      _close();
                    },
                    child: const Text('ምረጥ (Select)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    if (widget.inline) {
      widget.onDismiss?.call();
    } else {
      Navigator.of(context).pop();
      widget.onDismiss?.call();
    }
  }

  Widget _wrap(ThemeData theme, Widget child) {
    if (widget.inline) {
      return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        child: child,
      );
    }
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      backgroundColor: theme.colorScheme.surface,
      child: child,
    );
  }

  List<Widget> _buildWeekdayHeaders(AppLanguage lang, bool sundayFirst) {
    final days = sundayFirst
        ? [7, 1, 2, 3, 4, 5, 6]
        : [1, 2, 3, 4, 5, 6, 7];

    return days.map((d) {
      final text = LocaleStrings.getWeekdayShort(d, lang);
      return Expanded(
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDaysGrid(bool isEth, ThemeData theme) {
    final int daysCount = isEth
        ? EthiopianDate.daysInMonthFor(_ethYear, _ethMonth)
        : _daysInGregMonth(_gregYear, _gregMonth);

    // Calculate first day of month offset
    final int firstDayOfWeek = isEth
        ? EthiopianCalendarEngine.getDayOfWeek(EthiopianDate(_ethYear, _ethMonth, 1))
        : _getGregorianDayOfWeek(_gregYear, _gregMonth, 1);

    final int startOffset = widget.isSundayFirst
        ? (firstDayOfWeek == 7 ? 0 : firstDayOfWeek)
        : (firstDayOfWeek - 1);

    final totalCells = startOffset + daysCount;
    final rowCount = (totalCells / 7.0).ceil();

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rowCount * 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (context, index) {
        final day = index - startOffset + 1;
        if (day < 1 || day > daysCount) {
          return const SizedBox.shrink();
        }

        final isSelected = isEth ? (day == _ethDay) : (day == _gregDay);
        final isToday = isEth
            ? (_ethYear == widget.todayEthiopian.year &&
                _ethMonth == widget.todayEthiopian.month &&
                day == widget.todayEthiopian.day)
            : false;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (isEth) {
                _ethDay = day;
                _syncEthToGreg();
              } else {
                _gregDay = day;
                _syncGregToEth();
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary
                  : isToday
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _getGregorianDayOfWeek(int year, int month, int day) {
    final dt = DateTime(year, month, day);
    // In DateTime: 1 is Mon, 7 is Sun.
    return dt.weekday;
  }

  String _gregMonthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return (m >= 1 && m <= 12) ? names[m - 1] : '';
  }

  void _showMonthYearPicker(BuildContext context, bool isEth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEth ? 'ወር እና ዓመት ይምረጡ' : 'Select Month & Year',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Year selector row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setState(() {
                        if (isEth) {
                          _ethYear--;
                          _syncEthToGreg();
                        } else {
                          _gregYear--;
                          _syncGregToEth();
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  Text(
                    isEth ? '$_ethYear ዓ.ም' : '$_gregYear',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setState(() {
                        if (isEth) {
                          _ethYear++;
                          _syncEthToGreg();
                        } else {
                          _gregYear++;
                          _syncGregToEth();
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Month Wrap/Grid
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: List.generate(isEth ? 13 : 12, (i) {
                  final m = i + 1;
                  final name = isEth
                      ? LocaleStrings.getMonthName(m, widget.currentLang)
                      : _gregMonthName(m).substring(0, 3);
                  final isSelected = isEth ? (_ethMonth == m) : (_gregMonth == m);
                  return ActionChip(
                    label: Text(name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
                    onPressed: () {
                      setState(() {
                        if (isEth) {
                          _ethMonth = m;
                          _syncEthToGreg();
                        } else {
                          _gregMonth = m;
                          _syncGregToEth();
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormatToggleBtn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatToggleBtn({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
