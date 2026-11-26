import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/app/mascot.dart';
import 'package:habinson/app/theme.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/geography/domain/country.dart';
import 'package:habinson/games/geography/domain/geo_map.dart';
import 'package:habinson/games/geography/domain/quiz.dart';
import 'package:habinson/games/geography/geo_data.dart';
import 'package:habinson/games/geography/geo_store.dart';
import 'package:habinson/games/geography/ui/geo_quiz_screen.dart';
import 'package:habinson/games/geography/ui/geo_result_screen.dart';
import 'package:habinson/games/geography/ui/geo_setup_screen.dart';
import 'package:habinson/games/geography/ui/geo_widgets.dart';
import 'package:habinson/games/trivia/trivia_data.dart';
import 'package:habinson/games/trivia/ui/quiz_fx.dart';
import 'package:habinson/games/trivia/ui/trivia_quiz_screen.dart';
import 'package:habinson/games/trivia/ui/trivia_result_screen.dart';
import 'package:habinson/games/trivia/ui/trivia_setup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pantallas de Trivia y Geografía: escala de resultado, estados vacíos y que
/// nada desborde con letra 2.0 en 320x568 (con y sin animaciones).
void main() {
  final bank = parseTrivia(File(triviaAsset).readAsStringSync());

  // El contenido de Geografía se lee del disco en el propio test: la carga de
  // assets del motor de test no es fiable entre tests seguidos.
  final countries = [
    for (final j
        in (jsonDecode(
              File(
                'assets/content/es/geografia/paises.json',
              ).readAsStringSync(),
            )['items']
            as List))
      Country.fromJson(j as Map<String, dynamic>),
  ];
  GeoMap loadMap(String id) => GeoMap.fromJson(
    jsonDecode(
          File('assets/content/es/geografia/mapas/$id.json').readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final geoOverrides = <Override>[
    countriesProvider.overrideWith((ref) async => countries),
    silhouettesProvider.overrideWith((ref) async => <String, Silhouette>{}),
    geoMapProvider.overrideWith((ref, id) async => loadMap(id)),
  ];

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
    Map<String, Object> prefs = const {},
    double scale = 2.0,
    Size size = const Size(320, 568),
    bool noAnimations = false,
    String initialLocation = '/',
  }) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: '/game/trivia/play',
          builder: (_, _) => const TriviaQuizScreen(),
        ),
        GoRoute(
          path: '/game/trivia/result',
          builder: (_, _) => const TriviaResultScreen(),
        ),
        GoRoute(
          path: '/game/geografia',
          builder: (_, _) => const GeoSetupScreen(),
        ),
        GoRoute(
          path: '/game/geografia/play',
          builder: (_, _) => const GeoQuizScreen(),
        ),
        GoRoute(
          path: '/game/geografia/result',
          builder: (_, _) => const GeoResultScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: noAnimations,
            ),
            child: child!,
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    return container;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(f);
  }

  group('escala de resultado', () {
    test('Pleno / Gran carrera / En el podio / Hoy no era tu carrera', () {
      expect(QuizTier.of(10, 10), QuizTier.pleno);
      expect(QuizTier.of(9, 10), QuizTier.granCarrera);
      expect(QuizTier.of(8, 10), QuizTier.granCarrera);
      expect(QuizTier.of(7, 10), QuizTier.enElPodio);
      expect(QuizTier.of(5, 10), QuizTier.enElPodio);
      expect(QuizTier.of(4, 10), QuizTier.hoyNo);
      expect(QuizTier.of(0, 10), QuizTier.hoyNo);
      expect(QuizTier.of(0, 0), QuizTier.hoyNo);
      expect(
        [for (final t in QuizTier.values) t.label],
        ['Pleno', 'Gran carrera', 'En el podio', 'Hoy no era tu carrera'],
      );
    });
  });

  for (final noAnim in [false, true]) {
    group('animaciones', () {
      Widget host(bool active, bool noAnim) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: noAnim),
          child: Shake(
            active: active,
            child: const SizedBox(key: Key('x'), width: 10, height: 10),
          ),
        ),
      );

      double dx(WidgetTester tester) =>
          tester.getTopLeft(find.byKey(const Key('x'))).dx;

      testWidgets('la sacudida mueve el widget y termina en su sitio', (
        tester,
      ) async {
        await tester.pumpWidget(host(false, false));
        final home = dx(tester);
        await tester.pumpWidget(host(true, false));
        await tester.pump(const Duration(milliseconds: 40));
        expect(dx(tester), isNot(home));
        await tester.pump(const Duration(milliseconds: 600));
        expect(dx(tester), home);
      });

      testWidgets('con animaciones desactivadas no se mueve', (tester) async {
        await tester.pumpWidget(host(false, true));
        final home = dx(tester);
        await tester.pumpWidget(host(true, true));
        await tester.pump(const Duration(milliseconds: 40));
        expect(dx(tester), home);
      });
    });

    group('tarjeta de resultado (sin animaciones: $noAnim)', () {
      for (final (correct, total) in [
        (10, 10),
        (8, 10),
        (5, 10),
        (1, 10),
        (0, 1),
      ]) {
        testWidgets('$correct de $total no desborda a 2.0 en 320x568', (
          tester,
        ) async {
          await pumpScreen(
            tester,
            Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  QuizResultCard(
                    correct: correct,
                    total: total,
                    stub: const QuizStubBadge(text: 'Nuevo récord'),
                  ),
                ],
              ),
            ),
            noAnimations: noAnim,
          );
          await settle(tester);
          final tier = QuizTier.of(correct, total);
          expect(find.text(tier.label), findsOneWidget);
          // El Jockey celebra solo en un pleno.
          expect(
            find.byType(Jockey),
            tier == QuizTier.pleno ? findsOneWidget : findsNothing,
          );
          expect(find.text('$correct'), findsOneWidget);
        });
      }
    });
  }

  group('Trivia', () {
    final bankOverride = triviaBankProvider.overrideWith((ref) async => bank);

    testWidgets('sin partida: estado vacío con el Jockey neutral', (
      tester,
    ) async {
      await pumpScreen(tester, const TriviaResultScreen());
      expect(find.text('Aquí no hay partida'), findsOneWidget);
      expect(find.byType(Jockey), findsOneWidget);
      expect(
        tester.widget<Jockey>(find.byType(Jockey)).pose,
        JockeyPose.neutral,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('resultado: texto de la casa, boleto y fallos', (tester) async {
      final c = await pumpScreen(
        tester,
        const TriviaResultScreen(),
        scale: 1.0,
      );
      final q = bank.first.shuffled(DeterministicRandom());
      c
          .read(lastTriviaResultProvider.notifier)
          .set(
            TriviaResult(
              roundId: 'trivia-1',
              total: 10,
              correct: 7,
              mistakes: [TriviaMistake(q, q.wrong.first)],
            ),
          );
      await settle(tester);
      expect(find.text('En el podio'), findsOneWidget);
      expect(find.text('1 fallo'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('FALLOS'), 200);
      expect(find.text('Dijiste: ${q.wrong.first}'), findsOneWidget);
      expect(find.text('Otra vuelta'), findsOneWidget);
    });

    testWidgets('sin preguntas: estado vacío en vez de romper', (tester) async {
      await pumpScreen(
        tester,
        const TriviaQuizScreen(),
        overrides: [
          triviaBankProvider.overrideWith(
            (ref) async => const <TriviaQuestion>[],
          ),
        ],
      );
      await settle(tester);
      expect(find.text('Sin preguntas con estos filtros'), findsOneWidget);
      expect(find.byType(Jockey), findsOneWidget);
    });

    for (final noAnim in [false, true]) {
      testWidgets('partida completa sin overflow (sin animaciones: $noAnim)', (
        tester,
      ) async {
        await pumpScreen(
          tester,
          const TriviaQuizScreen(),
          overrides: [bankOverride],
          prefs: {
            'trivia.setup.v1': jsonEncode(const TriviaSetup(count: 3).toJson()),
          },
          noAnimations: noAnim,
        );
        await settle(tester);
        expect(find.text('Pregunta 1'), findsOneWidget);
        expect(find.text('1 / 3'), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        // Las opciones llevan letra y estado para lectores de pantalla.
        expect(find.bySemanticsLabel(RegExp(r'^A\. ')), findsOneWidget);

        for (var i = 0; i < 3; i++) {
          // Toca la primera opción (acierte o falle: ambos estados no deben desbordar).
          await tapVisible(tester, find.byType(QuizOptionTile).first);
          await settle(tester);
          await tapVisible(tester, find.byType(FilledButton).last);
          await settle(tester);
        }
        await tester.scrollUntilVisible(find.text('Otra vuelta'), 300);
        expect(find.text('Otra vuelta'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('ajustes: categorías con icono propio y sin emoji', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const TriviaSetupScreen(),
        overrides: [bankOverride],
      );
      await settle(tester);
      for (final c in TriviaCategory.values) {
        expect(find.text(c.label), findsOneWidget);
      }
      expect(
        find.byType(CategoryIcon),
        findsNWidgets(TriviaCategory.values.length),
      );
    });
  });

  group('Geografía', () {
    Map<String, Object> setupPrefs(GeoCategory cat, AnswerMode mode) => {
      'geo.setup.v1': jsonEncode(
        GeoSetup(category: cat, mode: mode, count: 3).toJson(),
      ),
    };

    for (final noAnim in [false, true]) {
      for (final cat in [
        GeoCategory.flags,
        GeoCategory.capitals,
        GeoCategory.owners,
        GeoCategory.silhouettes,
        GeoCategory.usStates,
      ]) {
        for (final mode in AnswerMode.values) {
          testWidgets(
            '${cat.name} / ${mode.name} sin overflow (sin animaciones: $noAnim)',
            (tester) async {
              await pumpScreen(
                tester,
                const GeoQuizScreen(),
                overrides: geoOverrides,
                prefs: setupPrefs(cat, mode),
                noAnimations: noAnim,
              );
              await settle(tester);
              expect(find.text('Pregunta 1'), findsOneWidget);
              expect(find.text('1 / 3'), findsNothing);
              expect(find.byType(LinearProgressIndicator), findsNothing);
              switch (mode) {
                case AnswerMode.options:
                  expect(find.byType(QuizOptionTile), findsNWidgets(4));
                  await tapVisible(tester, find.byType(QuizOptionTile).first);
                case AnswerMode.reveal:
                  await tapVisible(tester, find.text('Ver respuesta'));
                case AnswerMode.typed:
                  await tester.enterText(find.byType(TextField), 'zzz');
                  await tapVisible(tester, find.text('Comprobar'));
              }
              await settle(tester);
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('racha: llama de la casa a partir de 2 aciertos seguidos', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const GeoQuizScreen(),
        overrides: geoOverrides,
        prefs: setupPrefs(GeoCategory.flags, AnswerMode.reveal),
      );
      await settle(tester);
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Ver respuesta'));
        await settle(tester);
        await tester.tap(find.text('Acerté'));
        await settle(tester);
      }
      expect(find.bySemanticsLabel('Racha de 2 aciertos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('categorías de mapa usan la bandera real, el resto el icono', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const GeoSetupScreen(),
        overrides: geoOverrides,
        scale: 1.0,
        size: const Size(400, 1400),
      );
      await settle(tester);
      // 4 banderas (EE. UU., México, España, Japón) y 5 iconos de categoría.
      expect(find.byType(SvgPicture), findsNWidgets(4));
      expect(find.byType(CategoryIcon), findsNWidgets(5));
      expect(
        find.byType(GeoCategoryIcon),
        findsNWidgets(GeoCategory.values.length),
      );
      for (final c in GeoCategory.values) {
        expect(c.isMap ? c.flagIso : c.iconId, isNotNull, reason: c.name);
      }
    });

    for (final record in [true, false]) {
      testWidgets('resultado (récord: $record) sin overflow', (tester) async {
        final c = await pumpScreen(tester, const GeoResultScreen());
        final setup = const GeoSetup(count: 10);
        c
            .read(lastQuizResultProvider.notifier)
            .set(
              QuizResult(
                roundId: 'geografia-1',
                setup: setup,
                total: 10,
                correct: 10,
                mistakes: const [],
                newRecord: record,
                best: 10,
              ),
            );
        await settle(tester);
        expect(find.text('Pleno'), findsOneWidget);
        expect(
          find.text(record ? 'Nuevo récord' : 'Tu récord: 10/10'),
          findsOneWidget,
        );
        expect(find.text('Otra vuelta'), findsOneWidget);
        expect(find.byType(Jockey), findsOneWidget);
      });
    }

    testWidgets('resultado sin partida: vacío con el Jockey neutral', (
      tester,
    ) async {
      await pumpScreen(tester, const GeoResultScreen());
      expect(find.text('Aquí no hay partida'), findsOneWidget);
      expect(
        tester.widget<Jockey>(find.byType(Jockey)).pose,
        JockeyPose.neutral,
      );
    });
  });

  group('preparación: cabecera con héroe y letra grande', () {
    final bankOverride = triviaBankProvider.overrideWith((ref) async => bank);

    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('Trivia con letra $scale en 320x568', (tester) async {
        await pumpScreen(
          tester,
          const TriviaSetupScreen(),
          overrides: [bankOverride],
          scale: scale,
        );
        await settle(tester);
        expect(find.byType(GameIcon), findsOneWidget);
        expect(
          find.text('Cuatro opciones, una buena. La casa no da pistas.'),
          findsOneWidget,
        );
        final title = tester.renderObject<RenderParagraph>(find.text('Trivia'));
        expect(title.didExceedMaxLines, isFalse);
        for (final t in ['Categorías', 'Nivel', 'Cuántas preguntas']) {
          expect(find.text(t.toUpperCase()), findsOneWidget);
        }
      });

      testWidgets('Geografía con letra $scale en 320x568', (tester) async {
        await pumpScreen(
          tester,
          const GeoSetupScreen(),
          overrides: geoOverrides,
          scale: scale,
        );
        await settle(tester);
        expect(find.byType(GameIcon), findsOneWidget);
        expect(
          find.text('Banderas, capitales y mapas. La casa no regala atlas.'),
          findsOneWidget,
        );
        final title = tester.renderObject<RenderParagraph>(
          find.text('Geografía'),
        );
        expect(title.didExceedMaxLines, isFalse);
        expect(find.text('DIFICULTAD'), findsOneWidget);
        expect(find.text('Fácil'), findsOneWidget);
      });
    }

    testWidgets('la letra de la opción mide 20 px o más en Alfa Slab One', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        Scaffold(
          body: QuizOptionTile(
            label: 'Madrid',
            letter: 'A',
            state: QuizOptionState.idle,
            onTap: () {},
          ),
        ),
        scale: 1.0,
      );
      final letter = tester.widget<Text>(find.text('A'));
      expect(letter.style!.fontSize, greaterThanOrEqualTo(20));
      expect(letter.style!.fontFamily, AppFonts.display);
    });
  });
}

/// `Random` fijo para barajar sin depender de la semilla.
class DeterministicRandom implements Random {
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
  @override
  int nextInt(int max) => 0;
}
