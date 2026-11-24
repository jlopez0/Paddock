import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/settings_screen.dart';
import 'package:paddock/core/consequences/consequences.dart';
import 'package:paddock/core/settings/settings_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester, Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  return c;
}

void main() {
  testWidgets('Puntos es el modo por defecto', (tester) async {
    final c = await _pump(tester, {});
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
    expect(find.text('Puntos'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
    expect(find.text('Sorbos'), findsOneWidget);
  });

  testWidgets('Retos se elige sin diálogo', (tester) async {
    final c = await _pump(tester, {});
    await tester.tap(find.text('Retos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.retos);
  });

  testWidgets('Sorbos pide confirmación +18; cancelar mantiene el modo anterior', (tester) async {
    final c = await _pump(tester, {});
    await tester.tap(find.text('Retos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sorbos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('Nadie está obligado a beber'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    final s = c.read(settingsProvider);
    expect(s.consequenceMode, ConsequenceMode.retos);
    expect(s.adultConfirmed, isFalse);
  });

  testWidgets('confirmar activa Sorbos, y la segunda vez no vuelve a preguntar', (tester) async {
    final c = await _pump(tester, {});
    await tester.tap(find.text('Sorbos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tengo 18 o más'));
    await tester.pumpAndSettle();
    var s = c.read(settingsProvider);
    expect(s.consequenceMode, ConsequenceMode.sorbos);
    expect(s.adultConfirmed, isTrue);

    await tester.tap(find.text('Puntos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sorbos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    s = c.read(settingsProvider);
    expect(s.consequenceMode, ConsequenceMode.sorbos);
  });
}
