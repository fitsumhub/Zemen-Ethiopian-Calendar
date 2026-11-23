import 'package:ethiocal/core/widgets/home_widget_engine.dart';
import 'package:ethiocal/core/widgets/widget_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all 14 kinds map to a theme family', () {
    for (final kind in HomeWidgetKind.values) {
      final family = WidgetTheme.familyForKind(kind);
      final palette = WidgetTheme.palette(kind: kind);
      expect(palette.family, family);
      expect(palette.gradient, isNotEmpty);
    }
  });

  test('four families resolve distinct palettes', () {
    final ids = WidgetThemeFamily.values
        .map((f) => WidgetTheme.paletteFor(f).canvas.toARGB32())
        .toSet();
    expect(ids.length, WidgetThemeFamily.values.length);
  });

  test('override family replaces canonical mapping', () {
    final p = WidgetTheme.palette(
      kind: HomeWidgetKind.basicDate,
      overrideFamily: WidgetThemeFamily.parchmentClassic,
    );
    expect(p.family, WidgetThemeFamily.parchmentClassic);
    expect(p.isLight, isTrue);
  });

  test('basic/classic default to coral studio product look', () {
    expect(
      WidgetTheme.familyForKind(HomeWidgetKind.basicDate),
      WidgetThemeFamily.coralStudio,
    );
    expect(
      WidgetTheme.familyForKind(HomeWidgetKind.classicDate),
      WidgetThemeFamily.coralStudio,
    );
    final p = WidgetTheme.palette(kind: HomeWidgetKind.basicDate);
    expect(p.isLight, isTrue);
    expect(p.dayNumeral, WidgetTheme.coral);
  });
}
