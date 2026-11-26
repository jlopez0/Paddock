import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/players/players_controller.dart';
import 'package:habinson/core/players/players_screen.dart';
import 'package:habinson/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('playersLabel pluraliza', () {
    expect(playersLabel(1), '1 jugador');
    expect(playersLabel(2), '2 jugadores');
  });

  testWidgets('duplicado, vacío y deshacer al borrar', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PlayersScreen()),
      ),
    );

    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    expect(find.text('Escribe un nombre'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    expect(find.text('Ese nombre ya está en la cuadra'), findsOneWidget);
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

  testWidgets('"Hecho" del teclado añade y, con el campo vacío, cierra el teclado', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PlayersScreen()),
      ),
    );

    bool focused() =>
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus;

    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focused(), isTrue);

    // Con nombre: añade y mantiene el teclado para seguir apuntando.
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(container.read(playersProvider).length, 1);
    expect(focused(), isTrue);

    // Vacío: termina de añadir, sin error y sin teclado.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(focused(), isFalse);
    expect(find.text('Escribe un nombre'), findsNothing);
    expect(container.read(playersProvider).length, 1);
  });

  testWidgets('el contador del nombre cuenta letras, no jugadores', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PlayersScreen()),
      ),
    );
    expect(find.text('0/16 letras'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pump();
    expect(find.text('3/16 letras'), findsOneWidget);
    expect(find.text('3/16'), findsNothing);
  });

  testWidgets('tras un duplicado el texto queda seleccionado y se reemplaza', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PlayersScreen()),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.tap(find.byTooltip('Añadir'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(
      field.controller!.selection,
      const TextSelection(baseOffset: 0, extentOffset: 3),
    );
  });

  testWidgets('el aviso de retirada se descarta solo y al salir', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    container.read(playersProvider.notifier).add('Ana');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PlayersScreen()),
      ),
    );
    await tester.tap(find.byTooltip('Eliminar'));
    await tester.pump();
    expect(find.text('Ana se retira'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ana se retira'), findsNothing);
  });
}
