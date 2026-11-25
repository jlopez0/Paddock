import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/app_icons.dart';
import 'package:paddock/app/mascot.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_module.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _asset = 'assets/content/es/test_scale.json';
final _now = DateTime(2026, 11, 24, 22);

const _long =
    'tu mejor amigo te pidiera prestado el coche justo el día que tienes que '
    'ir a una boda en otra ciudad y no tienes ni idea de qué decirle';

List<Prompt> _cards(PromptCardStyle style) => [
  Prompt(
    id: 'c1',
    level: PromptLevel.atrevido,
    fields: switch (style) {
      PromptCardStyle.choice => {'a': _long, 'b': 'Bicicleta'},
      _ => {'texto': _long},
    },
  ),
  Prompt(
    id: 'c2',
    level: PromptLevel.suave,
    fields: switch (style) {
      PromptCardStyle.choice => {'a': 'Sí', 'b': 'No'},
      _ => {'texto': 'cantar'},
    },
  ),
];

PromptDeckModule _game(PromptCardStyle style, PromptPayMode pay) =>
    PromptDeckModule(
      id: 'test-game',
      title: '¿Quién es más probable?',
      subtitle: 's',
      color: const Color(0xFF3FA796),
      contentAsset: _asset,
      style: style,
      rule: 'A la de tres, todos señalan. El más señalado paga una ficha',
      prefix: 'Yo nunca',
      payMode: pay,
    );

Future<ProviderContainer> _pump(
  WidgetTester tester,
  PromptDeckModule game, {
  String? mode,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'players.v1': jsonEncode([
      for (final (i, n) in ['Ana', 'Luis', 'Eva', 'Pepe', 'Marta'].indexed)
        {'id': 'p$i', 'name': n, 'color': i},
    ]),
    'settings.consequenceMode.v1': ?mode,
    'settings.adultConfirmed.v1': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionClockProvider.overrideWithValue(() => _now),
      promptsProvider(_asset).overrideWith((ref) async => _cards(game.style)),
      promptsProvider(promptRetosAsset).overrideWith(
        (ref) async => [
          const Prompt(
            id: 'rt_x',
            level: PromptLevel.suave,
            fields: {'texto': 'Cuenta un secreto que nadie sepa de ti ahora'},
          ),
        ],
      ),
    ],
  );
  addTearDown(c.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('ini')),
      ),
      GoRoute(
        path: '/play',
        builder: (_, _) => PromptDeckPlayScreen(
          game: game,
          levels: const {PromptLevel.suave, PromptLevel.atrevido},
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(2.0),
            disableAnimations: reduceMotion,
          ),
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push('/play'));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  _gapTest();
  for (final style in PromptCardStyle.values) {
    for (final reduce in [false, true]) {
      testWidgets(
        'partida $style con letra 2.0 en 320x568 (sin animaciones: $reduce)',
        (tester) async {
          final c = await _pump(
            tester,
            _game(
              style,
              style == PromptCardStyle.statement
                  ? PromptPayMode.multi
                  : PromptPayMode.single,
            ),
            mode: 'retos',
            reduceMotion: reduce,
          );
          final ex0 = tester.takeException();
          expect(
            ex0,
            isNull,
            reason: ex0 is FlutterError ? ex0.toStringDeep() : '$ex0',
          );
          // La carta es un boleto y lleva el nivel con icono dibujado.
          expect(find.byType(TicketCard), findsOneWidget);
          expect(find.byType(LevelIcon), findsOneWidget);
          // El mazo se baraja: la primera carta puede ser de cualquier nivel.
          final levelFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data == 'Suave' || w.data == 'Atrevido'),
          );
          expect(levelFinder, findsOneWidget);
          expect(find.text('1 / 2'), findsOneWidget);

          // Marcar a varios jugadores: la ficha sustituye a la inicial.
          // Con letra 2.0 la fila de jugadores se desplaza dentro de su hueco.
          await tester.ensureVisible(find.byKey(const ValueKey('pay-p0')));
          await tester.tap(find.byKey(const ValueKey('pay-p0')));
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byKey(const ValueKey('pay-p0')),
              matching: find.byType(ChipToken),
            ),
            findsOneWidget,
          );
          await tester.ensureVisible(find.byKey(const ValueKey('pay-p1')));
          await tester.tap(find.byKey(const ValueKey('pay-p1')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Siguiente carta (nivel suave) y fin de mazo.
          await tester.tapAt(const Offset(160, 120));
          await tester.pumpAndSettle();
          expect(levelFinder, findsOneWidget);
          expect(c.read(sessionProvider).events.length, 2);
          await tester.tapAt(const Offset(160, 120));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Se acabó el mazo'), findsOneWidget);
          expect(find.byType(Jockey), findsOneWidget);
          expect(find.text('Barajar de nuevo'), findsOneWidget);
        },
      );
    }
  }
}

void _gapTest() {
  testWidgets(
    'el título de la cabecera no toca la barra de progreso (letra 2.0)',
    (tester) async {
      await _pump(
        tester,
        _game(PromptCardStyle.statement, PromptPayMode.multi),
        mode: 'retos',
      );
      final title = tester.getRect(find.text('¿Quién es más probable?'));
      final bar = tester.getRect(find.byType(LinearProgressIndicator));
      expect(bar.top - title.bottom, greaterThanOrEqualTo(8));
    },
  );
}
