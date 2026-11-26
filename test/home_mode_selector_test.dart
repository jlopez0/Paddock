import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/home_screen.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/settings/settings_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Map<String, Object> prefsValues = const {},
  Size size = const Size(800, 3000),
  double textScale = 1.0,
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('home: Fichas y Retos siempre; Sorbos no sale sin adultConfirmed', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Fichas'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
    expect(find.text('Sorbos'), findsNothing);
    // Nada de beber en la primera pantalla.
    expect(find.textContaining('sorbo'), findsNothing);
    expect(find.textContaining('agua'), findsNothing);
    expect(find.text('Se juega por honor. Nadie cumple nada fuera de la app.'),
        findsOneWidget);
  });

  testWidgets('home: con adultConfirmed aparece Sorbos y pide el +18 solo si falta', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      prefsValues: {'settings.adultConfirmed.v1': true},
    );
    expect(find.text('Sorbos'), findsOneWidget);
    await tester.tap(find.text('Sorbos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.sorbos);
    expect(find.text('Opcional y solo +18. Hasta 3 por ronda · o agua o reto.'),
        findsOneWidget);
  });

  testWidgets('home: elegir Retos cambia el modo y su descripción', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Retos'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.retos);
    expect(find.text('Lo que pierdes se cumple con retos. Hasta 3 por ronda.'),
        findsOneWidget);
  });

  testWidgets('home: Sorbos guardado sin adultConfirmed se queda en Fichas', (
    tester,
  ) async {
    await _pump(
      tester,
      prefsValues: {'settings.consequenceMode.v1': 'sorbos'},
    );
    expect(find.text('Sorbos'), findsNothing);
    expect(find.textContaining('agua'), findsNothing);
  });

  testWidgets('home: orden de los carteles y sin Copa ni insignias', (tester) async {
    await _pump(tester);
    final titles = [
      'Carrera de caballos',
      '¿Quién es más probable?',
      'Yo nunca',
      'El Infiltrado',
      '¿Qué preferirías?',
      'Abecedario',
      'Trivia',
      'Geografía',
    ];
    expect([for (final g in gameModules) g.title], titles);
    final ys = [for (final t in titles) tester.getTopLeft(find.text(t)).dy];
    expect(ys, [...ys]..sort());
    expect(find.text('Copa de la noche'), findsNothing);
    expect(find.text('Ver Copa'), findsNothing);
    expect(find.textContaining('Cuentan'), findsNothing);
    expect(find.byTooltip('Copa de la noche'), findsOneWidget);
  });

  for (final adult in [false, true]) {
    testWidgets('home: sin desbordes con letra 2.0 en 320x568 (+18: $adult)', (
      tester,
    ) async {
      await _pump(
        tester,
        prefsValues: {if (adult) 'settings.adultConfirmed.v1': true},
        size: const Size(320, 568),
        textScale: 2.0,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Fichas'), findsOneWidget);
    });
  }
}
