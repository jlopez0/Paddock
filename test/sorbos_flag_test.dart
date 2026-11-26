import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/credits_screen.dart';
import 'package:habinson/app/home_screen.dart';
import 'package:habinson/app/router.dart';
import 'package:habinson/core/consequences/consequence_banner.dart';
import 'package:habinson/core/consequences/consequence_mode_selector.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/consequences/sorbos_flag.dart';
import 'package:habinson/core/help/how_to_play.dart';
import 'package:habinson/core/settings/settings_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/horse_race/race_texts.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Compilación sin modo Sorbos (`--dart-define=SORBOS=false`, pensada para iOS).
// Un `const bool.fromEnvironment` no se puede cambiar en un test: el flag se
// inyecta con `sorbosEnabledProvider` (su valor por defecto es `kSorbosEnabled`).

Future<ProviderContainer> _container(
  Map<String, Object> initial, {
  bool? sorbos,
}) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (sorbos != null) sorbosEnabledProvider.overrideWithValue(sorbos),
    ],
  );
}

Future<ProviderContainer> _pump(
  WidgetTester tester,
  Widget home, {
  required bool sorbos,
  Map<String, Object> prefsValues = const {},
}) async {
  final c = await _container(prefsValues, sorbos: sorbos);
  addTearDown(c.dispose);
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: home),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

