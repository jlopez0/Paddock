import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/theme.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/core/players/players_controller.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/infiltrado/domain/infiltrado_engine.dart';
import 'package:paddock/games/infiltrado/infiltrado_module.dart';
import 'package:paddock/games/infiltrado/infiltrado_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 11, 24, 22);
const _module = InfiltradoModule();
const _names = ['Ana', 'Luis', 'Eva', 'Pepe'];

class _Env {
  _Env(this.c, this.router, this.ids);
  final ProviderContainer c;
  final GoRouter router;
  final Map<String, String> ids; // nombre -> id

  InfiltradoGame get game => c.read(infiltradoGameProvider)!;
  String nameOf(String id) => ids.entries.firstWhere((e) => e.value == id).key;
}

Future<_Env> _pump(
  WidgetTester tester, {
  List<String> players = _names,
  List<InfiltradoWord> words = kFallbackWords,
  String location = '/game/infiltrado',
  Size size = const Size(400, 900),
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      sessionClockProvider.overrideWithValue(() => _now),
      infiltradoRandomProvider.overrideWithValue(Random(7)),
      infiltradoWordsProvider.overrideWith((ref) async => words),
    ],
  );
  addTearDown(c.dispose);
  final ids = {for (final n in players) n: c.read(playersProvider.notifier).add(n).id};

  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(body: Text('MENU')),
        routes: [
          GoRoute(path: 'copa', builder: (_, _) => const Scaffold(body: Text('COPA'))),
          GoRoute(
            path: 'game/infiltrado',
            builder: (context, _) => _module.buildEntry(context),
            routes: _module.subRoutes,
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: disableAnimations,
          ),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Env(c, router, ids);
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final f = find.text(text);
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
  }
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Recorre la revelación comprobando que nadie ve la palabra antes de tiempo.
Future<void> _reveal(WidgetTester tester, _Env env) async {
  final game = env.game;
  final word = game.deal.word;
  for (final id in game.deal.players) {
    final name = env.nameOf(id);
    // Tarjeta tapada: solo el nombre, jamás la palabra.
    expect(find.text('Pasa el móvil a'), findsOneWidget);
    expect(find.text(name), findsOneWidget);
    expect(find.text(word), findsNothing);
    expect(find.text('Eres el infiltrado'), findsNothing);

    await _tapText(tester, 'Soy $name, ver mi tarjeta');
    if (game.deal.impostors.contains(id)) {
      expect(find.text('Eres el infiltrado'), findsOneWidget);
      expect(find.text(word), findsNothing, reason: 'el infiltrado nunca ve la palabra');
    } else {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.text(game.deal.category), findsOneWidget);
    final last = id == game.deal.players.last;
    await _tapText(tester, last ? 'Ocultar y empezar el debate' : 'Ocultar y pasar el móvil');
    expect(find.text(word), findsNothing);
  }
}

Future<void> _vote(WidgetTester tester, _Env env, Map<String, String> votes) async {
  for (final id in env.game.deal.players) {
    final name = env.nameOf(id);
    await _tapText(tester, 'Soy $name, votar');
    await _tapText(tester, env.nameOf(votes[id]!));
    await _tapText(tester, 'Confirmar voto');
  }
}

