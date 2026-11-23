# -*- coding: utf-8 -*-
from pathlib import Path

# e2e: 5 tabs, English month label
p = Path("test/e2e_app_journey_test.dart")
s = p.read_text(encoding="utf-8")
s = s.replace("for (var i = 0; i < 6; i++) {", "for (var i = 0; i < 5; i++) {")
s = s.replace("// Drag so target index is built/visible (6 tabs).", "// Drag so target index is built/visible (5 tabs).")
s = s.replace("expect(find.text('ወር'), findsWidgets);", "expect(find.text('Month'), findsWidgets);")
p.write_text(s, encoding="utf-8", newline="\n")
print("e2e ok")

# calendar_home_screen_test: English UI when language defaults to ENGLISH
p = Path("test/calendar_home_screen_test.dart")
s = p.read_text(encoding="utf-8")
s = s.replace(
    """      // View mode buttons are clean native Amharic without English suffixes
      expect(find.text('ወር'), findsOneWidget);
      expect(find.text('ሳምንት'), findsOneWidget);
      expect(find.text('ዓመት'), findsOneWidget);
      expect(find.text('ዕለት'), findsOneWidget);

      // Verify that duplicate "ዘመነ ዘመነ" does NOT exist anywhere on screen
      expect(find.textContaining('ዘመነ ዘመነ'), findsNothing);

      // Legend items are present as modern pill badges
      expect(find.text('መንግሥት'), findsOneWidget);
      expect(find.text('ባሕረ ሐሳብ'), findsOneWidget);
      expect(find.text('ማስታወሻ'), findsOneWidget);
      expect(find.text('ጾም'), findsOneWidget);
      expect(find.text('እስላማዊ'), findsOneWidget);

      // Verify no "Islamic≈" with raw tilde appears
      expect(find.text('Islamic≈'), findsNothing);

      // Verify clean native events & notes header is present without useless EN clutter
      expect(find.text('የዕለቱ ማስታወሻዎች'), findsOneWidget);
      expect(find.text('አክል'), findsOneWidget);

      // Verify useless English labels have been completely removed
      expect(find.text('SELECTED DAY'), findsNothing);
      expect(find.textContaining('(Regular Day)'), findsNothing);
      expect(find.textContaining('(Events & Notes)'), findsNothing);
      expect(find.textContaining('(Add)'), findsNothing);""",
    """      // View mode follows app language (English by default)
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Day'), findsOneWidget);

      // Verify that duplicate brand clutter does NOT exist
      expect(find.textContaining('ዘመነ ዘመነ'), findsNothing);

      // Legend items follow app language
      expect(find.text('Public holiday'), findsOneWidget);
      expect(find.text('Feast'), findsOneWidget);
      expect(find.text('Event'), findsOneWidget);
      expect(find.text('Fast'), findsOneWidget);
      expect(find.text('Islamic'), findsOneWidget);

      expect(find.text('Islamic≈'), findsNothing);

      expect(find.text('Events and notes'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);

      expect(find.text('SELECTED DAY'), findsNothing);
      expect(find.textContaining('(Regular Day)'), findsNothing);
      expect(find.textContaining('(Events & Notes)'), findsNothing);
      expect(find.textContaining('(Add)'), findsNothing);""",
)
p.write_text(s, encoding="utf-8", newline="\n")
print("home screen test ok")

p = Path("test/calendar_functional_test.dart")
s = p.read_text(encoding="utf-8")
s = s.replace(
    """      // Ethiopian-primary view switcher labels
      expect(find.text('ወር'), findsWidgets);
      expect(find.text('ሳምንት'), findsWidgets);
      expect(find.text('ዓመት'), findsWidgets);
      expect(find.text('ዕለት'), findsWidgets);

      // Legend
      expect(find.text('መንግሥት'), findsWidgets);
      expect(find.text('ባሕረ ሐሳብ'), findsWidgets);
      expect(find.text('ማስታወሻ'), findsWidgets);""",
    """      // View switcher + legend follow app language (English default)
      expect(find.text('Month'), findsWidgets);
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Year'), findsWidgets);
      expect(find.text('Day'), findsWidgets);

      expect(find.text('Public holiday'), findsWidgets);
      expect(find.text('Feast'), findsWidgets);
      expect(find.text('Event'), findsWidgets);""",
)
p.write_text(s, encoding="utf-8", newline="\n")
print("functional test ok")