void main() {
  group('flag y lectura de preferencias', () {
    test('por defecto el proveedor vale kSorbosEnabled', () async {
      final c = await _container({});
      addTearDown(c.dispose);
      expect(c.read(sorbosEnabledProvider), kSorbosEnabled);
      expect(
        kSorbosEnabled,
        const bool.fromEnvironment('SORBOS', defaultValue: true),
      );
    });

    test('con Sorbos activo todo sigue igual: se guarda y se lee', () async {
      final c = await _container({}, sorbos: true);
      addTearDown(c.dispose);
      c.read(settingsProvider.notifier)
        ..confirmAdult()
        ..setConsequenceMode(ConsequenceMode.sorbos);
      expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.sorbos);
    });

    test('sin Sorbos, setConsequenceMode(sorbos) no hace nada', () async {
      final c = await _container({
        'settings.adultConfirmed.v1': true,
      }, sorbos: false);
      addTearDown(c.dispose);
      final n = c.read(settingsProvider.notifier);
      n.setConsequenceMode(ConsequenceMode.sorbos);
      expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
      expect(
        c
            .read(sharedPreferencesProvider)
            .getString('settings.consequenceMode.v1'),
        isNull,
        reason: 'no debe guardarse nada',
      );
      // Retos sigue funcionando.
      n.setConsequenceMode(ConsequenceMode.retos);
      expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.retos);
    });

    test(
      'sin Sorbos, un modo sorbos guardado se lee como puntos '
      '(aunque haya +18 confirmado) y no se borra de las preferencias',
      () async {
        final c = await _container({
          'settings.consequenceMode.v1': 'sorbos',
          'settings.adultConfirmed.v1': true,
        }, sorbos: false);
        addTearDown(c.dispose);
        expect(
          c.read(settingsProvider).consequenceMode,
          ConsequenceMode.puntos,
        );
        expect(
          c
              .read(sharedPreferencesProvider)
              .getString('settings.consequenceMode.v1'),
          'sorbos',
        );
      },
    );

    test('sin Sorbos, retos guardado se conserva', () async {
      final c = await _container({
        'settings.consequenceMode.v1': 'retos',
      }, sorbos: false);
      addTearDown(c.dispose);
      expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.retos);
    });

    test('el enum conserva puntos, retos y sorbos (session.v1 intacto)', () {
      expect(ConsequenceMode.values.map((m) => m.name), [
        'puntos',
        'retos',
        'sorbos',
      ]);
    });
  });

  group('selector de modo', () {
    testWidgets(
      'sin Sorbos el selector de Ajustes solo ofrece Fichas y Retos',
      (tester) async {
        await _pump(
          tester,
          const Scaffold(body: ConsequenceModeSelector()),
          sorbos: false,
          prefsValues: {'settings.adultConfirmed.v1': true},
        );
        expect(find.text('Fichas'), findsOneWidget);
        expect(find.text('Retos'), findsOneWidget);
        expect(find.text('Sorbos'), findsNothing);
        expect(find.textContaining('sorbo', findRichText: true), findsNothing);
        expect(find.textContaining('+18'), findsNothing);
      },
    );

    testWidgets(
      'con Sorbos activo el selector de Ajustes lo sigue ofreciendo',
      (tester) async {
        await _pump(
          tester,
          const Scaffold(body: ConsequenceModeSelector()),
          sorbos: true,
        );
        expect(find.text('Sorbos'), findsOneWidget);
      },
    );

    testWidgets('sin Sorbos, un modo sorbos guardado muestra Fichas', (
      tester,
    ) async {
      await _pump(
        tester,
        const Scaffold(body: ConsequenceModeSelector()),
        sorbos: false,
        prefsValues: {
          'settings.adultConfirmed.v1': true,
          'settings.consequenceMode.v1': 'sorbos',
        },
      );
      expect(
        find.text('Se juega por honor. Nadie cumple nada fuera de la app.'),
        findsOneWidget,
      );
    });

    testWidgets('sin Sorbos la home no ofrece Sorbos ni con +18 confirmado', (
      tester,
    ) async {
      await _pump(
        tester,
        const HomeScreen(),
        sorbos: false,
        prefsValues: {'settings.adultConfirmed.v1': true},
      );
      expect(find.text('Fichas'), findsOneWidget);
      expect(find.text('Retos'), findsOneWidget);
      expect(find.text('Sorbos'), findsNothing);
    });

    testWidgets('sin Sorbos, selectConsequenceMode(sorbos) no abre el diálogo '
        '+18 ni cambia el modo', (tester) async {
      final c = await _pump(
        tester,
        Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              return TextButton(
                onPressed: () =>
                    selectConsequenceMode(context, ref, ConsequenceMode.sorbos),
                child: const Text('probar'),
              );
            },
          ),
        ),
        sorbos: false,
      );
      await tester.tap(find.text('probar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(c.read(settingsProvider).adultConfirmed, isFalse);
      expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
    });
  });

  group('textos', () {
    testWidgets('sin Sorbos los créditos no hablan de beber', (tester) async {
      await _pump(tester, const CreditsScreen(), sorbos: false);
      await tester.scrollUntilVisible(
        find.text('Juega con responsabilidad'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('beber'), findsNothing);
      expect(find.textContaining('trago'), findsNothing);
      expect(find.textContaining('agua'), findsNothing);
    });

    testWidgets('con Sorbos activo los créditos conservan el aviso legal', (
      tester,
    ) async {
      await _pump(tester, const CreditsScreen(), sorbos: true);
      await tester.scrollUntilVisible(
        find.text('Juega con responsabilidad'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('Nadie está obligado a beber'),
        findsOneWidget,
      );
    });

    testWidgets('sin Sorbos la bienvenida no dice "beber"', (tester) async {
      final c = await _container({}, sorbos: false);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: Consumer(
            builder: (context, ref, _) =>
                MaterialApp.router(routerConfig: ref.watch(routerProvider)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+18'), findsOneWidget);
      expect(find.text('Juega con responsabilidad'), findsOneWidget);
      expect(find.textContaining('beber'), findsNothing);
    });

    test('la ayuda sin Sorbos usa las variantes y no cita agua ni sorbos', () {
      final raw = File('assets/content/es/ayuda.json').readAsStringSync();
      final on = parseHowToPlay(raw);
      final off = parseHowToPlay(raw, sorbosEnabled: false);
      expect(off.keys, on.keys);
      for (final h in off.values) {
        final text = [...h.pasos, ?h.consejo].join(' ').toLowerCase();
        expect(text, isNot(contains('sorbo')), reason: h.id);
        expect(text, isNot(contains('agua')), reason: h.id);
        expect(text, isNot(contains('beb')), reason: h.id);
      }
      // Con Sorbos activo el texto no cambia.
      expect(on['quien-es-mas-probable']!.pasos.join(' '), contains('agua'));
      expect(off['quien-es-mas-probable']!.pasos, isNotEmpty);
      expect(off['yo-nunca']!.pasos, isNotEmpty);
    });

    test('pasosLite se ignora con Sorbos activo y se respeta sin él', () {
      const raw =
          '[{"id":"x","titulo":"T","pasos":["a","b"],"pasosLite":["a"]}]';
      expect(parseHowToPlay(raw)['x']!.pasos, ['a', 'b']);
      expect(parseHowToPlay(raw, sorbosEnabled: false)['x']!.pasos, ['a']);
    });
  });

  group('textos de juego en Fichas y Retos (los únicos modos sin Sorbos)', () {
    test('no mencionan sorbos ni agua', () {
      for (final m in [ConsequenceMode.puntos, ConsequenceMode.retos]) {
        // Los textos de la Carrera solo valen en Fichas: en Retos no se ofrece (D21).
        final race = m == ConsequenceMode.puntos
            ? [
                allInShareText(m, 2),
                losersTitle(m),
                losersLine(m, {'Ana': 2, 'Luis': 5}),
                nobodyWonText(m),
                whoPaysLabel(m),
              ]
            : const <String>[];
        final texts = [
          ...race,
          stakeHeadline(2, m) ?? '',
          ConsequenceBanner.amountText(resolveLoss(3, m)),
        ].join(' | ').toLowerCase();
        expect(texts, isNot(contains('sorbo')), reason: m.name);
        expect(texts, isNot(contains('agua')), reason: m.name);
      }
    });
  });
}
