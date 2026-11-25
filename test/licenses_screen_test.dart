import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/credits_screen.dart';
import 'package:paddock/app/licenses.dart';
import 'package:paddock/app/licenses_screen.dart';
import 'package:paddock/app/theme.dart';

Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  theme: buildAppTheme(),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: home,
    ),
  ),
);

/// Lee el `LicenseRegistry` real (los assets se cargan fuera del reloj falso).
Future<List<PackageLicenses>> _registry(WidgetTester tester) async =>
    (await tester.runAsync(loadPackageLicenses))!;

void main() {
  setUpAll(registerExtraLicenses);

  testWidgets('lista las licencias registradas por paquete, en español', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final packages = await _registry(tester);
    await tester.pumpWidget(_app(LicensesScreen(loader: () async => packages)));
    await tester.pumpAndSettle();
    expect(find.text('Licencias'), findsOneWidget);
    expect(find.textContaining('Phosphor'), findsWidgets);
    expect(find.text('Alfa Slab One (fuente)'), findsOneWidget);
    expect(find.text('Figtree (fuente)'), findsOneWidget);
    expect(find.text('confetti'), findsOneWidget);
    expect(find.text('1 licencia'), findsWidgets);
    expect(find.text('Powered by Flutter'), findsNothing);
  });

  testWidgets('al tocar un paquete se abre el texto completo de su licencia', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final packages = await _registry(tester);
    await tester.pumpWidget(_app(LicensesScreen(loader: () async => packages)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Figtree (fuente)'));
    await tester.pumpAndSettle();
    expect(find.text('Licencia'), findsOneWidget);
    expect(find.textContaining('SIL OPEN FONT LICENSE'), findsWidgets);
  });

  testWidgets('agrupa con recuento y maneja el estado vacío', (tester) async {
    final packages = await loadPackageLicenses(
      source: Stream.fromIterable([
        const LicenseEntryWithLineBreaks(['b', 'a'], 'uno'),
        const LicenseEntryWithLineBreaks(['a'], 'dos'),
      ]),
    );
    expect([for (final p in packages) '${p.name}:${p.count}'], ['a:2', 'b:1']);

    await tester.pumpWidget(_app(LicensesScreen(loader: () async => const [])));
    await tester.pumpAndSettle();
    expect(find.text('No hay licencias registradas.'), findsOneWidget);
  });

  testWidgets('Créditos abre la pantalla propia, no showLicensePage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const CreditsScreen()));
    await tester.scrollUntilVisible(
      find.text('Licencias de paquetes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Licencias de paquetes'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LicensesScreen), findsOneWidget);
    expect(find.byType(LicensePage), findsNothing);
  });

  testWidgets('con letra 2.0 en 320x568 no desborda', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final packages = await _registry(tester);
    await tester.pumpWidget(
      _app(LicensesScreen(loader: () async => packages), scale: 2),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(InkWell),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byType(InkWell).first);
    await tester.pump();
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(find.text('Licencia'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
