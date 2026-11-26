import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/core/content/prompts.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_module.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _asset = 'assets/content/es/test.json';
final _now = DateTime(2026, 11, 24, 22);

List<Prompt> _cards(PromptCardStyle style) => [
  for (var i = 1; i <= 3; i++)
    Prompt(
      id: 'c$i',
      level: PromptLevel.suave,
      fields: switch (style) {
        PromptCardStyle.choice => {'a': 'opción A$i', 'b': 'opción B$i'},
        _ => {'texto': 'texto $i'},
      },
    ),
];

PromptDeckModule _game({
  PromptPayMode payMode = PromptPayMode.fixed,
  PromptCardStyle style = PromptCardStyle.statement,
}) => PromptDeckModule(
  id: 'test-game',
  title: 'Test',
  subtitle: 's',
  color: const Color(0xFFE5575C),
  contentAsset: _asset,
  style: style,
  rule: 'regla',
  prefix: 'Yo nunca',
  payMode: payMode,
);

Future<ProviderContainer> _pump(
  WidgetTester tester,
  PromptDeckModule game, {
  bool withPlayers = true,
  String? mode,
  bool adult = false,
}) async {
  SharedPreferences.setMockInitialValues({
    if (adult) 'settings.adultConfirmed.v1': true,
    if (withPlayers)
      'players.v1': jsonEncode([
        {'id': 'p1', 'name': 'Ana', 'color': 0},
        {'id': 'p2', 'name': 'Luis', 'color': 1},
        {'id': 'p3', 'name': 'Eva', 'color': 2},
      ]),
    'settings.consequenceMode.v1': ?mode,
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionClockProvider.overrideWithValue(() => _now),
      promptsProvider(_asset).overrideWith((ref) async => _cards(game.style)),
      promptsProvider(promptRetosAsset).overrideWith(
        (ref) async => const [
          Prompt(
            id: 'rt_x',
            level: PromptLevel.suave,
            fields: {'texto': 'Reto de prueba'},
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
        builder: (_, _) => const Scaffold(body: Text('inicio')),
      ),
      GoRoute(
        path: '/play',
        builder: (_, _) =>
            PromptDeckPlayScreen(game: game, levels: const {PromptLevel.suave}),
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  unawaited(router.push('/play'));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('regla'));
  await tester.pumpAndSettle();
}

void main() {
  test('ningún modo de pago de los mazos anota en la Copa', () {
    for (final mode in PromptPayMode.values) {
      expect(_game(payMode: mode).scoresCup, isFalse, reason: '$mode');
    }
  });

  group('modo fixed (Yo nunca)', () {
    testWidgets('no pide marcar a nadie ni habla de pagar', (tester) async {
      await _pump(tester, _game());
      expect(find.byType(FilterChip), findsNothing);
      expect(find.textContaining('¿Quién paga?'), findsNothing);
      expect(find.textContaining('Apunta'), findsNothing);
      expect(
        find.textContaining('en la Copa', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('pasar todas las cartas no toca la Copa aunque haya jugadores', (
      tester,
    ) async {
      final c = await _pump(tester, _game());
      await _next(tester);
      await _next(tester);
      await _next(tester);
      expect(find.text('Fin de la partida'), findsOneWidget);
      expect(c.read(sessionProvider).events, isEmpty);
      expect(c.read(sessionProvider).roundIds, isEmpty);
    });

    testWidgets('en modo Fichas no hay banner ni texto de consecuencia', (
      tester,
    ) async {
      await _pump(tester, _game());
      expect(find.byKey(const ValueKey('fixed-banner')), findsNothing);
      expect(find.text('Quien lo haya hecho'), findsNothing);
      expect(find.textContaining('−', findRichText: true), findsNothing);
      expect(find.textContaining('sorbo'), findsNothing);
      expect(find.textContaining('reto'), findsNothing);
    });

    testWidgets('modo Retos: banner fijo con "Un reto" y nunca un número', (
      tester,
    ) async {
      await _pump(tester, _game(), mode: 'retos');
      expect(find.byKey(const ValueKey('fixed-banner')), findsOneWidget);
      expect(find.text('Quien lo haya hecho'), findsOneWidget);
      expect(find.text('Un reto'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d reto')), findsNothing);
      expect(find.text('Reto de prueba'), findsOneWidget);
      // El titular de la carta es solo de las cartas de apuesta: no se duplica.
      expect(find.textContaining('¡Por'), findsNothing);
    });

    testWidgets(
      'modo Sorbos: intensidad 1 a 3 con la alternativa de agua o reto a la vista',
      (tester) async {
        await _pump(tester, _game(), mode: 'sorbos', adult: true);
        expect(find.byKey(const ValueKey('fixed-banner')), findsOneWidget);
        expect(find.text('Quien lo haya hecho'), findsOneWidget);
        expect(
          find.textContaining(RegExp(r'^[123] sorbos? · o agua o reto$')),
          findsOneWidget,
        );
        expect(find.textContaining('o agua o reto'), findsOneWidget);
        expect(find.textContaining('Por '), findsNothing);
      },
    );

    testWidgets('la intensidad de Sorbos es de 1 a 3 en todas las cartas', (
      tester,
    ) async {
      await _pump(tester, _game(), mode: 'sorbos', adult: true);
      for (var i = 0; i < 3; i++) {
        expect(
          find.textContaining(RegExp(r'^[123] sorbos? · o agua o reto$')),
          findsOneWidget,
        );
        await _next(tester);
      }
    });

    testWidgets('el banner sigue en la carta siguiente y sin jugadores', (
      tester,
    ) async {
      final c = await _pump(tester, _game(), mode: 'retos', withPlayers: false);
      expect(find.byKey(const ValueKey('fixed-banner')), findsOneWidget);
      await _next(tester);
      expect(find.text('Carta 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('fixed-banner')), findsOneWidget);
      expect(c.read(sessionProvider).events, isEmpty);
    });

    testWidgets('al final de la partida el banner desaparece', (tester) async {
      await _pump(tester, _game(), mode: 'sorbos', adult: true);
      await _next(tester);
      await _next(tester);
      await _next(tester);
      expect(find.text('Fin de la partida'), findsOneWidget);
      expect(find.byKey(const ValueKey('fixed-banner')), findsNothing);
    });
  });

  testWidgets('payMode none no muestra banner ni jugadores', (tester) async {
    await _pump(tester, _game(payMode: PromptPayMode.none), mode: 'retos');
    expect(find.byType(FilterChip), findsNothing);
    expect(find.byKey(const ValueKey('fixed-banner')), findsNothing);
    expect(find.byKey(const ValueKey('stake-banner')), findsNothing);
  });

  testWidgets('estilo question: prefijo fijo y cierre con "?"', (tester) async {
    await _pump(
      tester,
      _game(payMode: PromptPayMode.stake, style: PromptCardStyle.question),
    );
    final rich = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText());
    expect(
      rich.any(
        (t) => RegExp(r'^¿Quién es más probable que texto \d\?$').hasMatch(t),
      ),
      isTrue,
      reason: rich.join(' | '),
    );
  });

  group('modo stake (¿Quién es más probable?)', () {
    PromptDeckModule stakeGame() =>
        _game(payMode: PromptPayMode.stake, style: PromptCardStyle.question);

    testWidgets('modo Fichas: sin texto de apuesta y sin selección de jugadores', (
      tester,
    ) async {
      await _pump(tester, stakeGame());
      expect(find.textContaining('Por '), findsNothing);
      expect(find.textContaining('¡Por'), findsNothing);
      expect(find.textContaining('ficha'), findsNothing);
      expect(find.textContaining('apuesta'), findsNothing);
      expect(find.textContaining('¿Quién paga?'), findsNothing);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.textContaining('Apunta'), findsNothing);
    });

    testWidgets('pasar todas las cartas no toca la Copa', (tester) async {
      final c = await _pump(tester, stakeGame());
      await _next(tester);
      await _next(tester);
      await _next(tester);
      expect(find.text('Fin de la partida'), findsOneWidget);
      expect(c.read(sessionProvider).events, isEmpty);
    });

    testWidgets('en modo puntos no hay banner: solo el titular', (tester) async {
      await _pump(tester, stakeGame());
      expect(find.byKey(const ValueKey('stake-banner')), findsNothing);
      expect(find.textContaining('−', findRichText: true), findsNothing);
    });

    testWidgets('modo Retos: titular "¡Por un reto!" sin ficha ni número', (
      tester,
    ) async {
      await _pump(tester, stakeGame(), mode: 'retos');
      expect(find.text('¡Por un reto!'), findsOneWidget);
      expect(find.textContaining('ficha'), findsNothing);
      expect(find.byType(ChipToken), findsNothing);
      expect(find.textContaining(RegExp(r'\d reto')), findsNothing);
      expect(find.text('Un reto'), findsNothing);
    });

    testWidgets('modo Sorbos: una sola vez la apuesta, con "o agua o reto" y sin ficha', (
      tester,
    ) async {
      await _pump(tester, stakeGame(), mode: 'sorbos', adult: true);
      expect(
        find.textContaining(RegExp(r'^Por [123] sorbos? · o agua o reto$')),
        findsOneWidget,
      );
      expect(find.textContaining('o agua o reto'), findsOneWidget);
      expect(find.textContaining('¡Por'), findsNothing);
      expect(find.textContaining('ficha'), findsNothing);
      expect(find.byType(ChipToken), findsNothing);
      expect(find.byKey(const ValueKey('stake-banner')), findsNothing);
      expect(find.text('El más señalado'), findsNothing);
    });

    testWidgets('modo Sorbos: "o agua o reto" sigue visible en todas las cartas', (
      tester,
    ) async {
      await _pump(tester, stakeGame(), mode: 'sorbos', adult: true);
      for (var i = 0; i < 3; i++) {
        expect(find.textContaining('o agua o reto'), findsOneWidget);
        await _next(tester);
      }
    });

    testWidgets('modo retos: el banner solo aporta el reto concreto', (
      tester,
    ) async {
      await _pump(tester, stakeGame(), mode: 'retos');
      expect(find.byKey(const ValueKey('stake-banner')), findsOneWidget);
      expect(find.text('El más señalado'), findsOneWidget);
      expect(find.text('Un reto'), findsNothing);
      expect(find.text('Reto de prueba'), findsOneWidget);
    });

    testWidgets('sin jugadores el juego funciona igual', (tester) async {
      final c = await _pump(
        tester,
        stakeGame(),
        withPlayers: false,
        mode: 'retos',
      );
      expect(find.textContaining('¡Por '), findsOneWidget);
      await _next(tester);
      expect(find.text('Carta 2'), findsOneWidget);
      expect(c.read(sessionProvider).events, isEmpty);
    });

    testWidgets('salir no menciona la Copa', (tester) async {
      await _pump(tester, stakeGame());
      await tester.tap(find.byTooltip('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('Pierdes el sitio en la partida.'), findsOneWidget);
    });
  });

  testWidgets('al final se ofrece otra partida con cartas', (tester) async {
    await _pump(tester, _game(payMode: PromptPayMode.none));
    await _next(tester);
    await _next(tester);
    await _next(tester);
    expect(find.text('Fin de la partida'), findsOneWidget);
    expect(find.text('Otra partida'), findsOneWidget);
    await tester.tap(find.text('Otra partida'));
    await tester.pumpAndSettle();
    expect(find.text('Carta 1'), findsOneWidget);
  });

  testWidgets('salir pide confirmación, no menciona la Copa y no anota nada', (
    tester,
  ) async {
    final c = await _pump(tester, _game());
    await tester.tap(find.byTooltip('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    expect(find.text('Pierdes el sitio en la partida.'), findsOneWidget);
    expect(find.textContaining('Copa'), findsNothing);
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsNothing);

    // Atrás del sistema (también el predictivo): mismo diálogo.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
    expect(c.read(sessionProvider).events, isEmpty);
  });
}
