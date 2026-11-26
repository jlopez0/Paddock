import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/app/mascot.dart';
import 'package:habinson/core/content/prompts.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_module.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_screens.dart';
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

/// Modo de pago de cada estilo en la app real: Yo nunca muestra una consecuencia fija,
/// ¿Quién es más probable? anuncia una apuesta y ¿Qué preferirías? no paga nada.
PromptPayMode _payModeOf(PromptCardStyle style) => switch (style) {
  PromptCardStyle.statement => PromptPayMode.fixed,
  PromptCardStyle.question => PromptPayMode.stake,
  PromptCardStyle.choice => PromptPayMode.none,
};

PromptDeckModule _game(PromptCardStyle style, PromptPayMode pay) =>
    PromptDeckModule(
      id: 'test-game',
      title: '¿Quién es más probable?',
      subtitle: 's',
      color: const Color(0xFF3FA796),
      contentAsset: _asset,
      style: style,
      rule: 'A la de tres, todos señalan. Al más señalado le toca lo que diga la carta',
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
  _sorbosTest();
  for (final style in PromptCardStyle.values) {
    for (final reduce in [false, true]) {
      testWidgets(
        'partida $style con letra 2.0 en 320x568 (sin animaciones: $reduce)',
        (tester) async {
          final c = await _pump(
            tester,
            _game(style, _payModeOf(style)),
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
          // Solo el número de carta: ni barra de progreso ni total del mazo.
          expect(find.text('Carta 1'), findsOneWidget);
          expect(find.byType(LinearProgressIndicator), findsNothing);
          expect(find.text('1 / 2'), findsNothing);

          // Ningún mazo pide marcar jugadores ni habla de "¿Quién paga?".
          expect(find.byType(FilterChip), findsNothing);
          expect(find.textContaining('¿Quién paga?'), findsNothing);
          if (style == PromptCardStyle.statement) {
            // Yo nunca: banner fijo de lo que le toca a quien lo haya hecho.
            expect(find.byKey(const ValueKey('fixed-banner')), findsOneWidget);
            expect(find.text('Quien lo haya hecho'), findsOneWidget);
          } else {
            expect(find.byKey(const ValueKey('fixed-banner')), findsNothing);
          }
          if (style == PromptCardStyle.question) {
            // La apuesta se anuncia sobre la pregunta y en Retos sale el banner.
            expect(find.textContaining('¡Por '), findsOneWidget);
            expect(find.byKey(const ValueKey('stake-banner')), findsOneWidget);
          } else {
            expect(find.textContaining('¡Por '), findsNothing);
          }

          // Siguiente carta (nivel suave) y fin de la partida.
          await tester.tapAt(const Offset(160, 120));
          await tester.pumpAndSettle();
          expect(levelFinder, findsOneWidget);
          expect(
            c.read(sessionProvider).events,
            isEmpty,
            reason: 'ningún mazo anota en la Copa',
          );
          await tester.tapAt(const Offset(160, 120));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Fin de la partida'), findsOneWidget);
          expect(find.byType(Jockey), findsOneWidget);
          expect(find.text('Otra partida'), findsOneWidget);
        },
      );
    }
  }
}

void _sorbosTest() {
  for (final style in [PromptCardStyle.question, PromptCardStyle.statement]) {
    testWidgets('modo Sorbos $style: titular con "o agua o reto" sin duplicado ni desbordes (letra 2.0)', (
      tester,
    ) async {
      await _pump(tester, _game(style, _payModeOf(style)), mode: 'sorbos');
      final ex = tester.takeException();
      expect(ex, isNull, reason: ex is FlutterError ? ex.toStringDeep() : '$ex');
      expect(find.textContaining('o agua o reto'), findsOneWidget);
      expect(find.textContaining('ficha'), findsNothing);
      expect(find.textContaining('paga'), findsNothing);
      if (style == PromptCardStyle.question) {
        expect(find.textContaining(RegExp(r'^Por [123] sorbos? · o agua o reto$')), findsOneWidget);
        expect(find.byKey(const ValueKey('stake-banner')), findsNothing);
      }
    });
  }
}

void _gapTest() {
  testWidgets(
    'el título de la cabecera no pisa el número de carta (letra 2.0)',
    (tester) async {
      await _pump(
        tester,
        _game(PromptCardStyle.statement, PromptPayMode.fixed),
        mode: 'retos',
      );
      final title = tester.getRect(find.text('¿Quién es más probable?'));
      final counter = tester.getRect(find.text('Carta 1'));
      expect(title.overlaps(counter), isFalse);
    },
  );
}
