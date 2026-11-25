import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/theme.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/geography/geo_store.dart';
import 'package:paddock/games/geography/ui/geo_result_screen.dart';
import 'package:paddock/games/trivia/trivia_data.dart';
import 'package:paddock/games/trivia/ui/trivia_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "¿Quién ha jugado?" en los resultados de Trivia y Geografía: anota las
/// fichas de la vuelta en la Copa (regla en `QuizTier.chips`).
void main() {
  final now = DateTime(2026, 11, 25, 22);

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget screen, {
    bool withPlayers = true,
    double scale = 1.0,
    bool noAnimations = false,
    Size size = const Size(400, 900),
  }) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      if (withPlayers)
        'players.v1': jsonEncode([
          {'id': 'p1', 'name': 'Ana', 'color': 0},
          {'id': 'p2', 'name': 'Luis', 'color': 1},
        ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sessionClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(c.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(path: '/game/trivia/play', builder: (_, _) => const Scaffold()),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: noAnimations,
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return c;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  void setTrivia(
    ProviderContainer c, {
    required int correct,
    int total = 10,
    String roundId = 'trivia-1',
  }) => c
      .read(lastTriviaResultProvider.notifier)
      .set(
        TriviaResult(
          roundId: roundId,
          total: total,
          correct: correct,
          mistakes: const [],
        ),
      );

  void setGeo(
    ProviderContainer c, {
    required int correct,
    int total = 10,
    String roundId = 'geografia-1',
  }) => c
      .read(lastQuizResultProvider.notifier)
      .set(
        QuizResult(
          roundId: roundId,
          setup: const GeoSetup(),
          total: total,
          correct: correct,
          mistakes: const [],
          newRecord: false,
          best: correct,
        ),
      );

  FilledButton award(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const ValueKey('quiz-cup-award')));

  group('Trivia', () {
    testWidgets('sin jugadores no aparece nada de la Copa', (tester) async {
      final c = await pump(
        tester,
        const TriviaResultScreen(),
        withPlayers: false,
      );
      setTrivia(c, correct: 10);
      await settle(tester);
      expect(find.text('¿Quién ha jugado?'), findsNothing);
      expect(find.textContaining('Anotar'), findsNothing);
      expect(c.read(sessionProvider).isEmpty, isTrue);
    });

    testWidgets('pleno: elegir jugador y anotar suma 3 a la Copa', (
      tester,
    ) async {
      final c = await pump(tester, const TriviaResultScreen());
      setTrivia(c, correct: 10);
      await settle(tester);
      expect(find.text('¿Quién ha jugado?'), findsOneWidget);
      expect(find.text('Esta vuelta vale 3 fichas en la Copa'), findsOneWidget);
      // Sin elegir a nadie no se puede anotar.
      expect(award(tester).onPressed, isNull);
      expect(c.read(sessionProvider).isEmpty, isTrue);

      await tester.tap(find.byKey(const ValueKey('quiz-cup-p1')));
      await settle(tester);
      expect(award(tester).onPressed, isNotNull);
      await tester.tap(find.text('Anotar 3 fichas'));
      await settle(tester);

      final s = c.read(sessionProvider);
      expect(s.standings.single.playerId, 'p1');
      expect(s.standings.single.total, 3);
      expect(s.statsByGame.single.gameId, 'trivia');
      expect(find.text('Ana suma 3 fichas'), findsOneWidget);
      expect(find.text('Ya anotado en la Copa'), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-cup-award')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('una vuelta ya anotada no se anota otra vez al volver', (
      tester,
    ) async {
      final c = await pump(tester, const TriviaResultScreen());
      c.read(sessionProvider.notifier).award('trivia-1', 'trivia', {'p2': 2});
      setTrivia(c, correct: 8);
      await settle(tester);
      expect(find.text('Luis suma 2 fichas'), findsOneWidget);
      expect(find.byKey(const ValueKey('quiz-cup-award')), findsNothing);
      // Los chips quedan bloqueados.
      final chip = tester.widget<FilterChip>(
        find.byKey(const ValueKey('quiz-cup-p1')),
      );
      expect(chip.onSelected, isNull);
      expect(c.read(sessionProvider).standings.single.total, 2);
    });

    testWidgets('escalones: 80 % vale 2, 50 % vale 1', (tester) async {
      final c = await pump(tester, const TriviaResultScreen());
      setTrivia(c, correct: 8);
      await settle(tester);
      expect(find.text('Anotar 2 fichas'), findsOneWidget);
      setTrivia(c, correct: 5, roundId: 'trivia-2');
      await settle(tester);
      expect(find.text('Anotar 1 ficha'), findsOneWidget);
    });

    testWidgets('con menos de la mitad no suma ni deja anotar', (tester) async {
      final c = await pump(tester, const TriviaResultScreen());
      setTrivia(c, correct: 4);
      await settle(tester);
      expect(find.textContaining('no suma fichas'), findsOneWidget);
      expect(find.textContaining('Anotar'), findsNothing);
      expect(find.byKey(const ValueKey('quiz-cup-p1')), findsNothing);
    });

    for (final noAnim in [false, true]) {
      for (final anotada in [false, true]) {
        testWidgets('letra al doble en 320 de ancho sin desbordes '
            '(sin anim: $noAnim, anotada: $anotada)', (tester) async {
          final c = await pump(
            tester,
            const TriviaResultScreen(),
            scale: 2.0,
            size: const Size(320, 1800),
            noAnimations: noAnim,
          );
          if (anotada) {
            c.read(sessionProvider.notifier).award('trivia-1', 'trivia', {
              'p1': 3,
            });
          }
          setTrivia(c, correct: 10);
          await settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('¿Quién ha jugado?'), findsOneWidget);
        });
      }
    }
  });

  group('Geografía', () {
    testWidgets('sin jugadores el resultado va como siempre', (tester) async {
      final c = await pump(tester, const GeoResultScreen(), withPlayers: false);
      setGeo(c, correct: 10);
      await settle(tester);
      expect(find.text('¿Quién ha jugado?'), findsNothing);
      expect(c.read(sessionProvider).isEmpty, isTrue);
    });

    testWidgets('anota las fichas con el id del juego', (tester) async {
      final c = await pump(tester, const GeoResultScreen());
      setGeo(c, correct: 9);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('quiz-cup-p2')));
      await settle(tester);
      await tester.tap(find.text('Anotar 2 fichas'));
      await settle(tester);
      final s = c.read(sessionProvider);
      expect(s.statsByGame.single.gameId, 'geografia');
      expect(s.standings.single.playerId, 'p2');
      expect(s.standings.single.total, 2);
      expect(find.text('Luis suma 2 fichas'), findsOneWidget);
    });

    testWidgets('letra al doble en 320x568 sin desbordes', (tester) async {
      final c = await pump(
        tester,
        const GeoResultScreen(),
        scale: 2.0,
        size: const Size(320, 568),
      );
      setGeo(c, correct: 10);
      await settle(tester);
      await tester.scrollUntilVisible(find.text('¿Quién ha jugado?'), 200);
      expect(tester.takeException(), isNull);
      expect(find.text('¿Quién ha jugado?'), findsOneWidget);
    });
  });
}
