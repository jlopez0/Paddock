import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/theme.dart';
import 'package:paddock/core/audio/app_sound.dart';
import 'package:paddock/core/players/players_screen.dart';
import 'package:paddock/core/settings/app_feedback.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/horse_race/ui/race_setup_screen.dart';
import 'package:paddock/games/trivia/trivia_data.dart';
import 'package:paddock/games/trivia/ui/quiz_fx.dart';
import 'package:paddock/games/trivia/ui/trivia_quiz_screen.dart';
import 'package:paddock/games/trivia/ui/trivia_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los sonidos están enganchados donde toca y respetan solo el ajuste de Sonido.
class _FakeBackend implements SoundBackend {
  final played = <AppSound>[];

  @override
  Future<void> play(AppSound sound) async => played.add(sound);

  @override
  Future<void> preload(AppSound sound) async {}
}

void main() {
  late _FakeBackend fake;

  setUp(() {
    fake = _FakeBackend();
    AppSoundService.useBackend(fake);
    AppFeedback.soundEnabled = true;
  });

  tearDown(() => AppFeedback.soundEnabled = true);

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    Map<String, Object> prefs = const {},
    List<Override> overrides = const [],
    bool reduce = false,
    Size size = const Size(400, 2400),
  }) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp), ...overrides],
    );
    addTearDown(c.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(path: '/game/trivia/result', builder: (_, _) => const TriviaResultScreen()),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: child!,
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    return c;
  }

  String players(int n) => jsonEncode([
    for (var i = 0; i < n; i++) {'id': 'p$i', 'name': ['Ana', 'Luis', 'Eva', 'Pepe'][i], 'color': i},
  ]);

  group('Carrera', () {
    testWidgets('chip al subir y bajar la apuesta y al elegir All-in (no al quitarlo)', (tester) async {
      await pump(tester, const RaceSetupScreen(), prefs: {'players.v1': players(2)});
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played, isEmpty);

      await tester.tap(find.byTooltip('Una ficha más'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played, [AppSound.chip]);

      await tester.tap(find.byTooltip('Una ficha menos'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played, [AppSound.chip, AppSound.chip]);

      await tester.tap(find.textContaining('All-in'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played.length, 3);

      await tester.tap(find.textContaining('All-in')); // lo quita: en silencio
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played.length, 3);
    });

    testWidgets('con el sonido desactivado no suena nada', (tester) async {
      AppFeedback.soundEnabled = false;
      await pump(tester, const RaceSetupScreen(), prefs: {'players.v1': players(2)});
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byTooltip('Una ficha más'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played, isEmpty);
    });

    testWidgets('con "reducir animaciones" el sonido sigue el ajuste de Sonido', (tester) async {
      await pump(tester, const RaceSetupScreen(), prefs: {'players.v1': players(2)}, reduce: true);
      await tester.tap(find.widgetWithText(FilterChip, 'Ana'));
      await tester.pump();
      await tester.tap(find.byTooltip('Una ficha más'));
      await tester.pump();
      expect(fake.played, [AppSound.chip]);
    });
  });

  group('Trivia', () {
    final bank = parseTrivia(File(triviaAsset).readAsStringSync());

    testWidgets('responder suena correct o wrong, una sola vez por pregunta', (tester) async {
      await pump(
        tester,
        const TriviaQuizScreen(),
        overrides: [triviaBankProvider.overrideWith((ref) async => bank)],
        prefs: {'trivia.setup.v1': jsonEncode(const TriviaSetup(count: 3).toJson())},
        size: const Size(400, 900),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played, isEmpty);
      await tester.tap(find.byType(QuizOptionTile).first);
      await tester.pump(const Duration(milliseconds: 300));
      expect(fake.played.length, 1);
      expect(fake.played.single, anyOf(AppSound.correct, AppSound.wrong));
    });

    for (final c in [(10, 10, true), (9, 10, true), (6, 10, false), (2, 10, false)]) {
      testWidgets('tarjeta de resultado ${c.$1}/${c.$2}: podio solo con Pleno o Gran carrera', (tester) async {
        await pump(
          tester,
          Scaffold(body: QuizResultCard(correct: c.$1, total: c.$2, stub: const Text('x'))),
          size: const Size(400, 900),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(fake.played, c.$3 ? [AppSound.podium] : isEmpty);
      });
    }
  });

  group('Jugadores', () {
    testWidgets('añadir un jugador suena chipSoft; un nombre vacío o repetido no', (tester) async {
      await pump(tester, const PlayersScreen(), size: const Size(400, 900));
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pump();
      expect(fake.played, isEmpty);

      await tester.enterText(find.byType(TextField), 'Ana');
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pump();
      expect(fake.played, [AppSound.chipSoft]);

      await tester.enterText(find.byType(TextField), 'ana');
      await tester.tap(find.byTooltip('Añadir'));
      await tester.pump();
      expect(fake.played, [AppSound.chipSoft]);
    });
  });
}
