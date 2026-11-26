import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/horse_race/domain/bets.dart';
import 'package:habinson/games/horse_race/domain/cards.dart';
import 'package:habinson/games/horse_race/race_result.dart';
import 'package:habinson/games/horse_race/ui/race_result_screen.dart';
import 'package:habinson/games/horse_race/ui/race_setup_screen.dart';
import 'package:habinson/games/horse_race/ui/race_stats_screen.dart';
import 'package:habinson/games/horse_race/ui/race_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionClockProvider.overrideWithValue(() => DateTime(2026, 11, 24, 22)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Widget _app(ProviderContainer c, Widget home, {double scale = 1, bool reduce = false}) =>
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: reduce,
          ),
          child: child!,
        ),
        home: home,
      ),
    );

String _players(int n) => jsonEncode([
      for (var i = 0; i < n; i++) {'id': 'p$i', 'name': ['Ana', 'Luis', 'Eva', 'Pepe'][i], 'color': i},
    ]);

Finder _chip(int v) => find.byWidgetPredicate((w) => w is ChipToken && w.value == v);

void _phone(WidgetTester tester, {bool tall = false}) {
  tester.view.physicalSize = tall ? const Size(320, 3000) : const Size(320, 568);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  group('sin emoji en la zona de la Carrera', () {
    test('ningún archivo de lib/games/horse_race contiene emoji', () {
      // Emoji y pictogramas: fuera del BMP (U+1F000..) o en los bloques de símbolos varios.
      final emoji = RegExp('[\u{1F000}-\u{1FFFF}☀-➿⬀-⯿️]', unicode: true);
      final offenders = [
        for (final f in Directory('lib/games/horse_race').listSync(recursive: true))
          if (f is File && f.path.endsWith('.dart') && emoji.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(offenders, isEmpty);
    });
  });

  group('preparación con fichas dibujadas', () {
    testWidgets('320x568 con texto al 200 %: elegir jugador, All-in y palo sin desbordes', (tester) async {
      _phone(tester);
      final c = await _container({'players.v1': _players(2)});
      await tester.pumpWidget(_app(c, const RaceSetupScreen(), scale: 2));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump();
      await tester.scrollUntilVisible(find.textContaining('All-in'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(find.textContaining('All-in'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
    });

    testWidgets('la apuesta se dibuja como ficha con su valor y con All-in es la ficha de 10', (tester) async {
      _phone(tester, tall: true);
      final c = await _container({'players.v1': _players(2)});
      await tester.pumpWidget(_app(c, const RaceSetupScreen()));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_chip(2), findsOneWidget);
      await tester.tap(find.byTooltip('Subir apuesta'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_chip(3), findsOneWidget);
      await tester.tap(find.textContaining('All-in'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_chip(kAllInChips), findsWidgets);
    });

    testWidgets('con "reducir animaciones" la ficha cambia al instante', (tester) async {
      _phone(tester, tall: true);
      final c = await _container({'players.v1': _players(2)});
      await tester.pumpWidget(_app(c, const RaceSetupScreen(), reduce: true));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump();
      await tester.tap(find.byTooltip('Subir apuesta'));
      await tester.pump();
      expect(_chip(3), findsOneWidget);
      expect(_chip(2), findsNothing);
    });
  });

  group('resultado como boletos', () {
    Future<ProviderContainer> pumpResult(
      WidgetTester tester, {
      required List<Bet> bets,
      Suit winner = Suit.copas,
      double scale = 1,
      bool reduce = false,
    }) async {
      _phone(tester, tall: scale == 1);
      final c = await _container({
        'settings.adultConfirmed.v1': true,
        'players.v1': _players(4),
      });
      c.read(lastRaceResultProvider.notifier).set(
            RaceResult(
              roundId: 'carrera-1',
              winner: winner,
              standings: Suit.values,
              outcomes: settleBets(bets, winner),
              draws: 12,
            ),
          );
      await tester.pumpWidget(_app(c, const RaceResultScreen(), scale: scale, reduce: reduce));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return c;
    }

    testWidgets('cada apostante tiene boleto: Cobran con sello COBRA y Pagan con sello PAGA', (tester) async {
      await pumpResult(tester, bets: const [
        Bet(playerId: 'p0', suit: Suit.copas, chips: 3),
        Bet(playerId: 'p1', suit: Suit.oros, chips: 2),
      ]);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Cobran'), findsOneWidget);
      expect(find.text('Pagan'), findsOneWidget);
      expect(find.text('COBRA', skipOffstage: false), findsOneWidget);
      expect(find.text('PAGA', skipOffstage: false), findsOneWidget);
      expect(find.byType(TicketCard, skipOffstage: false), findsNWidgets(2));
      // El podio usa medallas dibujadas.
      expect(find.byType(MedalIcon), findsNWidgets(3));
      // Nada sugiere que unos paguen a otros.
      expect(find.textContaining('Ganan'), findsNothing);
    });

    testWidgets('320x568 con texto al 200 % y All-in ganador y perdedor: sin desbordes', (tester) async {
      await pumpResult(
        tester,
        scale: 2,
        bets: const [
          Bet(playerId: 'p0', suit: Suit.copas, chips: Bet.allIn),
          Bet(playerId: 'p1', suit: Suit.oros, chips: Bet.allIn),
          Bet(playerId: 'p2', suit: Suit.bastos, chips: 5),
        ],
      );
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('con "reducir animaciones" no hay confeti ni retardo en los sellos', (tester) async {
      await pumpResult(tester, reduce: true, bets: const [Bet(playerId: 'p0', suit: Suit.copas, chips: 3)]);
      expect(find.text('COBRA', skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin ganador: nadie cobra y no hay sello COBRA', (tester) async {
      await pumpResult(tester, bets: const [Bet(playerId: 'p0', suit: Suit.oros, chips: 3)]);
      expect(find.text('Cobran'), findsNothing);
      expect(find.text('COBRA', skipOffstage: false), findsNothing);
      expect(find.text('Nadie acertó. Pagan todos.'), findsOneWidget);
    });
  });

  group('estadísticas', () {
    testWidgets('sin carreras: estado vacío con la mascota', (tester) async {
      _phone(tester);
      final c = await _container({'players.v1': _players(2)});
      await tester.pumpWidget(_app(c, const RaceStatsScreen(), scale: 2));
      await tester.pump();
      expect(find.text('Pista sin estrenar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('piezas', () {
    testWidgets('el sello y la ficha respetan el texto grande sin desbordar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: const Scaffold(
              body: Row(children: [RaceChip(12), RaceChip(0, allIn: true), RaceStamp.cobra(), RaceStamp.paga()]),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
