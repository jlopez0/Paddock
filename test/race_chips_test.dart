import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/core/consequences/consequences.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/horse_race/domain/bets.dart';
import 'package:paddock/games/horse_race/domain/cards.dart';
import 'package:paddock/games/horse_race/race_result.dart';
import 'package:paddock/games/horse_race/race_store.dart';
import 'package:paddock/games/horse_race/race_texts.dart';
import 'package:paddock/games/horse_race/ui/race_result_screen.dart';
import 'package:paddock/games/horse_race/ui/race_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 24, 22);

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs), sessionClockProvider.overrideWithValue(() => _now)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('migración de race.setup.v1', () {
    test('lee el formato antiguo: sips 8 se recorta a 5 y sips 0 pasa a All-in', () async {
      final c = await _container({
        'race.setup.v1': jsonEncode({
          'settings': {'length': 6, 'obstacles': true, 'double': false, 'music': true},
          'bets': [
            {'player': 'a', 'suit': 'oros', 'sips': 8},
            {'player': 'b', 'suit': 'copas', 'sips': 0},
            {'player': 'c', 'suit': 'bastos', 'sips': 3},
          ],
        }),
      });
      final bets = c.read(raceSetupProvider).bets;
      expect(bets.map((b) => b.chips), [5, Bet.allIn, 3]);
      expect(bets[1].isAllIn, isTrue);
    });

    test('al guardar escribe fichas y se vuelve a leer igual', () async {
      final c = await _container({});
      c.read(raceSetupProvider.notifier).setBets(const [
        Bet(playerId: 'a', suit: Suit.oros, chips: 4),
        Bet(playerId: 'b', suit: Suit.copas, chips: Bet.allIn),
      ]);
      final raw = jsonDecode(c.read(sharedPreferencesProvider).getString('race.setup.v1')!) as Map;
      expect((raw['bets'] as List).first, containsPair('chips', 4));
      final c2 = await _container({'race.setup.v1': jsonEncode(raw)});
      expect(c2.read(raceSetupProvider).bets.map((b) => b.chips), [4, Bet.allIn]);
    });

    test('datos raros no tumban la app', () async {
      for (final raw in ['no es json', '{"settings": 3}', '{"settings": {}, "bets": [{"player": 1}]}']) {
        final c = await _container({'race.setup.v1': raw});
        expect(c.read(raceSetupProvider).bets, isEmpty);
      }
      final c = await _container({
        'race.setup.v1': jsonEncode({
          'settings': <String, dynamic>{},
          'bets': [
            {'player': 'a', 'suit': 'oros', 'sips': -4},
            {'player': 'b', 'suit': 'oros', 'sips': 99},
          ],
        }),
      });
      expect(c.read(raceSetupProvider).bets.map((b) => b.chips), [1, 5]);
    });

    test('las estadísticas antiguas (claves d y g) se leen como fichas', () async {
      final c = await _container({
        'race.stats.v1': jsonEncode({
          'players': {
            'a': {'r': 4, 'h': 2, 'd': 11, 'g': 7},
          },
          'suits': {'oros': 4},
        }),
      });
      final s = c.read(raceStatsProvider).byPlayer['a']!;
      expect([s.chipsLost, s.chipsWon], [11, 7]);
      expect(s.toJson(), {'r': 4, 'h': 2, 'd': 11, 'g': 7});
    });
  });

  group('settleChips', () {
    test('apuestas normales: ganar suma, perder resta', () {
      final outcomes = settleBets(
        const [Bet(playerId: 'a', suit: Suit.copas, chips: 3), Bet(playerId: 'b', suit: Suit.oros, chips: 5)],
        Suit.copas,
        winMultiplier: 2,
      );
      final s = settleChips(outcomes, const {});
      expect(s.deltas, {'a': 6, 'b': -5});
      expect(s.losses, {'b': 5});
    });

    test('All-in ganador: 2 personas distintas pagan 10 y él gana 20', () {
      final outcomes = settleBets(const [Bet(playerId: 'a', suit: Suit.copas, chips: Bet.allIn)], Suit.copas);
      final s = settleChips(outcomes, {
        'a': {'b', 'c'},
      });
      expect(s.deltas, {'a': 2 * kAllInChips, 'b': -kAllInChips, 'c': -kAllInChips});
      expect(s.losses, {'b': kAllInChips, 'c': kAllInChips});
    });

    test('All-in ganador: ignora a sí mismo y lo que pase de 2', () {
      final outcomes = settleBets(const [Bet(playerId: 'a', suit: Suit.copas, chips: Bet.allIn)], Suit.copas);
      final s = settleChips(outcomes, {
        'a': {'a', 'b', 'c', 'd'},
      });
      expect(s.deltas['a'], 2 * kAllInChips); // a queda fuera; cuentan b y c (tope de 2)
      expect(s.deltas.keys.toSet(), {'a', 'b', 'c'});
    });

    test('All-in con menos de 3 jugadores reparte a los que haya', () {
      expect(allInTargetCount(0), 0);
      expect(allInTargetCount(1), 1);
      expect(allInTargetCount(2), 2);
      expect(allInTargetCount(5), 2);
      final outcomes = settleBets(const [Bet(playerId: 'a', suit: Suit.copas, chips: Bet.allIn)], Suit.copas);
      final s = settleChips(outcomes, {
        'a': {'b'},
      });
      expect(s.deltas, {'a': kAllInChips, 'b': -kAllInChips});
      expect(settleChips(outcomes, const {}).deltas, {'a': 0});
    });

    test('All-in perdedor paga 10; en retos y sorbos el tope lo limita', () {
      final outcomes = settleBets(const [Bet(playerId: 'a', suit: Suit.oros, chips: Bet.allIn)], Suit.copas);
      final s = settleChips(outcomes, const {});
      expect(s.losses['a'], kAllInChips);
      expect(resolveLoss(s.losses['a']!, ConsequenceMode.puntos).amount, 10);
      expect(resolveLoss(s.losses['a']!, ConsequenceMode.retos).amount, kRoundCap);
      expect(resolveLoss(s.losses['a']!, ConsequenceMode.sorbos).amount, kRoundCap);
    });

    test('quien pierde y además recibe un All-in suma ambas pérdidas', () {
      final outcomes = settleBets(const [
        Bet(playerId: 'a', suit: Suit.copas, chips: Bet.allIn),
        Bet(playerId: 'b', suit: Suit.oros, chips: 2),
      ], Suit.copas);
      final s = settleChips(outcomes, {
        'a': {'b', 'c'},
      });
      expect(s.losses['b'], 2 + kAllInChips);
      expect(s.deltas['b'], -(2 + kAllInChips));
    });
  });

  group('pantalla de resultado', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      required List<Bet> bets,
      int players = 4,
      String mode = 'puntos',
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const names = ['Ana', 'Luis', 'Eva', 'Pepe'];
      final c = await _container({
        'settings.consequenceMode.v1': mode,
        'settings.adultConfirmed.v1': true,
        'players.v1': jsonEncode([
          for (var i = 0; i < players; i++) {'id': 'p$i', 'name': names[i], 'color': i},
        ]),
      });
      c
          .read(lastRaceResultProvider.notifier)
          .set(
            RaceResult(
              roundId: 'carrera-1',
              winner: Suit.copas,
              standings: Suit.values,
              outcomes: settleBets(bets, Suit.copas),
              draws: 12,
            ),
          );
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const RaceResultScreen()),
          GoRoute(
            path: '/game/carrera',
            builder: (_, _) => const Scaffold(body: Text('setup')),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      return c;
    }

    testWidgets('sin All-in: manda las fichas a la Copa una sola vez y muestra el banner', (tester) async {
      final c = await pump(
        tester,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
          Bet(playerId: 'p1', suit: Suit.oros, chips: 2),
        ],
      );
      expect(find.text('−2 en la Copa'), findsOneWidget);
      expect(find.text('Ana gana 3 fichas'), findsOneWidget);
      expect(find.text('Ganan: Ana (+3)'), findsOneWidget);
      expect(find.text('Pagan: Luis (−2)'), findsOneWidget);
      expect(find.text('Apostó 2 fichas a Oros y falló'), findsOneWidget);
      final events = c.read(sessionProvider).events;
      expect(events.map((e) => (e.playerId, e.delta)).toSet(), {('p0', 3), ('p1', -2)});
      // Registrar otra vez la misma ronda no duplica.
      expect(c.read(sessionProvider.notifier).award('carrera-1', 'carrera', {'p0': 3}), isFalse);
      expect(c.read(sessionProvider).events, hasLength(2));
    });

    testWidgets('All-in ganador: elige 2 personas distintas y las fichas pasan al salir', (tester) async {
      final c = await pump(
        tester,
        bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn)],
      );
      expect(c.read(sessionProvider).events, isEmpty); // espera a la elección
      expect(find.textContaining('Reparte 2 All-in a 2 personas distintas (0/2)'), findsOneWidget);
      expect(find.text('Ana reparte 2 All-in'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Luis'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Eva'));
      await tester.pump();
      // Con 2 elegidos, el tercero queda bloqueado.
      expect(tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'Pepe')).onSelected, isNull);
      expect(find.text('−10 en la Copa'), findsNWidgets(2));
      await tester.tap(find.text('Cambiar apuestas'));
      await tester.pumpAndSettle();
      final byPlayer = {for (final e in c.read(sessionProvider).events) e.playerId: e.delta};
      expect(byPlayer, {'p0': 20, 'p1': -10, 'p2': -10});
      expect(c.read(lastRaceResultProvider)!.settled, isTrue);
    });

    testWidgets('con 2 jugadores el All-in solo puede ir a la otra persona', (tester) async {
      await pump(
        tester,
        bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn)],
        players: 2,
      );
      expect(find.textContaining('(0/1)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Ana'), findsNothing);
      expect(find.widgetWithText(FilterChip, 'Luis'), findsOneWidget);
    });

    testWidgets('nadie acierta: todos pagan', (tester) async {
      await pump(
        tester,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.oros, chips: 1),
          Bet(playerId: 'p1', suit: Suit.bastos, chips: 4),
        ],
      );
      expect(find.text('Nadie acertó. ¡Todos pagan!'), findsOneWidget);
      expect(find.text('−4 en la Copa'), findsOneWidget);
    });

    testWidgets('modo sorbos: el All-in perdedor pide 3 sorbos y una línea aparte dice −10 en la Copa', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [Bet(playerId: 'p0', suit: Suit.oros, chips: Bet.allIn)],
      );
      expect(find.text('3 sorbos · o agua o reto'), findsOneWidget);
      expect(find.text('−10 en la Copa'), findsOneWidget);
      expect(find.text('Apostó All-in a Oros y falló'), findsOneWidget);
    });

    testWidgets('modo retos y sorbos: el All-in ganador se traduce a retos o sorbos', (tester) async {
      await pump(
        tester,
        mode: 'retos',
        bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn)],
      );
      expect(find.textContaining('Reparte un reto a 2 personas distintas (0/2)'), findsOneWidget);
      expect(find.textContaining('Reparte 2 All-in'), findsNothing);
    });

    testWidgets('modo sorbos: reparte hasta 3 sorbos', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn)],
      );
      expect(find.textContaining('Reparte hasta 3 sorbos a 2 personas distintas'), findsOneWidget);
    });
  });

  group('textos de la carrera', () {
    test('All-in según el modo', () {
      expect(allInShareText(ConsequenceMode.puntos, 2), 'Reparte 2 All-in a 2 personas distintas');
      expect(allInShareText(ConsequenceMode.puntos, 1), 'Reparte 1 All-in a 1 persona');
      expect(allInShareText(ConsequenceMode.retos, 2), 'Reparte un reto a 2 personas distintas');
      expect(allInShareText(ConsequenceMode.sorbos, 2), 'Reparte hasta 3 sorbos a 2 personas distintas');
    });

    test('resumen de quién paga y línea de la Copa', () {
      expect(chipsLine('Pagan', {'Ana': 2, 'Luis': 3}, gain: false), 'Pagan: Ana (−2), Luis (−3)');
      expect(chipsLine('Ganan', {'Marta': 5}, gain: true), 'Ganan: Marta (+5)');
      expect(chipsLine('Pagan', {}, gain: false), '');
      expect(cupLineFor(ConsequenceMode.puntos, 10), isNull);
      expect(cupLineFor(ConsequenceMode.sorbos, 10), '−10 en la Copa');
      expect(chipsText(1), '1 ficha');
      expect(allInCountText(2), '2 All-in');
    });
  });

  group('preparación', () {
    Future<void> pumpSetup(WidgetTester tester, {required int players}) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await _container({
        if (players > 0)
          'players.v1': jsonEncode([
            for (var i = 0; i < players; i++) {'id': 'p$i', 'name': 'J$i', 'color': i},
          ]),
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(home: RaceSetupScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('sin jugadores explica qué hacer y ofrece añadirlos', (tester) async {
      await pumpSetup(tester, players: 0);
      expect(find.text('Carrera de caballos'), findsOneWidget);
      expect(find.textContaining('Añade jugadores para apostar.'), findsOneWidget);
      expect(find.text('Añade jugadores para apostar'), findsOneWidget); // botón
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Gira el móvil'), findsOneWidget);
    });

    testWidgets('con jugadores pide elegir quién apuesta y el valor del slider va en la etiqueta', (tester) async {
      await pumpSetup(tester, players: 2);
      expect(find.text('Elige quién apuesta'), findsOneWidget);
      expect(find.text('Casillas hasta la meta: 6'), findsOneWidget);
    });
  });
}
