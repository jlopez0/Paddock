import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/theme.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/geography/geo_store.dart';
import 'package:habinson/games/geography/ui/geo_result_screen.dart';
import 'package:habinson/games/trivia/trivia_data.dart';
import 'package:habinson/games/trivia/ui/trivia_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opción C (docs/research/ux_previa.md): Trivia y Geografía no suman a la Copa.
/// Los resultados muestran el escalón (Pleno, Gran carrera, En el podio) como titular,
/// sin "¿Quién ha jugado?" ni fichas, aunque haya jugadores en la cuadra.
void main() {
  final now = DateTime(2026, 11, 26, 22);

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget screen, {
    double scale = 1.0,
    Size size = const Size(400, 900),
  }) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
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
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
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

  void setTrivia(ProviderContainer c, {required int correct, int total = 10}) =>
      c
          .read(lastTriviaResultProvider.notifier)
          .set(
            TriviaResult(
              roundId: 'trivia-1',
              total: total,
              correct: correct,
              mistakes: const [],
            ),
          );

  void setGeo(ProviderContainer c, {required int correct, int total = 10}) => c
      .read(lastQuizResultProvider.notifier)
      .set(
        QuizResult(
          roundId: 'geografia-1',
          setup: const GeoSetup(),
          total: total,
          correct: correct,
          mistakes: const [],
          newRecord: false,
          best: correct,
        ),
      );

  void expectNoCup(WidgetTester tester, ProviderContainer c) {
    expect(find.text('¿Quién ha jugado?'), findsNothing);
    expect(find.textContaining('Anotar'), findsNothing);
    expect(find.textContaining('Copa'), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.textContaining('ficha'), findsNothing);
    expect(c.read(sessionProvider).isEmpty, isTrue);
  }

  group('Trivia', () {
    testWidgets('pleno con jugadores: titular sin fichas ni Copa', (
      tester,
    ) async {
      final c = await pump(tester, const TriviaResultScreen());
      setTrivia(c, correct: 10);
      await settle(tester);
      expect(find.text('Pleno'), findsOneWidget);
      expectNoCup(tester, c);
    });

    testWidgets('gran carrera y en el podio siguen siendo titular', (
      tester,
    ) async {
      final c = await pump(tester, const TriviaResultScreen());
      setTrivia(c, correct: 8);
      await settle(tester);
      expect(find.text('Gran carrera'), findsOneWidget);
      setTrivia(c, correct: 5);
      await settle(tester);
      expect(find.text('En el podio'), findsOneWidget);
      expectNoCup(tester, c);
    });

    testWidgets('letra al doble en 320x568 sin desbordes', (tester) async {
      final c = await pump(
        tester,
        const TriviaResultScreen(),
        scale: 2.0,
        size: const Size(320, 568),
      );
      setTrivia(c, correct: 10);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expectNoCup(tester, c);
    });
  });

  group('Geografía', () {
    testWidgets('pleno con jugadores: titular sin fichas ni Copa', (
      tester,
    ) async {
      final c = await pump(tester, const GeoResultScreen());
      setGeo(c, correct: 10);
      await settle(tester);
      expect(find.text('Pleno'), findsOneWidget);
      expectNoCup(tester, c);
    });

    testWidgets('letra al doble en 320x568 sin desbordes', (tester) async {
      final c = await pump(
        tester,
        const GeoResultScreen(),
        scale: 2.0,
        size: const Size(320, 568),
      );
      setGeo(c, correct: 9);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expectNoCup(tester, c);
    });
  });
}
