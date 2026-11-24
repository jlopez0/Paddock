import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/router.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/settings/onboarding_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/registry.dart';
import 'package:paddock/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las pantallas principales no deben desbordar con letra 2.0 en 320x568.
void main() {
  Future<ProviderContainer> boot(WidgetTester tester, {required bool players}) async {
    SharedPreferences.setMockInitialValues({
      OnboardingController.welcomeKey: true,
      if (players)
        'players.v1': jsonEncode([
          for (final (i, n) in ['Ana', 'Luis', 'Eva', 'Pepe', 'Marta'].indexed) {'id': 'p$i', 'name': n, 'color': i},
        ]),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
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
            child: const PaddockApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> visit(WidgetTester tester, ProviderContainer c, String path) async {
    c.read(routerProvider).go(path);
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(tester.takeException(), isNull, reason: 'desborda en $path');
  }

  for (final withPlayers in [true, false]) {
    testWidgets('pantallas principales sin overflow (jugadores: $withPlayers)', (tester) async {
      final c = await boot(tester, players: withPlayers);
      expect(tester.takeException(), isNull, reason: 'desborda en /');
      if (withPlayers) {
        c.read(sessionProvider.notifier).award('r1', 'trivia', {'p0': 5, 'p1': 3, 'p2': -2});
        await tester.pump();
      }
      for (final path in ['/', '/settings', '/players', '/copa', for (final g in gameModules) g.path]) {
        await visit(tester, c, path);
      }
    });
  }
}
