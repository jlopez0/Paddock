import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/consequences/consequence_banner.dart';
import 'package:paddock/core/consequences/consequences.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('puntos: "−2 en la Copa"', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 2, 'Luis': 0}, mode: ConsequenceMode.puntos)));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('−2 en la Copa'), findsOneWidget);
    expect(find.text('Luis'), findsNothing);
  });

  testWidgets('retos: cantidad y reto de reserva', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 2, 'Luis': 1}, mode: ConsequenceMode.retos)));
    expect(find.text('2 retos'), findsOneWidget);
    expect(find.text('1 reto'), findsOneWidget);
    expect(find.text(kFallbackRetos[0]), findsOneWidget);
    expect(find.text(kFallbackRetos[1]), findsOneWidget);
  });

  testWidgets('retos: usa la lista recibida', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 1},
        mode: ConsequenceMode.retos,
        retos: ['Reto de prueba'])));
    expect(find.text('Reto de prueba'), findsOneWidget);
  });

  testWidgets('sorbos: alternativa visible y nunca más de 3', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 10, 'Luis': 1}, mode: ConsequenceMode.sorbos)));
    expect(find.text('3 sorbos · o agua o reto'), findsOneWidget);
    expect(find.text('1 sorbo · o agua o reto'), findsOneWidget);
    expect(find.textContaining('10'), findsNothing);
    expect(find.textContaining('o agua o reto'), findsNWidgets(2));
  });

  testWidgets('sin pérdidas no pinta nada', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 0}, mode: ConsequenceMode.sorbos)));
    expect(find.byType(Card), findsNothing);
  });
}