void main() {
  group('palabras y configuración', () {
    test('parseInfiltradoWords ignora entradas incompletas o con nivel desconocido', () {
      final words = parseInfiltradoWords('''
{ "version": 1, "items": [
  {"id": "inf_001", "nivel": "suave", "categoria": "Comida", "palabra": "Tortilla"},
  {"id": "inf_002", "nivel": "hot", "categoria": "Lugares", "palabra": "Discoteca"},
  {"id": "inf_003", "nivel": "suave", "categoria": "", "palabra": "Vacía"},
  {"id": "inf_004", "nivel": "raro", "categoria": "X", "palabra": "Y"},
  {"id": "inf_005", "nivel": "suave", "categoria": "X"}
]}''');
      expect(words.map((w) => w.id), ['inf_001', 'inf_002']);
      expect(words[1].level, PromptLevel.atrevido);
    });

    test('InfiltradoSetup se guarda y se lee, y sanea valores raros', () {
      const s = InfiltradoSetup(
        playerIds: {'a', 'b', 'c'},
        impostors: 2,
        levels: {PromptLevel.suave, PromptLevel.picante},
        debateSeconds: 180,
      );
      final back = InfiltradoSetup.fromJson(s.toJson());
      expect(back.playerIds, {'a', 'b', 'c'});
      expect(back.impostors, 2);
      expect(back.levels, {PromptLevel.suave, PromptLevel.picante});
      expect(back.debateSeconds, 180);

      final odd = InfiltradoSetup.fromJson({'impostors': 9, 'levels': <String>[], 'debate': 7});
      expect(odd.playerIds, isNull);
      expect(odd.impostors, 2);
      expect(odd.levels, {PromptLevel.suave});
      expect(odd.debateSeconds, 0);
    });
  });

  group('configuración', () {
    testWidgets('menos de 3 jugadores: botón desactivado y aviso', (tester) async {
      await _pump(tester, players: ['Ana', 'Luis']);
      expect(find.text('Elige al menos 3 jugadores'), findsOneWidget);
      expect(find.textContaining('Hacen falta al menos 3'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Elige al menos 3 jugadores'));
      expect(button.onPressed, isNull);
    });

    testWidgets('palabras agotadas: aviso y botón para reiniciar', (tester) async {
      final env = await _pump(tester);
      for (final w in kFallbackWords) {
        env.c.read(infiltradoUsedProvider.notifier).add(w.id);
      }
      await tester.pumpAndSettle();
      expect(find.text('No quedan palabras'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('No quedan palabras con estos niveles.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('No quedan palabras con estos niveles.'), findsOneWidget);

      await _tapText(tester, 'Barajar todas de nuevo');
      expect(find.text('Repartir roles'), findsOneWidget);
    });

    testWidgets('con 4 jugadores solo se permite 1 infiltrado', (tester) async {
      await _pump(tester);
      expect(find.text('Con 2 infiltrados hacen falta 5 jugadores o más.'), findsOneWidget);
    });
  });

  group('partida completa', () {
    testWidgets('4 jugadores: revelación privada, votación, última oportunidad y Copa', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      expect(game.deal.players, hasLength(4));
      expect(game.deal.impostors, hasLength(1));
      final impostor = game.deal.impostors.single;

      await _reveal(tester, env);

      // Todos votan al infiltrado; el infiltrado vota a otro.
      final other = game.deal.civils.first;
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == impostor ? other : impostor,
      });

      // Pillado: última oportunidad antes de ver la palabra.
      expect(find.text('Última oportunidad'), findsOneWidget);
      expect(find.text(game.deal.word), findsNothing);
      await tester.enterText(find.byType(TextField), 'palabra equivocada');
      await _tapText(tester, 'Comprobar');

      expect(find.text('¡Lo habéis pillado!'), findsOneWidget);
      expect(find.text(game.deal.word), findsOneWidget);
      expect(find.text('−2 en la Copa'), findsOneWidget);

      final events = env.c.read(sessionProvider).events;
      expect(events, hasLength(1));
      expect(events.single.playerId, impostor);
      expect(events.single.delta, -2);
      expect(events.single.gameId, 'infiltrado');
      // La palabra usada no vuelve a salir en la siguiente ronda.
      expect(env.c.read(infiltradoUsedProvider), hasLength(1));
    });

    testWidgets('si el infiltrado acierta la palabra gana y los demás pierden 1', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      final impostor = game.deal.impostors.single;
      await _reveal(tester, env);
      final other = game.deal.civils.first;
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == impostor ? other : impostor,
      });

      await tester.enterText(find.byType(TextField), game.deal.word.toUpperCase());
      await _tapText(tester, 'Comprobar');
      expect(find.text('¡Acertó la palabra!'), findsOneWidget);

      final events = env.c.read(sessionProvider).events;
      expect(events, hasLength(3));
      expect(events.every((e) => e.delta == -1 && e.playerId != impostor), isTrue);
    });

    testWidgets('si no lo pillan, va directo al resultado y suma a la Copa una sola vez', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      final impostor = game.deal.impostors.single;
      await _reveal(tester, env);

      // Todos votan a un civil (los civiles a otro civil distinto de sí mismos).
      final civils = game.deal.civils.toList();
      final scapegoat = civils.first;
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == scapegoat ? civils.last : scapegoat,
      });

      expect(find.text('Última oportunidad'), findsNothing);
      expect(find.text('El infiltrado se escapa'), findsOneWidget);
      expect(find.text(game.deal.word), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fichas anotadas en la Copa de la noche.'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Fichas anotadas en la Copa de la noche.'), findsOneWidget);
      final events = env.c.read(sessionProvider).events;
      expect(events, hasLength(3));
      expect(events.any((e) => e.playerId == impostor), isFalse);

      // Otra ronda: nueva palabra y nuevo roundId, sin tocar lo anterior.
      await _tapText(tester, 'Otra ronda');
      expect(find.text('Pasa el móvil a'), findsOneWidget);
      expect(env.game.roundId, isNot(game.roundId));
      expect(env.game.deal.word, isNot(game.deal.word));
    });

    testWidgets('empate: segunda votación solo entre los empatados', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final players = env.game.deal.players;
      await _reveal(tester, env);

      final a = players[0], b = players[1], c = players[2], d = players[3];
      await _vote(tester, env, {a: b, b: a, c: b, d: a});

      expect(find.text('¡Empate!'), findsOneWidget);
      expect(
        find.text('Se vuelve a votar solo entre ${env.nameOf(a)} y ${env.nameOf(b)}.'),
        findsOneWidget,
      );
      await _tapText(tester, 'Segunda votación');

      // c solo puede votar a a o b (no a d).
      await _tapText(tester, 'Soy ${env.nameOf(a)}, votar');
      expect(find.text(env.nameOf(b)), findsOneWidget);
      expect(find.text(env.nameOf(c)), findsNothing);
      expect(find.text(env.nameOf(d)), findsNothing);
      await _tapText(tester, env.nameOf(b));
      await _tapText(tester, 'Confirmar voto');
      await _tapText(tester, 'Soy ${env.nameOf(b)}, votar');
      await _tapText(tester, env.nameOf(a));
      await _tapText(tester, 'Confirmar voto');
      await _tapText(tester, 'Soy ${env.nameOf(c)}, votar');
      expect(find.text(env.nameOf(d)), findsNothing);
      await _tapText(tester, env.nameOf(a));
      await _tapText(tester, 'Confirmar voto');
      await _tapText(tester, 'Soy ${env.nameOf(d)}, votar');
      await _tapText(tester, env.nameOf(a));
      await _tapText(tester, 'Confirmar voto');

      // Acusado: a. Según su rol, última oportunidad o resultado directo.
      final caught = env.game.deal.impostors.contains(a);
      expect(find.text(caught ? 'Última oportunidad' : 'Resultado'), findsOneWidget);
    });
  });

  group('debate', () {
    testWidgets('temporizador opcional: cuenta atrás y pasa a votar', (tester) async {
      final env = await _pump(tester);
      env.c.read(infiltradoSetupProvider.notifier).set(const InfiltradoSetup(debateSeconds: 120));
      await _tapText(tester, 'Repartir roles');
      await _reveal(tester, env);

      expect(find.text('2:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('1:59'), findsOneWidget);

      await _tapText(tester, 'A votar');
      expect(find.text('Voto 1 de 4'), findsOneWidget);
    });
  });

  group('diseño con alma', () {
    testWidgets('sello del resultado: SALVADOS si lo pillan, INFILTRADO si se escapa', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      final impostor = game.deal.impostors.single;
      await _reveal(tester, env);
      final other = game.deal.civils.first;
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == impostor ? other : impostor,
      });
      await _tapText(tester, 'Ni idea');
      expect(find.text('SALVADOS'), findsOneWidget);
      expect(find.text('INFILTRADO'), findsNothing);
    });

    testWidgets('sello INFILTRADO cuando el infiltrado se escapa', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      await _reveal(tester, env);
      final civils = game.deal.civils.toList();
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == civils.first ? civils.last : civils.first,
      });
      expect(find.text('INFILTRADO'), findsOneWidget);
      expect(find.text('SALVADOS'), findsNothing);
    });

    for (final disable in [false, true]) {
      testWidgets(
        'partida completa en 320x568 con texto x2 sin desbordes (animaciones ${disable ? 'off' : 'on'})',
        (tester) async {
          final env = await _pump(
            tester,
            size: const Size(320, 568),
            textScale: 2,
            disableAnimations: disable,
          );
          await _tapText(tester, 'Repartir roles');
          final game = env.game;
          final impostor = game.deal.impostors.single;
          await _reveal(tester, env);
          final other = game.deal.civils.first;
          await _vote(tester, env, {
            for (final id in game.deal.players) id: id == impostor ? other : impostor,
          });
          expect(find.text('Última oportunidad'), findsOneWidget);
          await _tapText(tester, 'Ni idea');
          expect(find.text('SALVADOS'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('sin partida y con texto x2 tampoco desborda', (tester) async {
      await _pump(
        tester,
        location: '/game/infiltrado/result',
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(find.text('Nadie está disimulando ahora mismo.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('ni un emoji en el código del Infiltrado', () {
      final emoji = RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{2B50}\u{2B55}]', unicode: true);
      for (final f in Directory('lib/games/infiltrado').listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart')) continue;
        expect(emoji.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
      }
    });
  });

  group('salir y estados vacíos', () {
    testWidgets('el botón de salir y el atrás piden confirmación', (tester) async {
      final env = await _pump(tester);
      await _tapText(tester, 'Repartir roles');
      expect(find.text('Pasa el móvil a'), findsOneWidget);

      // Botón solo con icono: tiene etiqueta accesible.
      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.byTooltip('Salir de la partida'));
      expect(node.tooltip, 'Salir de la partida');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();

      // Botón de cerrar: diálogo, "Seguir" se queda.
      await tester.tap(find.byTooltip('Salir de la partida'));
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await _tapText(tester, 'Seguir');
      expect(find.text('Pasa el móvil a'), findsOneWidget);

      // Atrás del sistema (también el predictivo): mismo diálogo.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await _tapText(tester, 'Salir');
      expect(find.text('Repartir roles'), findsOneWidget);
      expect(env.router.state.matchedLocation, '/game/infiltrado');
    });

    testWidgets('sin partida en curso no se enseña nada y se ofrece preparar una', (tester) async {
      await _pump(tester, location: '/game/infiltrado/reveal');
      expect(find.text('Nadie está disimulando ahora mismo.'), findsOneWidget);
      await _tapText(tester, 'Preparar partida');
      expect(find.text('Repartir roles'), findsOneWidget);
    });

    testWidgets('palabras agotadas al pedir otra ronda: vuelve a la configuración', (tester) async {
      final env = await _pump(tester, words: [kFallbackWords.first]);
      await _tapText(tester, 'Repartir roles');
      final game = env.game;
      await _reveal(tester, env);
      final civils = game.deal.civils.toList();
      await _vote(tester, env, {
        for (final id in game.deal.players) id: id == civils.first ? civils.last : civils.first,
      });
      await _tapText(tester, 'Otra ronda');
      expect(find.text('No quedan palabras'), findsOneWidget);
    });
  });

  test('el motor sigue exigiendo 3 jugadores', () {
    expect(InfiltradoEngine.minPlayers, 3);
  });
}
