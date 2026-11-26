import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/games/abecedario/abecedario_data.dart';
import 'package:habinson/games/abecedario/abecedario_review.dart';

AbecedarioEntry _e(String letter, {String answer = 'respuesta', bool contains = false}) =>
    AbecedarioEntry(
      id: letter,
      letter: letter,
      contains: contains,
      answer: answer,
      definition: 'definición de $letter',
      level: 'facil',
    );

void main() {
  final entries = [_e('A', answer: 'avión'), _e('B', answer: 'barco'), _e('C', answer: 'casa')];

  test('sin marcar: todo cuenta como sin marcar', () {
    final r = AbecedarioReview(entries);
    expect(r.hits, 0);
    expect(r.misses, 0);
    expect(r.unmarked, 3);
    expect(r.markOf(0), isNull);
    expect(r.missed, isEmpty);
  });

  test('marcar acierto y fallo se cuenta por separado', () {
    final r = AbecedarioReview(entries)
        .mark(0, AbecedarioMark.hit)
        .mark(1, AbecedarioMark.miss);
    expect(r.hits, 1);
    expect(r.misses, 1);
    expect(r.unmarked, 1);
    expect(r.markOf(0), AbecedarioMark.hit);
    expect(r.markOf(1), AbecedarioMark.miss);
    expect(r.markOf(2), isNull);
  });

  test('marcar la misma marca otra vez la quita', () {
    final r = AbecedarioReview(entries)
        .mark(0, AbecedarioMark.hit)
        .mark(0, AbecedarioMark.hit);
    expect(r.markOf(0), isNull);
    expect(r.hits, 0);
  });

  test('marcar la contraria cambia la marca, sin duplicar', () {
    final r = AbecedarioReview(entries)
        .mark(0, AbecedarioMark.hit)
        .mark(0, AbecedarioMark.miss);
    expect(r.markOf(0), AbecedarioMark.miss);
    expect(r.hits, 0);
    expect(r.misses, 1);
  });

  test('es inmutable: mark devuelve otra instancia', () {
    final a = AbecedarioReview(entries);
    final b = a.mark(0, AbecedarioMark.hit);
    expect(a.hits, 0);
    expect(b.hits, 1);
  });

  test('missed: solo las falladas, en orden, con su entrada y respuesta', () {
    final r = AbecedarioReview(entries)
        .mark(2, AbecedarioMark.miss)
        .mark(0, AbecedarioMark.miss)
        .mark(1, AbecedarioMark.hit);
    expect(r.missed.map((e) => e.letter).toList(), ['A', 'C']);
    expect(r.missed.map((e) => e.answer).toList(), ['avión', 'casa']);
  });

  test('rows: una por letra con su resultado', () {
    final r = AbecedarioReview(entries).mark(1, AbecedarioMark.hit);
    expect(r.rows.length, 3);
    expect(r.rows[1].mark, AbecedarioMark.hit);
    expect(r.rows[0].mark, isNull);
    expect(r.rows[1].entry.letter, 'B');
  });

  test('fuera de rango: ignora la marca', () {
    final r = AbecedarioReview(entries).mark(9, AbecedarioMark.hit).mark(-1, AbecedarioMark.miss);
    expect(r.hits, 0);
    expect(r.misses, 0);
  });

  test('sin entradas: todo a cero', () {
    final r = AbecedarioReview(const []);
    expect(r.hits + r.misses + r.unmarked, 0);
    expect(r.missed, isEmpty);
  });
}
