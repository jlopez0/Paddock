import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/games/trivia/trivia_data.dart';

void main() {
  final bank = parseTrivia(File(triviaAsset).readAsStringSync());

  test('banco: ids únicos, 4 opciones distintas y todas las categorías con preguntas', () {
    expect(bank.map((q) => q.id).toSet().length, bank.length);
    for (final q in bank) {
      expect({q.answer, ...q.wrong}.length, 4, reason: q.text);
      expect(q.text.trim(), isNotEmpty);
    }
    for (final c in TriviaCategory.values) {
      expect(bank.where((q) => q.category == c).length, greaterThanOrEqualTo(15), reason: c.label);
    }
  });

  test('generar: respeta categorías y cantidad, opciones barajadas con la correcta', () {
    final qs = generateTrivia(bank, {TriviaCategory.deporte}, 10, Random(1));
    expect(qs.length, 10);
    expect(qs.every((q) => q.category == TriviaCategory.deporte), isTrue);
    for (final q in qs) {
      expect(q.options.length, 4);
      expect(q.options, contains(q.answer));
    }
    expect(generateTrivia(bank, TriviaCategory.values.toSet(), 0, Random(1)).length, bank.length);
  });

  test('nivel: normal excluye difíciles y difícil solo las difíciles', () {
    final bank = parseTrivia(File('assets/content/es/trivia.json').readAsStringSync());
    final all = TriviaCategory.values.toSet();
    final normal = generateTrivia(bank, all, 0, Random(1), level: TriviaLevel.normal);
    final hard = generateTrivia(bank, all, 0, Random(1), level: TriviaLevel.hard);
    expect(normal.any((q) => q.hard), isFalse);
    expect(hard.isNotEmpty && hard.every((q) => q.hard), isTrue);
    expect(normal.length + hard.length, bank.length);
  });
}
