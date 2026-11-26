import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/home_screen.dart';
import 'package:habinson/app/mascot.dart';
import 'package:habinson/core/storage.dart';
import 'package:habinson/games/registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('menú: lema, cuadra vacía con Jockey y un cartel por juego', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Se abre la noche'), findsOneWidget);
    expect(find.text('Forma la cuadra'), findsOneWidget);
    expect(find.byType(Jockey), findsNWidgets(2)); // cabecera + cuadra vacía
    for (final g in gameModules) {
      expect(find.text(g.title), findsOneWidget, reason: g.id);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('menú: sin animaciones si el sistema las desactiva', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: HomeScreen()),
      ),
    ));
    await tester.pump();
    expect(find.text('Se abre la noche'), findsOneWidget);
  });
}
