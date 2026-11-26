import 'dart:io';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/abecedario/ui/abecedario_play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habinson/games/abecedario/abecedario_data.dart';

void main() {
  final bank = parseAbecedario(File(abecedarioAsset).readAsStringSync());

  test('banco: ids únicos y al menos una definición por letra', () {
    expect(bank.map((e) => e.id).toSet().length, bank.length);
    for (final l in abecedarioLetters) {
      expect(bank.any((e) => e.letter == l), isTrue, reason: 'falta la $l');
    }
  });

  test('generar: una entrada por letra, en orden', () {
    final r = generateAbecedario(bank, Random(1));
    expect(r.map((e) => e.letter).toList(), abecedarioLetters);
  });

  test('niveles: cada nivel da un abecedario completo de ese nivel', () {
    for (final l in [
      AbecedarioLevel.easy,
      AbecedarioLevel.medium,
      AbecedarioLevel.hard,
    ]) {
      final r = generateAbecedario(bank, Random(3), level: l);
      expect(r.map((e) => e.letter).toList(), abecedarioLetters);
      expect(r.every((e) => e.level == l.key), isTrue, reason: l.label);
    }
  });

  test('pistas: "Comienza por la X" / "Contiene la X", sin marcas ajenas', () {
    AbecedarioEntry entry(String letter, {required bool contains}) =>
        AbecedarioEntry(
          id: 'x',
          letter: letter,
          contains: contains,
          answer: 'a',
          definition: 'd',
          level: 'facil',
        );
    expect(entry('B', contains: false).clue, 'Comienza por la B');
    expect(entry('X', contains: true).clue, 'Contiene la X');
    for (final e in bank) {
      expect(
        e.clue,
        e.contains ? 'Contiene la ${e.letter}' : 'Comienza por la ${e.letter}',
      );
      expect(e.clue.toLowerCase(), isNot(contains('rosco')));
      expect(e.clue.toLowerCase(), isNot(contains('pasapalabra')));
    }
  });

  testWidgets('partida: cuenta atrás, desvela, avanza solo y no desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'abecedario.setup.v1': '{"seconds":10,"auto":true,"read":3}',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AbecedarioPlayScreen()),
      ),
    );
    // La lectura del asset es E/S real (fuera del reloj simulado): se espera a que aparezca la partida.
    for (
      var i = 0;
      i < 40 && find.text('Desvelar ya').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Desvelar ya'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Siguiente'), findsOneWidget); // respuesta desvelada
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Desvelar ya'), findsOneWidget); // pasó sola a la B
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'fichas de letra y fin de partida: sin overflow con letra 2.0 en 320x568',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({
        'abecedario.setup.v1': '{"seconds":10,"auto":true,"read":3}',
      });
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            // El banco ya está leído: evita compartir el Future cacheado de rootBundle entre tests.
            abecedarioBankProvider.overrideWith((ref) async => bank),
          ],
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: const MaterialApp(home: AbecedarioPlayScreen()),
            ),
          ),
        ),
      );
      for (
        var i = 0;
        i < 200 && find.text('Desvelar ya').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 50));
      final ex = tester.takeException();
      expect(ex, isNull, reason: '$ex');
      expect(find.byType(LetterChip), findsNWidgets(27));

      // Toda la partida en automático hasta la pantalla de fin.
      for (var i = 0; i < abecedarioLetters.length; i++) {
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull, reason: 'letra $i');
      }
      await tester.pumpAndSettle();
      expect(find.text('Llegasteis a la Z'), findsOneWidget);
      expect(find.text('Otra vuelta'), findsOneWidget);
      expect(find.text('Otra vez'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  _marksTests();
}

// ---------------------------------------------------------------------------
// Aciertos y fallos: botones en la partida y resumen para aprender al final.
// ---------------------------------------------------------------------------

List<AbecedarioEntry> _fakeBank() => [
  for (final l in abecedarioLetters)
    AbecedarioEntry(
      id: 'f$l',
      letter: l,
      contains: false,
      answer: 'palabra$l',
      definition: 'def$l',
      level: 'facil',
    ),
];

Future<void> _pumpGame(
  WidgetTester tester, {
  Size size = const Size(720, 1400),
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'abecedario.setup.v1': '{"seconds":20,"auto":false,"read":5}',
  });
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/jugar',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('MENU'))),
      GoRoute(path: '/jugar', builder: (_, _) => const AbecedarioPlayScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        abecedarioBankProvider.overrideWith((ref) async => _fakeBank()),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  for (
    var i = 0;
    i < 200 && find.text('Desvelar ya').evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Desvelar ya'), findsOneWidget);
}

/// Juega las 27 letras en manual. `plan(i)` devuelve los toques de marca de la letra i
/// ("hit" o "miss") antes de pasar a la siguiente.
Future<void> _playAll(
  WidgetTester tester,
  List<String> Function(int i) plan,
) async {
  for (var i = 0; i < abecedarioLetters.length; i++) {
    await tester.tap(find.text('Desvelar ya'));
    await tester.pump(const Duration(milliseconds: 400));
    for (final m in plan(i)) {
      await tester.tap(find.byTooltip(m == 'hit' ? 'Acierto' : 'Fallo'));
      await tester.pump();
    }
    await tester.tap(
      find.text(i == abecedarioLetters.length - 1 ? 'Terminar' : 'Siguiente'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

Finder _statValue(String key, String value) =>
    find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(value));

void _marksTests() {
  testWidgets('botones de acierto y fallo: solo tras desvelar, con tooltip', (
    tester,
  ) async {
    await _pumpGame(tester);
    expect(find.byTooltip('Acierto'), findsNothing);
    expect(find.byTooltip('Fallo'), findsNothing);
    await tester.tap(find.text('Desvelar ya'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Acierto'), findsOneWidget);
    expect(find.byTooltip('Fallo'), findsOneWidget);
    expect(find.text('Siguiente'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resumen: recuento, falladas con su respuesta y lista por letra', (
    tester,
  ) async {
    await _pumpGame(tester);
    // A acierto; B fallo; C acierto y vuelve a pulsar (se quita); D fallo y cambia a
    // acierto; E fallo; el resto sin marcar.
    await _playAll(
      tester,
      (i) => switch (i) {
        0 => ['hit'],
        1 => ['miss'],
        2 => ['hit', 'hit'],
        3 => ['miss', 'hit'],
        4 => ['miss'],
        _ => [],
      },
    );
    expect(find.text('Llegasteis a la Z'), findsOneWidget);
    expect(_statValue('stat-hits', '2'), findsOneWidget);
    expect(_statValue('stat-misses', '2'), findsOneWidget);
    expect(_statValue('stat-unmarked', '23'), findsOneWidget);
    expect(find.text('Para repasar'), findsOneWidget);
    // Las falladas (B y E) salen destacadas con su respuesta correcta; las acertadas, no.
    expect(find.text('PALABRAB'), findsOneWidget);
    expect(find.text('PALABRAE'), findsOneWidget);
    expect(find.text('PALABRAA'), findsNothing);
    expect(find.text('defB'), findsOneWidget);
    expect(find.text('defA'), findsNothing);
    // Lista de todas las letras: una fila por letra, con su resultado en la semántica.
    expect(find.text('Todas las letras'), findsOneWidget);
    expect(find.text('palabraA'), findsOneWidget);
    expect(find.text('palabraZ'), findsOneWidget);
    expect(find.bySemanticsLabel('A: palabraA, acertada'), findsOneWidget);
    expect(find.bySemanticsLabel('B: palabraB, fallada'), findsOneWidget);
    expect(find.bySemanticsLabel('C: palabraC, sin marcar'), findsOneWidget);
    expect(find.bySemanticsLabel('D: palabraD, acertada'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resumen sin marcar nada: avisa en vez de listar', (tester) async {
    await _pumpGame(tester);
    await _playAll(tester, (_) => []);
    expect(find.byKey(const ValueKey('review-empty')), findsOneWidget);
    expect(find.text('Para repasar'), findsNothing);
    expect(_statValue('stat-hits', '0'), findsOneWidget);
    expect(_statValue('stat-misses', '0'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-unmarked')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('resumen sin fallos: nada que repasar', (tester) async {
    await _pumpGame(tester);
    await _playAll(tester, (_) => ['hit']);
    expect(find.byKey(const ValueKey('review-no-misses')), findsOneWidget);
    expect(_statValue('stat-hits', '27'), findsOneWidget);
    expect(find.byKey(const ValueKey('stat-unmarked')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Otra vuelta reinicia el registro de marcas', (tester) async {
    await _pumpGame(tester);
    await _playAll(tester, (_) => ['miss']);
    expect(_statValue('stat-misses', '27'), findsOneWidget);
    await tester.tap(find.text('Otra vuelta'));
    await tester.pump(const Duration(milliseconds: 100));
    await _playAll(tester, (_) => []);
    expect(find.byKey(const ValueKey('review-empty')), findsOneWidget);
    expect(_statValue('stat-misses', '0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('fin de partida: Menú vuelve a la raíz', (tester) async {
    await _pumpGame(tester);
    await _playAll(tester, (_) => []);
    await tester.tap(find.text('Menú'));
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('salir en mitad de la partida pide confirmación y va a la raíz', (
    tester,
  ) async {
    await _pumpGame(tester);
    await tester.tap(find.byTooltip('Salir'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    await tester.tap(find.text('Salir').last);
    await tester.pumpAndSettle();
    expect(find.text('MENU'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('botones y resumen: sin desbordes con letra 2.0 en 320x568', (
    tester,
  ) async {
    await _pumpGame(tester, size: const Size(320, 568), textScale: 2.0);
    await tester.tap(find.text('Desvelar ya'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.byTooltip('Fallo'), findsOneWidget);
    await tester.tap(find.byTooltip('Fallo'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pump(const Duration(milliseconds: 100));
    for (var i = 1; i < abecedarioLetters.length; i++) {
      await tester.tap(find.text('Desvelar ya'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byTooltip(i.isEven ? 'Fallo' : 'Acierto'));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'letra $i');
      await tester.tap(
        find.text(i == abecedarioLetters.length - 1 ? 'Terminar' : 'Siguiente'),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.text('Llegasteis a la Z'), findsOneWidget);
    expect(find.text('Otra vuelta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
