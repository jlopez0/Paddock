import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/cup_screen.dart';
import 'package:paddock/app/home_screen.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/session/session_score.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 24, 22);

class _Env {
  _Env(this.c, this.shared);
  final ProviderContainer c;
  final List<String> shared;
}

Future<_Env> _pump(WidgetTester tester, Widget home, {bool withScores = true}) async {
  const ids = {'Ana': 'p1', 'Luis': 'p2', 'Eva': 'p3', 'Pepe': 'p4'};
  SharedPreferences.setMockInitialValues({
    'players.v1': jsonEncode([
      for (final e in ids.entries) {'id': e.value, 'name': e.key, 'color': ids.keys.toList().indexOf(e.key)},
    ]),
  });
  final prefs = await SharedPreferences.getInstance();
  final shared = <String>[];
  final c = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    sessionClockProvider.overrideWithValue(() => _now),
    shareTextProvider.overrideWithValue((text) async => shared.add(text)),
  ]);
  addTearDown(c.dispose);
  final (ana, luis, eva, pepe) = (ids['Ana']!, ids['Luis']!, ids['Eva']!, ids['Pepe']!);
  if (withScores) {
    final s = c.read(sessionProvider.notifier);
    s.award('r1', 'trivia', {ana: 5, luis: 3, eva: -2, pepe: 1});
    s.award('r2', 'carrera', {ana: -1, luis: 4, eva: 0});
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(home: home),
  ));
  await tester.pump(const Duration(seconds: 4));
  return _Env(c, shared);
}

void main() {
  test('cupShareText resume clasificación, perdedor y juegos', () {
    final s = Session.empty(_now)
        .withRound(roundId: 'r1', gameId: 'trivia', deltas: {'a': 5, 'b': 5, 'c': -2}, at: _now);
    final text = cupShareText(
      s,
      nameOf: (id) => {'a': 'Ana', 'b': 'Luis', 'c': 'Eva'}[id]!,
      titleOf: (id) => 'Trivia',
    );
    expect(text, startsWith('🏆 Copa de la noche · Paddock (24/11/2026)'));
    expect(text, contains('🥇 Ana: +5 fichas'));
    expect(text, contains('🥇 Luis: +5 fichas'));
    expect(text, contains('🥉 Eva: -2 fichas'));
    expect(text, contains('Va ganando: Ana, Luis'));
    expect(text, isNot(contains('Ganador')));
    expect(text, isNot(contains('http')));
    expect(text, contains('El que más ha perdido: Eva'));
    expect(text, contains('- Trivia (1 ronda): Ana, Luis'));
    expect(text.toLowerCase(), isNot(contains('alcohol')));
    final fin = cupShareText(s, nameOf: (id) => id, titleOf: (id) => id, finished: true);
    expect(fin, contains('Ganador: a, b'));
  });

  test('cupShareText con todos en negativo: lidera quien menos pierde', () {
    final s = Session.empty(_now)
        .withRound(roundId: 'r1', gameId: 'g', deltas: {'a': -2, 'b': -5, 'c': -2}, at: _now);
    final text = cupShareText(s, nameOf: (id) => id, titleOf: (id) => id);
    expect(text, contains('🥇 a: -2 fichas'));
    expect(text, contains('🥉 b: -5 fichas'));
    expect(text, contains('Va ganando: a, c'));
    expect(text, contains('El que más ha perdido: b'));
  });

  testWidgets('la pantalla muestra podio, clasificación y estadísticas', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, const CupScreen());
    // Ana 4, Luis 7, Pepe 1, Eva -2.
    expect(find.text('Luis'), findsWidgets);
    expect(find.text('+7 fichas'), findsNWidgets(2)); // podio + lista
    expect(find.text('-2 fichas'), findsOneWidget); // 4.ª: solo en la lista
    expect(find.text('Va ganando: Luis'), findsOneWidget);
    expect(find.text('Líder'), findsOneWidget);
    expect(find.text('Ganador'), findsNothing);
    expect(find.textContaining('va ganando quien más ha ganado'), findsOneWidget);
    expect(find.text('Clasificación'), findsOneWidget);
    expect(find.text('Por juego'), findsOneWidget);
    expect(find.text('El que más ha perdido'), findsOneWidget);
    expect(find.text('Nueva noche'), findsOneWidget);
  });

  testWidgets('estado vacío sin puntuaciones', (tester) async {
    await _pump(tester, const CupScreen(), withScores: false);
    expect(find.text('Todavía no hay puntuaciones'), findsOneWidget);
    expect(find.byTooltip('Compartir resultado'), findsNothing);
  });

  testWidgets('compartir envía el texto de la Copa', (tester) async {
    final env = await _pump(tester, const CupScreen());
    await tester.tap(find.byTooltip('Compartir resultado'));
    await tester.pump();
    expect(env.shared, hasLength(1));
    expect(env.shared.single, startsWith('🏆 Copa de la noche'));
    expect(env.shared.single, contains('Luis: +7 fichas'));
    expect(env.shared.single, contains('Paddock'));
    expect(env.shared.single, contains('24/11/2026'));
  });

  testWidgets('con letra 2.0 en 320x568 la Copa no desborda', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: const CupScreen(),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nueva noche pide confirmación y vacía la Copa', (tester) async {
    final env = await _pump(tester, const CupScreen());
    await tester.scrollUntilVisible(find.text('Nueva noche'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Nueva noche'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(env.c.read(sessionProvider).isEmpty, isFalse);

    await tester.tap(find.text('Nueva noche'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Nueva noche')));
    await tester.pumpAndSettle();
    expect(env.c.read(sessionProvider).isEmpty, isTrue);
    expect(find.text('Todavía no hay puntuaciones'), findsOneWidget);
  });

  testWidgets('la home muestra el top 3 solo si hay eventos', (tester) async {
    await _pump(tester, const HomeScreen());
    expect(find.text('Copa de la noche'), findsOneWidget);
    expect(find.text('Ver Copa'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('Pepe'), findsOneWidget);
    expect(find.text('Eva'), findsNothing); // 4.ª: fuera del top 3
  });

  testWidgets('la home oculta la tarjeta sin eventos', (tester) async {
    await _pump(tester, const HomeScreen(), withScores: false);
    expect(find.text('Copa de la noche'), findsNothing);
    expect(find.text('Ver Copa'), findsNothing);
  });
}
