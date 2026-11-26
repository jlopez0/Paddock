import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/app/home_screen.dart';
import 'package:habinson/app/router.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/settings/onboarding_controller.dart';
import 'package:habinson/core/settings/settings_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/horse_race/ui/race_setup_screen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// D21: la Carrera no existe en Retos. Su ruta y subrutas vuelven a `/`, también si el modo
/// cambia con la Carrera abierta.
Future<ProviderContainer> _boot(
  WidgetTester tester, {
  String mode = 'puntos',
  String path = '/',
}) async {
  SharedPreferences.setMockInitialValues({
    OnboardingController.welcomeKey: true,
    'settings.consequenceMode.v1': mode,
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(c.dispose);
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  c.read(routerProvider).go(path);
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
  return c;
}

String _location(ProviderContainer c) =>
    c.read(routerProvider).routeInformationProvider.value.uri.path;

void main() {
  for (final path in [
    '/game/carrera',
    '/game/carrera/race',
    '/game/carrera/result',
    '/game/carrera/stats',
  ]) {
    testWidgets('en Retos $path vuelve a la home sin romper', (tester) async {
      final c = await _boot(tester, mode: 'retos', path: path);
      expect(tester.takeException(), isNull);
      expect(_location(c), '/');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RaceSetupScreen), findsNothing);
    });
  }

  testWidgets('en Fichas la ruta de la Carrera funciona', (tester) async {
    final c = await _boot(tester, path: '/game/carrera');
    expect(_location(c), '/game/carrera');
    expect(find.byType(RaceSetupScreen), findsOneWidget);
  });

  testWidgets('con la Carrera abierta, pasar a Retos la cierra y vuelve a la home', (
    tester,
  ) async {
    final c = await _boot(tester, path: '/game/carrera');
    expect(find.byType(RaceSetupScreen), findsOneWidget);
    c.read(settingsProvider.notifier).setConsequenceMode(ConsequenceMode.retos);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_location(c), '/');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(RaceSetupScreen), findsNothing);
  });

  testWidgets('en Retos el resto de juegos sigue abriendo', (tester) async {
    final c = await _boot(tester, mode: 'retos', path: '/game/abecedario');
    expect(_location(c), '/game/abecedario');
    expect(find.byType(HomeScreen), findsNothing);
  });
}
