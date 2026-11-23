# -*- coding: utf-8 -*-
from pathlib import Path

p = Path("lib/features/calendar/calendar_home_screen.dart")
s = p.read_text(encoding="utf-8")

s = s.replace(
    "LocaleStrings.format('days_count', lang, {'count': '$days'})",
    "LocaleStrings.format('days_count', lang, params: {'count': '$days'})",
)

old = """  Future<void> _deleteEvent(EventEntity event) async {
    final notifier = ref.read(eventsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final isGreg = _isGregPrimary;
    await notifier.deleteEvent(event.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(LocaleStrings.get('event_deleted', lang)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: LocaleStrings.get('undo', lang),"""

new = """  Future<void> _deleteEvent(EventEntity event) async {
    final notifier = ref.read(eventsNotifierProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final lang = ref.read(currentAppLanguageProvider);
    await notifier.deleteEvent(event.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(LocaleStrings.get('event_deleted', lang)),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: LocaleStrings.get('undo', lang),"""

assert old in s, "_deleteEvent block missing"
s = s.replace(old, new)

s = s.replace(
    "            : ['S', 'M', 'T', 'W', 'T', 'F', 'S'])",
    """            : [
              DateText.weekdayInitial(7, lang),
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
            ])""",
)
s = s.replace(
    "            : ['M', 'T', 'W', 'T', 'F', 'S', 'S']);",
    """            : [
              DateText.weekdayInitial(1, lang),
              DateText.weekdayInitial(2, lang),
              DateText.weekdayInitial(3, lang),
              DateText.weekdayInitial(4, lang),
              DateText.weekdayInitial(5, lang),
              DateText.weekdayInitial(6, lang),
              DateText.weekdayInitial(7, lang),
            ]);""",
)

p.write_text(s, encoding="utf-8", newline="\n")
print("ok")
