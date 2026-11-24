import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_module.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_screens.dart';
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
  PromptPayMode payMode = PromptPayMode.multi,
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
}) async {
  SharedPreferences.setMockInitialValues({
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
  test('promptRoundId distingue carta, posición y partida', () {
    expect(
      promptRoundId('yn_001', 0, 'a.1'),
      isNot(promptRoundId('yn_001', 1, 'a.1')),
    );
    expect(
      promptRoundId('yn_001', 0, 'a.1'),
      isNot(promptRoundId('yn_001', 0, 'a.2')),
    );
    expect(promptRoundId('yn_001', 0, 'a.1'), startsWith('yn_001+0'));
  });

  test('payHint depende del modo y del estilo', () {
    expect(_game(payMode: PromptPayMode.none).payHint, '');
    expect(_game().payHint, 'Marca a quien lo haya hecho');
    expect(
      _game(
        payMode: PromptPayMode.single,
        style: PromptCardStyle.choice,
      ).payHint,
      'Marca a la minoría',
    );
    expect(
      _game(
        payMode: PromptPayMode.single,
        style: PromptCardStyle.question,
      ).payHint,
      'Marca al más votado',
    );
  });

  testWidgets('marcar a 2 jugadores resta 1 a cada uno al pasar de carta', (
    tester,
  ) async {
    final c = await _pump(tester, _game());
    expect(find.text('¿Quién paga? · 1 ficha'), findsOneWidget);
    expect(find.text('Marca a quien lo haya hecho'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pay-p1')));
    await tester.tap(find.byKey(const ValueKey('pay-p2')));
    await tester.pump();
    expect(
      c.read(sessionProvider).events,
      isEmpty,
      reason: 'no se registra hasta pasar de carta',
    );

    await _next(tester);
    final events = c.read(sessionProvider).events;
    expect(events.length, 2);
    expect({for (final e in events) e.playerId: e.delta}, {'p1': -1, 'p2': -1});
    expect(events.every((e) => e.gameId == 'test-game'), isTrue);
    expect(events.first.roundId, contains('+0@'));
  });

  testWidgets('deshacer y volver a avanzar no duplica y bloquea los chips', (
    tester,
  ) async {
    final c = await _pump(tester, _game());
    await tester.tap(find.byKey(const ValueKey('pay-p1')));
    await tester.pump();
    await _next(tester);
    expect(c.read(sessionProvider).events.length, 1);

    await tester.tap(find.byTooltip('Anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Ya anotado en la Copa'), findsOneWidget);
    // Tocar un chip bloqueado no cambia nada.
    await tester.tap(find.byKey(const ValueKey('pay-p2')));
    await tester.pump();

    await _next(tester);
    final events = c.read(sessionProvider).events;
    expect(events.length, 1);
    expect(events.single.playerId, 'p1');
    expect(c.read(sessionProvider).roundIds.length, 1);
  });

  testWidgets('pasar sin marcar a nadie no registra nada', (tester) async {
    final c = await _pump(tester, _game());
    await _next(tester);
    await _next(tester);
    expect(c.read(sessionProvider).events, isEmpty);
  });

  testWidgets('sin jugadores no hay fila y el juego sigue funcionando', (
    tester,
  ) async {
    final c = await _pump(tester, _game(), withPlayers: false);
    expect(find.textContaining('¿Quién paga?'), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
    expect(find.text('1 / 3'), findsOneWidget);
    await _next(tester);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(c.read(sessionProvider).events, isEmpty);
  });

  testWidgets('payMode none no muestra la fila aunque haya jugadores', (
    tester,
  ) async {
    await _pump(tester, _game(payMode: PromptPayMode.none));
    expect(find.textContaining('¿Quién paga?'), findsNothing);
    expect(find.byType(FilterChip), findsNothing);
  });

  testWidgets('modo puntos muestra el resumen en fichas, sin "bebe"', (
    tester,
  ) async {
    await _pump(tester, _game());
    await tester.tap(find.byKey(const ValueKey('pay-p3')));
    await tester.pump();
    expect(find.text('−1 en la Copa: Eva'), findsOneWidget);
    expect(find.textContaining('bebe', findRichText: true), findsNothing);
  });

  testWidgets('modo retos usa ConsequenceBanner con el mazo de retos', (
    tester,
  ) async {
    await _pump(tester, _game(), mode: 'retos');
    await tester.tap(find.byKey(const ValueKey('pay-p1')));
    await tester.pumpAndSettle();
    expect(find.text('1 reto'), findsOneWidget);
    expect(find.text('Reto de prueba'), findsOneWidget);
  });

  testWidgets('estilo question: prefijo fijo y cierre con "?"', (tester) async {
    await _pump(
      tester,
      _game(payMode: PromptPayMode.single, style: PromptCardStyle.question),
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
    expect(find.text('Marca al más votado'), findsOneWidget);
  });

  testWidgets('cerrar la partida registra las fichas de la carta actual', (
    tester,
  ) async {
    final c = await _pump(tester, _game());
    await tester.tap(find.byKey(const ValueKey('pay-p2')));
    await tester.pump();
    await tester.tap(find.byTooltip('Salir'));
    await tester.pumpAndSettle();
    // Pide confirmación: "Seguir" se queda y no registra nada todavía.
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    await tester.tap(find.text('Seguir'));
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsNothing);
    expect(c.read(sessionProvider).events, isEmpty);

    // Atrás del sistema (también el predictivo): mismo diálogo; "Salir" conserva las fichas.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(c.read(sessionProvider).events.map((e) => e.playerId), ['p2']);
    expect(find.text('inicio'), findsOneWidget);
  });

  for (final mode in [null, 'retos', 'sorbos']) {
    testWidgets('marcar a alguien no mueve la carta (modo $mode)', (
      tester,
    ) async {
      await _pump(tester, _game(), mode: mode);
      final before =
          tester.getSize(find.text('regla').first).height +
          tester.getTopLeft(find.text('regla').first).dy;
      await tester.tap(find.byKey(const ValueKey('pay-p3')));
      await tester.pumpAndSettle();
      final after =
          tester.getSize(find.text('regla').first).height +
          tester.getTopLeft(find.text('regla').first).dy;
      expect(after, before);
    });
  }
}
