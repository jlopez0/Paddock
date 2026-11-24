import 'dart:io';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/abecedario/ui/abecedario_play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paddock/games/abecedario/abecedario_data.dart';

void main() {
  final bank = parseAbecedario(File(abecedarioAsset).readAsStringSync());

  test('banco: ids únicos y al menos una definición por letra', () {
    expect(bank.map((e) => e.id).toSet().length, bank.length);
    for (final l in abecedarioLetters) {
      expect(bank.any((e) => e.letter == l), isTrue, reason: 'falta la $l');
    }
  });

  test('generar: una entrada por letra, en orden', () {
    final r = generateAbecedario(bank, Random(1));
    expect(r.map((e) => e.letter).toList(), abecedarioLetters);
  });

  test('niveles: cada nivel da un abecedario completo de ese nivel', () {
    for (final l in [
      AbecedarioLevel.easy,
      AbecedarioLevel.medium,
      AbecedarioLevel.hard,
    ]) {
      final r = generateAbecedario(bank, Random(3), level: l);
      expect(r.map((e) => e.letter).toList(), abecedarioLetters);
      expect(r.every((e) => e.level == l.key), isTrue, reason: l.label);
    }
  });

  testWidgets('partida: cuenta atrás, desvela, avanza solo y no desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      'abecedario.setup.v1': '{"seconds":10,"auto":true,"read":3}',
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: AbecedarioPlayScreen()),
      ),
    );
    // La lectura del asset es E/S real (fuera del reloj simulado): se espera a que aparezca la partida.
    for (
      var i = 0;
      i < 40 && find.text('Desvelar ya').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Desvelar ya'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('Siguiente'), findsOneWidget); // respuesta desvelada
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Desvelar ya'), findsOneWidget); // pasó sola a la B
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
