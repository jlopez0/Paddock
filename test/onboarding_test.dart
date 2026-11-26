import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/router.dart';
import 'package:habinson/core/settings/onboarding_controller.dart';
import 'package:habinson/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

Widget _app(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider)),
      ),
    );

void main() {
  test('por defecto no está vista y al marcarla se guarda', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    expect(c.read(onboardingProvider), isFalse);
    c.read(onboardingProvider.notifier).markWelcomeSeen();
    expect(c.read(onboardingProvider), isTrue);
    expect(c.read(sharedPreferencesProvider).getBool('onboarding.welcome.v1'), isTrue);
  });

  test('se recupera el indicador guardado', () async {
    final c = await _container({'onboarding.welcome.v1': true});
    addTearDown(c.dispose);
    expect(c.read(onboardingProvider), isTrue);
  });

  testWidgets('la primera vez sale la bienvenida y tras continuar desaparece', (tester) async {
    final c = await _container({});
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pumpAndSettle();
    expect(find.text('+18'), findsOneWidget);
    expect(find.text('Nadie está obligado a beber'), findsOneWidget);
    expect(find.byKey(const Key('welcome-privacy')), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome-continue')));
    await tester.pumpAndSettle();
    expect(find.text('+18'), findsNothing);
    expect(c.read(onboardingProvider), isTrue);
  });

  testWidgets('si ya está vista no se muestra', (tester) async {
    final c = await _container({'onboarding.welcome.v1': true});
    addTearDown(c.dispose);
    await tester.pumpWidget(_app(c));
    await tester.pumpAndSettle();
    expect(find.text('+18'), findsNothing);
  });

  test('indicador guardado con tipo equivocado no crashea y vale false', () async {
    final c = await _container({'onboarding.welcome.v1': 'yes'});
    addTearDown(c.dispose);
    expect(c.read(onboardingProvider), isFalse);
  });

  testWidgets('la bienvenida no desborda con letra 2.0 en 320x568', (tester) async {
    final c = await _container({});
    addTearDown(c.dispose);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(2.0)),
        child: _app(c),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('+18'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
