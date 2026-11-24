import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/players/players_controller.dart';
import 'package:paddock/core/players/players_screen.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('playersLabel pluraliza', () {
    expect(playersLabel(1), '1 jugador');
    expect(playersLabel(2), '2 jugadores');
  });

  testWidgets('duplicado, vacío y deshacer al borrar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PlayersScreen()),
    ));

    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    expect(find.text('Escribe un nombre'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    expect(find.text('Ya hay un jugador con ese nombre'), findsOneWidget);
    expect(container.read(playersProvider).length, 1);
    expect(find.text('0/16'), findsNothing);

    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pump();
    expect(container.read(playersProvider), isEmpty);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    expect(container.read(playersProvider).single.name, 'Ana');
  });
}
