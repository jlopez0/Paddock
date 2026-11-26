import 'dart:convert';

import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/router.dart';
import 'package:habinson/games/horse_race/domain/bets.dart';
import 'package:habinson/games/horse_race/domain/cards.dart';
import 'package:habinson/games/horse_race/race_store.dart';
import 'package:habinson/core/players/player.dart';
import 'package:habinson/core/players/player_widgets.dart';
import 'package:habinson/core/session/session_controller.dart';
import 'package:habinson/core/settings/onboarding_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/registry.dart';
import 'package:habinson/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Las pantallas principales no deben desbordar con letra 2.0 en 320x568.
void main() {
  Future<ProviderContainer> boot(WidgetTester tester, {required bool players, double scale = 2.0, Size size = const Size(320, 568)}) async {
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
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: const HabinsonApp(),
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

  testWidgets('los títulos largos de la barra caben enteros con letra 2.0 en 320x568', (tester) async {
    final c = await boot(tester, players: true);
    c.read(sessionProvider.notifier).award('r1', 'trivia', {'p0': 5, 'p1': 3, 'p2': -2});
    await tester.pump();
    for (final (path, title) in [('/copa', 'Copa de la noche'), ('/game/carrera', 'Carrera de caballos')]) {
      await visit(tester, c, path);
      final finder = find.descendant(of: find.byType(AppBar), matching: find.text(title));
      expect(finder, findsOneWidget, reason: 'título de $path');
      final p = tester.renderObject<RenderParagraph>(finder);
      // Sin recorte: el párrafo mide lo que mide el texto entero (se escala, no se corta).
      expect(p.size.width, greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity) - 0.5), reason: 'recortado en $path');
      // Y la barra lo enseña dentro de la pantalla.
      expect(tester.getBottomRight(finder).dx, lessThanOrEqualTo(320.5), reason: 'se sale en $path');
      expect(tester.getTopLeft(finder).dx, greaterThanOrEqualTo(0), reason: 'se sale en $path');
    }
  });

  testWidgets('la inicial del avatar cabe en su círculo con letra 2.0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2.0)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              for (final size in [24.0, 28.0, 36.0])
                PlayerAvatar(const Player(id: 'a', name: 'Marta', colorIndex: 0), size: size, key: ValueKey(size)),
            ],
          ),
        ),
      ),
    );
    for (final size in [24.0, 28.0, 36.0]) {
      final text = find.descendant(of: find.byKey(ValueKey(size)), matching: find.text('M'));
      // Dentro del círculo, descontado el borde de 2 px por lado.
      // Lo que mide la letra (no la caja que le deja el círculo).
      final p = tester.renderObject<RenderParagraph>(text);
      expect(p.getMaxIntrinsicHeight(double.infinity), lessThanOrEqualTo(size - 4), reason: 'avatar de $size recortado');
      expect(p.getMaxIntrinsicWidth(double.infinity), lessThanOrEqualTo(size - 4), reason: 'avatar de $size recortado');
    }
  });

  testWidgets('en el boleto, el nombre del palo no se parte con letra 2.0 en 320x568', (tester) async {
    final c = await boot(tester, players: true);
    c.read(raceSetupProvider.notifier).setBets(const [Bet(playerId: 'p0', suit: Suit.oros, chips: 2)]);
    await visit(tester, c, '/game/carrera');
    final suit = find.text('Espadas');
    await tester.scrollUntilVisible(suit, 200, scrollable: find.byType(Scrollable).first);
    expect(suit, findsOneWidget);
    // Una sola línea (12 px x 2.0), no "Espad / as".
    expect(tester.getSize(suit).height, lessThan(40));
    expect(tester.takeException(), isNull);
  });

  for (final (scale, size) in [(1.0, const Size(320, 568)), (2.0, const Size(320, 568)), (1.0, const Size(400, 800))]) {
    testWidgets('en la home la cuadra deja aire entre el texto y los avatares (letra $scale, ${size.width.toInt()} de ancho)',
        (tester) async {
      await boot(tester, players: true, scale: scale, size: size);
      final label = find.text('5 jugadores');
      expect(label, findsOneWidget);
      final card = find.ancestor(of: label, matching: find.byType(InkWell)).first;
      final avatars = find.descendant(of: card, matching: find.byType(PlayerAvatar));
      final paragraph = tester.renderObject<RenderParagraph>(label);
      final textRight = tester.getTopLeft(label).dx + paragraph.getMaxIntrinsicWidth(double.infinity);
      if (size.width >= 400) expect(avatars, findsWidgets, reason: 'con sitio, se enseñan avatares');
      for (final a in avatars.evaluate()) {
        final left = tester.getTopLeft(find.byWidget(a.widget)).dx;
        expect(left - textRight, greaterThanOrEqualTo(8), reason: 'avatares pegados al texto');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
