import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/credits_screen.dart';
import 'package:paddock/app/theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: const CreditsScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'la sección Diseño atribuye Phosphor, tipografías y confetti con enlaces a licencias',
    (tester) async {
      await pump(tester);
      await tester.scrollUntilVisible(
        find.text('Diseño'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Diseño'), findsOneWidget);
      expect(
        find.textContaining('Phosphor Icons (MIT)', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Alfa Slab One', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Figtree', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('SIL Open Font License 1.1', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('confetti (MIT)', findRichText: true),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Ver licencia MIT'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Ver licencia SIL OFL 1.1'), findsOneWidget);
      expect(find.text('Ver licencia MIT'), findsOneWidget);
    },
  );

  testWidgets('conserva atribuciones y aviso legal previos', (tester) async {
    await pump(tester);
    expect(find.text('Baraja española'), findsOneWidget);
    expect(find.text('Ver licencia CC BY-SA 3.0'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Juega con responsabilidad'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Nadie está obligado a beber'), findsOneWidget);
  });

  testWidgets('con letra 2.0 en 320x568 los Créditos no desbordan', (
    tester,
  ) async {
    await pump(tester, scale: 2);
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
  });
}
