import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/cup_screen.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/horse_race/domain/bets.dart';
import 'package:habinson/games/horse_race/domain/cards.dart';
import 'package:habinson/games/horse_race/horse_race_module.dart';
import 'package:habinson/games/horse_race/race_result.dart';
import 'package:habinson/games/horse_race/race_store.dart';
import 'package:habinson/games/horse_race/race_texts.dart';
import 'package:habinson/games/horse_race/ui/race_result_screen.dart';
import 'package:habinson/games/horse_race/ui/race_setup_screen.dart';
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

/// La etiqueta accesible de un `Semantics` (sin activar el árbol de semántica).
Finder _sem(String label) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == label, description: 'Semantics "$label"');

void main() {
  group('migración de race.setup.v1', () {
    test('lee el formato antiguo: sips 8 se conserva (rango 1-9) y sips 0 pasa a All-in', () async {
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
      expect(bets.map((b) => b.chips), [8, Bet.allIn, 3]);
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
      expect(c.read(raceSetupProvider).bets.map((b) => b.chips), [1, 9]);
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
      Size size = const Size(800, 2400),
      double scale = 1.0,
    }) async {
      tester.view.physicalSize = size;
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
          GoRoute(path: '/copa', builder: (_, _) => const CupScreen()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            routerConfig: router,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
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
      expect(find.text('Ana cobra 3 fichas'), findsOneWidget);
      // La información va una sola vez, en los boletos: sin línea suelta que la repita.
      expect(find.textContaining('Cobran: '), findsNothing);
      expect(find.textContaining('Pagan: '), findsNothing);
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

    testWidgets('All-in ganador que sale con Ver Copa sin repartir: sigue en la Copa y no cuenta doble', (tester) async {
      final c = await pump(
        tester,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn),
          Bet(playerId: 'p1', suit: Suit.oros, chips: Bet.allIn),
        ],
      );
      expect(c.read(sessionProvider).events, isEmpty); // espera a la elección
      expect(find.textContaining('(0/2)'), findsOneWidget);
      await tester.tap(find.text('Ver Copa'));
      await tester.pumpAndSettle();
      // La ganadora (Ana) aparece en el podio de la Copa, con 0 fichas, junto a quien perdió.
      final s = c.read(sessionProvider).standings;
      expect(s.map((e) => (e.playerId, e.total)), [('p0', 0), ('p1', -10)]);
      expect(find.byKey(const ValueKey('podium-block-p0')), findsOneWidget);
      expect(find.byKey(const ValueKey('podium-block-p1')), findsOneWidget);
      // Volver al resultado y salir otra vez no duplica la ronda.
      c.read(sessionProvider.notifier).award('carrera-1', 'carrera', {'p0': 99});
      expect(c.read(sessionProvider).events, hasLength(2));
      expect(c.read(lastRaceResultProvider)!.settled, isTrue);
    });

    testWidgets('el resultado ofrece Ver Copa', (tester) async {
      await pump(tester, bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: 3)]);
      expect(find.text('Ver Copa'), findsOneWidget);
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
      expect(find.text('Nadie acertó. Pagan todos.'), findsOneWidget);
      expect(find.text('−4 en la Copa'), findsOneWidget);
    });

    testWidgets('modo sorbos: no se dice "pagar", sino a quién le toca, siempre con agua o reto', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
          Bet(playerId: 'p1', suit: Suit.oros, chips: 2),
        ],
      );
      expect(find.text('Les toca'), findsOneWidget);
      expect(find.textContaining('Les toca: '), findsNothing);
      expect(find.text('LE TOCA'), findsOneWidget);
      expect(find.text('PAGA'), findsNothing);
      expect(find.textContaining('Pagan'), findsNothing);
      expect(find.text('2 sorbos · o agua o reto'), findsOneWidget);
    });

    testWidgets('modo sorbos: el boleto no estrecha "3 sorbos · o agua o reto" junto al nombre', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        size: const Size(360, 900),
        bets: const [Bet(playerId: 'p0', suit: Suit.oros, chips: 3)],
      );
      final amount = find.text('3 sorbos · o agua o reto');
      expect(amount, findsOneWidget);
      // Si no cabe junto al nombre, el importe baja a su propia línea, con todo el ancho,
      // en vez de quedarse en una columna estrecha a su lado.
      final name = find.descendant(of: find.byType(Wrap).first, matching: find.text('Ana'));
      expect(tester.getTopLeft(amount).dy, greaterThanOrEqualTo(tester.getBottomLeft(name).dy));
      expect(tester.getTopLeft(amount).dx, tester.getTopLeft(name).dx);
    });

    testWidgets('con letra 2.0 en 320x568 el resultado de la Carrera en Sorbos no desborda', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        size: const Size(320, 568),
        scale: 2.0,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
          Bet(playerId: 'p1', suit: Suit.oros, chips: Bet.allIn),
          Bet(playerId: 'p2', suit: Suit.bastos, chips: 2),
        ],
      );
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('modo sorbos: nadie acierta dice a quién le toca', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [Bet(playerId: 'p0', suit: Suit.oros, chips: 1)],
      );
      expect(find.text('Nadie acertó. Les toca a todos · o agua o reto.'), findsOneWidget);
      expect(find.textContaining('Pagan'), findsNothing);
    });

    testWidgets('modo sorbos: el All-in perdedor pide 3 sorbos y no enseña los 10 de la Copa', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [Bet(playerId: 'p0', suit: Suit.oros, chips: Bet.allIn)],
      );
      expect(find.text('3 sorbos · o agua o reto'), findsOneWidget);
      expect(find.text('−10 en la Copa'), findsNothing);
      expect(find.text('Apostó All-in a Oros y falló'), findsOneWidget);
    });

    testWidgets('Sorbos: sin "ficha", "Cobran", "Paga/Pagan" ni "−N en la Copa" en el resultado', (tester) async {
      final banned = RegExp('ficha|Fichas|Cobr|cobr|COBR|Pag[ao]|PAG[AO]|−\\d+ en la Copa');
      for (final mode in ['sorbos']) {
        await pump(
          tester,
          mode: mode,
          bets: const [
            Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
            Bet(playerId: 'p1', suit: Suit.oros, chips: 2),
            Bet(playerId: 'p2', suit: Suit.bastos, chips: Bet.allIn),
          ],
        );
        await tester.pump(const Duration(seconds: 2));
        expect(find.text('Aciertan'), findsOneWidget, reason: mode);
        expect(find.text('Ana acierta'), findsOneWidget, reason: mode);
        expect(find.text('ACIERTA', skipOffstage: false), findsOneWidget, reason: mode);
        expect(find.text('Les toca'), findsOneWidget, reason: mode);
        expect(find.text('LE TOCA', skipOffstage: false), findsNWidgets(2), reason: mode);
        expect(find.text('Apostó a Copas'), findsOneWidget, reason: mode);
        expect(find.text('Apostó a Oros y falló'), findsOneWidget, reason: mode);
        expect(find.text('Apostó All-in a Bastos y falló'), findsOneWidget, reason: mode);
        expect(find.text('Ya cuenta en la Copa de la noche.'), findsOneWidget, reason: mode);
        final texts = [
          for (final e in find.byType(Text, skipOffstage: false).evaluate())
            ?(e.widget as Text).data,
        ];
        final bad = [
          for (final t in texts)
            if (t != 'Ya cuenta en la Copa de la noche.' && banned.hasMatch(t)) t,
        ];
        expect(bad, isEmpty, reason: 'modo $mode');
      }
    });

    testWidgets('modo fichas conserva Cobran, Pagan y la nota de fichas', (tester) async {
      await pump(
        tester,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
          Bet(playerId: 'p1', suit: Suit.oros, chips: 2),
        ],
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Cobran'), findsOneWidget);
      expect(find.text('Pagan'), findsOneWidget);
      expect(find.text('Apostó 3 fichas a Copas'), findsOneWidget);
      expect(find.text('Fichas anotadas en la Copa de la noche.'), findsOneWidget);
    });

    testWidgets('modo sorbos: reparte hasta 3 sorbos', (tester) async {
      await pump(
        tester,
        mode: 'sorbos',
        bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn)],
      );
      expect(find.textContaining('Reparte 2 All-in · hasta 3 sorbos cada uno · o agua o reto'), findsOneWidget);
      expect(find.textContaining('En la Copa, cada All-in vale'), findsNothing);
    });
  });

  group('textos de la carrera', () {
    test('All-in según el modo', () {
      expect(allInShareText(ConsequenceMode.puntos, 2), 'Reparte 2 All-in a 2 personas distintas');
      expect(allInShareText(ConsequenceMode.puntos, 1), 'Reparte 1 All-in a 1 persona');
      expect(allInShareText(ConsequenceMode.sorbos, 2), 'Reparte 2 All-in · hasta 3 sorbos cada uno · o agua o reto');
    });

    test('en Sorbos se dice "Les toca", con tope de 3 y agua o reto', () {
      expect(losersTitle(ConsequenceMode.sorbos), 'Les toca');
      expect(losersTitle(ConsequenceMode.puntos), 'Pagan');
      expect(losersLine(ConsequenceMode.sorbos, {'Ana': 2}), 'Les toca: Ana (2 sorbos · o agua o reto)');
      expect(losersLine(ConsequenceMode.sorbos, {'Ana': 10}), 'Les toca: Ana (3 sorbos · o agua o reto)');
      expect(losersLine(ConsequenceMode.puntos, {'Ana': 2}), 'Pagan: Ana (−2)');
      expect(whoPaysLabel(ConsequenceMode.sorbos), '¿A quién le toca?');
      expect(whoPaysLabel(ConsequenceMode.puntos), '¿Quién paga?');
    });

    test('vocabulario por modo: "ficha", "Cobran" y "Paga/Pagan" solo en Fichas', () {
      const bet = Bet(playerId: 'p0', suit: Suit.oros, chips: 3);
      const allIn = Bet(playerId: 'p0', suit: Suit.oros, chips: Bet.allIn);
      expect(winnersTitle(ConsequenceMode.puntos), 'Cobran');
      expect(winnersTitle(ConsequenceMode.sorbos), 'Aciertan');
      expect(winnerTicketTitle(ConsequenceMode.puntos, 'Ana', 3), 'Ana cobra 3 fichas');
      expect(winnerTicketTitle(ConsequenceMode.sorbos, 'Ana', 3), 'Ana acierta');
      expect(betReasonText(ConsequenceMode.puntos, bet), 'Apostó 3 fichas a Oros');
      expect(betReasonText(ConsequenceMode.puntos, bet, failed: true), 'Apostó 3 fichas a Oros y falló');
      expect(betReasonText(ConsequenceMode.sorbos, bet), 'Apostó a Oros');
      expect(betReasonText(ConsequenceMode.sorbos, bet, failed: true), 'Apostó a Oros y falló');
      expect(betReasonText(ConsequenceMode.sorbos, allIn, failed: true), 'Apostó All-in a Oros y falló');
      expect(nobodyWonText(ConsequenceMode.sorbos), 'Nadie acertó. Les toca a todos · o agua o reto.');
      final banned = RegExp('ficha|Pag[ao]|cobr|Cobr');
      for (final m in [ConsequenceMode.sorbos]) {
        final all = [
          allInShareText(m, 2),
          losersTitle(m),
          losersLine(m, {'Ana': 2, 'Luis': 5}),
          nobodyWonText(m),
          whoPaysLabel(m),
          winnersTitle(m),
          winnerTicketTitle(m, 'Ana', 3),
          betReasonText(m, bet, failed: true),
          allInA11yText(m),
          allInButtonText(m),
          stakeA11yText(m, 4),
          stakeCaption(m),
          stakeCapNote(m)!,
          cupNoteText(m),
        ].join(' | ');
        expect(banned.hasMatch(all), isFalse, reason: 'modo $m: $all');
      }
    });

    test('selector de apuesta: sin unidad ni "ficha" en Sorbos, con el tope a la vista', () {
      expect(stakeA11yText(ConsequenceMode.puntos, 1), '1 ficha');
      expect(stakeA11yText(ConsequenceMode.puntos, 3), '3 fichas');
      expect(stakeA11yText(ConsequenceMode.sorbos, 3), 'Apuesta de 3');
      expect(stakeCaption(ConsequenceMode.puntos), 'fichas');
      expect(stakeCaption(ConsequenceMode.sorbos), 'apuesta');
      expect(stakeCapNote(ConsequenceMode.puntos), isNull);
      expect(stakeCapNote(ConsequenceMode.sorbos), 'Hasta 3 por ronda · o agua o reto');
      expect(allInA11yText(ConsequenceMode.puntos), 'All-in, 10 fichas');
      expect(allInA11yText(ConsequenceMode.sorbos), 'All-in, 3 sorbos, o agua o reto');
      expect(allInButtonText(ConsequenceMode.puntos), 'All-in  ·  10 fichas');
      expect(allInButtonText(ConsequenceMode.sorbos), 'All-in  ·  3 sorbos');
      expect(cupNoteText(ConsequenceMode.puntos), 'Fichas anotadas en la Copa de la noche.');
      expect(cupNoteText(ConsequenceMode.sorbos), 'Ya cuenta en la Copa de la noche.');
    });

    test('la Carrera no se ofrece en Retos (D21), sí en Fichas y Sorbos', () {
      const race = HorseRaceModule();
      expect(race.availableIn(ConsequenceMode.puntos), isTrue);
      expect(race.availableIn(ConsequenceMode.sorbos), isTrue);
      expect(race.availableIn(ConsequenceMode.retos), isFalse);
    });

    test('home y estadísticas son neutras en los tres modos', () {
      expect(const HorseRaceModule().subtitle, 'Elige palo, apuesta y que corra tu caballo');
      final stats = File('lib/games/horse_race/ui/race_stats_screen.dart').readAsStringSync();
      expect(stats, contains("label: 'en contra'"));
      expect(stats, contains("label: 'a favor'"));
      expect(stats, isNot(contains('fichas perdidas')));
      expect(stats, isNot(contains('fichas ganadas')));
    });

    test('resumen de quién paga', () {
      expect(chipsLine('Pagan', {'Ana': 2, 'Luis': 3}, gain: false), 'Pagan: Ana (−2), Luis (−3)');
      expect(chipsLine('Cobran', {'Marta': 5}, gain: true), 'Cobran: Marta (+5)');
      expect(chipsLine('Pagan', {}, gain: false), '');
      expect(allInCupNote(ConsequenceMode.puntos), 'En la Copa, cada All-in vale 10 fichas');
      expect(allInCupNote(ConsequenceMode.retos), isNull);
      expect(allInCupNote(ConsequenceMode.sorbos), isNull);
      expect(chipsText(1), '1 ficha');
      expect(allInCountText(2), '2 All-in');
    });
  });

  group('preparación', () {
    Future<void> pumpSetup(WidgetTester tester, {required int players, String mode = 'puntos'}) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await _container({
        'settings.consequenceMode.v1': mode,
        'settings.adultConfirmed.v1': true,
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
      expect(find.textContaining('Sin jugadores no hay apuestas.'), findsOneWidget);
      expect(find.text('Añade jugadores para apostar'), findsOneWidget); // botón
      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Gira el móvil'), findsOneWidget);
    });

    testWidgets('con jugadores pide elegir quién apuesta y el valor del slider va en la etiqueta', (tester) async {
      await pumpSetup(tester, players: 2);
      expect(find.text('Haced vuestras apuestas'), findsOneWidget);
      expect(find.text('Casillas hasta la meta: 6'), findsOneWidget);
    });

    testWidgets('en Fichas el selector habla de fichas y no hay nota de tope', (tester) async {
      await pumpSetup(tester, players: 2);
      await tester.tap(find.widgetWithText(FilterChip, 'J0'));
      await tester.pump();
      expect(find.text('fichas'), findsOneWidget);
      expect(find.text('All-in  ·  10 fichas'), findsOneWidget);
      expect(find.byTooltip('Bajar apuesta'), findsOneWidget);
      expect(find.byTooltip('Subir apuesta'), findsOneWidget);
      expect(find.textContaining('Hasta 3 por ronda'), findsNothing);
      expect(_sem('2 fichas'), findsOneWidget);
      expect(find.text('Acertar gana el doble'), findsOneWidget);
      expect(find.text('Quien acierta suma el doble en la Copa'), findsOneWidget);
    });

    for (final (mode, button, note, a11y) in [
      ('sorbos', 'All-in  ·  3 sorbos', 'Hasta 3 por ronda · o agua o reto', 'All-in, 3 sorbos, o agua o reto'),
    ]) {
      testWidgets('en $mode el selector de apuesta no dice "ficha", enseña el tope y no cambia el rango', (tester) async {
        await pumpSetup(tester, players: 2, mode: mode);
        await tester.tap(find.widgetWithText(FilterChip, 'J0'));
        await tester.pump();
        expect(find.text(button), findsOneWidget);
        expect(find.text(note), findsOneWidget);
        expect(_sem(a11y), findsOneWidget);
        expect(_sem('Apuesta de 2'), findsWidgets);
        expect(find.byTooltip('Bajar apuesta'), findsOneWidget);
        expect(find.byTooltip('Subir apuesta'), findsOneWidget);
        expect(find.textContaining('ficha'), findsNothing);
        expect(find.textContaining('Fichas'), findsNothing);
        // Rango 1 a 9: subir desde 9 salta al All-in y bajar desde el All-in vuelve a 9.
        IconButton iconBtn(String tip) => tester.widget<IconButton>(find.byWidgetPredicate((w) => w is IconButton && w.tooltip == tip));
        for (var i = 0; i < 7; i++) {
          await tester.tap(find.byTooltip('Subir apuesta'));
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(_sem('Apuesta de 9'), findsWidgets);
        expect(iconBtn('Subir apuesta').onPressed, isNotNull);
        await tester.tap(find.byTooltip('Subir apuesta'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(_sem(a11y), findsWidgets);
        expect(iconBtn('Subir apuesta').onPressed, isNull);
        await tester.tap(find.byTooltip('Bajar apuesta'));
        await tester.pump(const Duration(milliseconds: 400));
        expect(_sem('Apuesta de 9'), findsWidgets);
        expect(iconBtn('Subir apuesta').onPressed, isNotNull);
      });
    }
  });
}
