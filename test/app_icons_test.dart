import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/games/registry.dart';

/// Los iconos propios no deben desbordar con letra 2.0 en 320 px.
void main() {
  Future<void> pump(WidgetTester tester, Widget w) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(320, 568), textScaler: TextScaler.linear(2.0)),
        child: Scaffold(body: SingleChildScrollView(child: w)),
      ),
    ));
    expect(tester.takeException(), isNull);
  }

  test('cada juego del registro tiene icono propio', () {
    for (final g in gameModules) {
      expect(GameIcon.hasIcon(g.id), isTrue, reason: g.id);
    }
    expect(GameIcon.hasIcon('no-existe'), isFalse);
  });

  test('todas las categorias tienen icono', () {
    for (final id in [...CategoryIcon.triviaIds, ...CategoryIcon.geoIds]) {
      expect(CategoryIcon.hasIcon(id), isTrue, reason: id);
    }
  });

  testWidgets('iconos y piezas dibujadas renderizan sin overflow', (tester) async {
    await pump(
      tester,
      Wrap(
        children: [
          for (final g in gameModules) g.icon(44),
          GameIcon('desconocido'),
          for (final k in GameIconKind.values) GameIcon.kind(k, size: 72),
          for (var p = 1; p <= 4; p++) MedalIcon(p, size: 40),
          for (final l in LevelIcon.ids) LevelIcon(l),
          for (final id in [...CategoryIcon.triviaIds, ...CategoryIcon.geoIds]) CategoryIcon(id),
          for (final i in AppIcon.values) i.widget(size: 32),
          for (final v in [1, 5, 25, 100, 1000, 12500]) ChipToken(v, size: 48),
          const SizedBox(
            width: 280,
            child: TicketCard(child: Text('Boleto de carrera número uno')),
          ),
          const SizedBox(
            width: 280,
            child: TicketCard(
              stub: Text('Paga 3 a 1'),
              child: Text('Boleto de carrera número uno'),
            ),
          ),
        ],
      ),
    );
    expect(find.byType(MedalIcon), findsNWidgets(4));
    expect(find.byType(TicketCard), findsNWidgets(2));
  });
}
