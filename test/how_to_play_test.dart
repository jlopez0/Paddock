import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/router.dart';
import 'package:habinson/core/help/how_to_play.dart';
import 'package:habinson/core/settings/onboarding_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/registry.dart';
import 'package:habinson/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final raw = File('assets/content/es/ayuda.json').readAsStringSync();

  test('carga: un item por juego del registro', () {
    final m = parseHowToPlay(raw);
    for (final g in gameModules) {
      final h = m[g.id];
      expect(h, isNotNull, reason: g.id);
      expect(h!.pasos, isNotEmpty);
    }
  });

  test('la Copa tiene su entrada de ayuda y no cita juegos que no suman', () {
    final h = parseHowToPlay(raw)['copa'];
    expect(h, isNotNull);
    expect(h!.pasos, isNotEmpty);
    expect(h.pasos.join(' '), contains('Carrera'));
    expect(h.pasos.join(' '), contains('Infiltrado'));
  });

  test('la ayuda no cita fichas en Carrera ni Infiltrado, no dice sorbo y la Copa explica que cuenta en fichas', () {
    final m = parseHowToPlay(raw);
    for (final id in ['carrera', 'infiltrado']) {
      final h = m[id]!;
      final all = [h.titulo, ...h.pasos, ?h.consejo].join(' ').toLowerCase();
      expect(all, isNot(contains('ficha')), reason: id);
      expect(all, isNot(contains('cobr')), reason: id);
      expect(all, isNot(contains('pagan')), reason: id);
    }
    expect(raw.toLowerCase(), isNot(contains('sorbo')));
    final copa = m['copa']!.pasos.join(' ');
    expect(copa, contains('La Copa cuenta en fichas, sea cual sea el modo'));
    expect(m['carrera']!.pasos.join(' '), contains('El modo elegido decide qué se juega.'));
    expect(m['infiltrado']!.pasos.join(' '), contains('El modo elegido decide qué se juega.'));
  });

  test('id inexistente y JSON roto no crashean', () {
    expect(parseHowToPlay(raw)['no-existe'], isNull);
    expect(parseHowToPlay('{{ roto'), isEmpty);
    expect(parseHowToPlay('{"a":1}'), isEmpty);
    expect(parseHowToPlay('[1, {"id":"x"}, {"id":"y","titulo":"T","pasos":"mal"}]')['y']!.pasos, isEmpty);
  });

  Future<void> bootAt(WidgetTester tester, String path, {List<Override> overrides = const []}) async {
    SharedPreferences.setMockInitialValues({
      OnboardingController.welcomeKey: true,
      'players.v1': jsonEncode([
        for (final (i, n) in ['Ana', 'Luis', 'Eva'].indexed) {'id': 'p$i', 'name': n, 'color': i},
      ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs), ...overrides]);
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
            child: const HabinsonApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (overrides.isEmpty) await tester.runAsync(() => c.read(howToPlayProvider.future));
    c.read(routerProvider).go(path);
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  }

  for (final g in gameModules) {
    testWidgets('el botón aparece y abre la hoja en ${g.id} (2.0x, 320x568)', (tester) async {
      await bootAt(tester, g.path);
      final btn = find.byTooltip('¿Cómo se juega?');
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(find.text('1.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('la Copa tiene el botón de ayuda', (tester) async {
    await bootAt(tester, '/copa');
    expect(find.byTooltip('¿Cómo se juega?'), findsOneWidget);
  });

  testWidgets('sin ayuda para el id, el botón no aparece', (tester) async {
    await bootAt(tester, gameModules.first.path, overrides: [howToPlayProvider.overrideWith((ref) async => {})]);
    expect(find.byTooltip('¿Cómo se juega?'), findsNothing);
  });
}
