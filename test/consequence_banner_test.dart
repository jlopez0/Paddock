import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/consequences/consequence_banner.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/consequences/retos_filter.dart';
import 'package:habinson/core/content/prompts.dart';

Widget _wrap(Widget w) => MaterialApp(home: Scaffold(body: w));

void main() {
  testWidgets('puntos: "−2 en la Copa"', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 2, 'Luis': 0}, mode: ConsequenceMode.puntos)));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('−2 en la Copa'), findsOneWidget);
    expect(find.text('Luis'), findsNothing);
  });

  testWidgets('retos: "Un reto" por jugador (nunca un número) y reto de reserva', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 2, 'Luis': 1}, mode: ConsequenceMode.retos)));
    expect(find.text('Un reto'), findsNWidgets(2));
    expect(find.textContaining(RegExp(r'\d reto')), findsNothing);
    expect(find.text(kFallbackRetos[0]), findsOneWidget);
    expect(find.text(kFallbackRetos[1]), findsOneWidget);
  });

  testWidgets('retos: cada jugador recibe el reto de su nivel (1 suave, 2 picante, 3 atrevido)', (t) async {
    final pools = RetoPools.fromPrompts(const [
      Prompt(id: 'a', level: PromptLevel.suave, fields: {'texto': 'S'}),
      Prompt(id: 'b', level: PromptLevel.picante, fields: {'texto': 'P'}),
      Prompt(id: 'c', level: PromptLevel.atrevido, fields: {'texto': 'A'}),
    ], adultConfirmed: true);
    await t.pumpWidget(_wrap(ConsequenceBanner(
        losses: const {'Ana': 1, 'Luis': 2, 'Eva': 3, 'Pau': 10},
        mode: ConsequenceMode.retos,
        retoPools: pools)));
    expect(find.text('S'), findsOneWidget);
    expect(find.text('P'), findsOneWidget);
    expect(find.text('A'), findsNWidgets(2)); // 3 y All-in (10) = nivel máximo
    expect(find.text('Un reto'), findsNWidgets(4));
  });

  testWidgets('retos: sin +18 el nivel máximo baja a picante', (t) async {
    final pools = RetoPools.fromPrompts(const [
      Prompt(id: 'a', level: PromptLevel.suave, fields: {'texto': 'S'}),
      Prompt(id: 'b', level: PromptLevel.picante, fields: {'texto': 'P'}),
      Prompt(id: 'c', level: PromptLevel.atrevido, fields: {'texto': 'A'}),
    ], adultConfirmed: false);
    await t.pumpWidget(_wrap(ConsequenceBanner(
        losses: const {'Eva': 3}, mode: ConsequenceMode.retos, retoPools: pools)));
    expect(find.text('P'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('retos: retoOffset rota el reto elegido', (t) async {
    await t.pumpWidget(_wrap(const ConsequenceBanner(
        losses: {'Ana': 1},
        mode: ConsequenceMode.retos,
        retos: ['X', 'Y', 'Z'],
        retoOffset: 1)));
    expect(find.text('Y'), findsOneWidget);
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
