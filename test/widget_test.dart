import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiocal/data/preferences/user_preferences_repository.dart';
import 'package:ethiocal/main.dart';

void main() {
  testWidgets('Zemen: Ethiopian Calendar smoke test and UI bootstrap', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'pref_onboarding_completed': true,
    });
    await UserPreferencesRepository.initialize();
    await tester.pumpWidget(const ProviderScope(child: EthioCalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsWidgets);
    expect(find.text('Converter'), findsWidgets);
  });
}
