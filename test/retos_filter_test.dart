import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/consequences/retos_filter.dart';
import 'package:habinson/core/content/prompts.dart';

void main() {
  const json = '''
{"version":1,"items":[
  {"id":"a","nivel":"suave","texto":"S"},
  {"id":"b","nivel":"picante","texto":"P"},
  {"id":"c","nivel":"atrevido","texto":"A"},
  {"id":"d","nivel":"raro","texto":"X"}
]}''';

  test('atrevido solo con adultConfirmed', () {
    final prompts = parsePrompts(json);
    expect(filterRetos(prompts, adultConfirmed: false), ['S', 'P']);
    expect(filterRetos(prompts, adultConfirmed: true), ['S', 'P', 'A']);
  });

  test('nivel desconocido se descarta sin lanzar', () {
    expect(parsePrompts(json).map((p) => p.id), ['a', 'b', 'c']);
  });

  group('RetoPools.forIntensity', () {
    final prompts = parsePrompts(json);

    test('1 suave, 2 picante, 3 o mas atrevido con +18', () {
      final p = RetoPools.fromPrompts(prompts, adultConfirmed: true);
      expect(p.forIntensity(1), ['S']);
      expect(p.forIntensity(2), ['P']);
      expect(p.forIntensity(3), ['A']);
      expect(p.forIntensity(10), ['A']);
    });

    test('sin +18 la intensidad 3 baja a picante', () {
      final p = RetoPools.fromPrompts(prompts, adultConfirmed: false);
      expect(p.forIntensity(3), ['P']);
      expect(p.forIntensity(9), ['P']);
      expect(p.forIntensity(1), ['S']);
    });

    test('intensidad 0 o negativa se trata como suave', () {
      final p = RetoPools.fromPrompts(prompts, adultConfirmed: true);
      expect(p.forIntensity(0), ['S']);
      expect(p.forIntensity(-4), ['S']);
    });

    test('pool del nivel vacio: cualquier reto permitido', () {
      final soloSuaves = parsePrompts(
        '{"version":1,"items":[{"id":"a","nivel":"suave","texto":"S"},'
        '{"id":"c","nivel":"atrevido","texto":"A"}]}',
      );
      final adult = RetoPools.fromPrompts(soloSuaves, adultConfirmed: true);
      expect(adult.forIntensity(2), ['S', 'A']);
      final menor = RetoPools.fromPrompts(soloSuaves, adultConfirmed: false);
      expect(menor.forIntensity(3), ['S']);
    });

    test('sin retos cargados: kFallbackRetos', () {
      expect(
        RetoPools.fromPrompts(null, adultConfirmed: true).forIntensity(2),
        kFallbackRetos,
      );
      expect(
        RetoPools.fromPrompts(const [], adultConfirmed: false).forIntensity(1),
        kFallbackRetos,
      );
    });

    test('flat usa la misma lista en todos los niveles', () {
      final p = RetoPools.flat(['X', 'Y']);
      expect(p.forIntensity(1), ['X', 'Y']);
      expect(p.forIntensity(3), ['X', 'Y']);
      expect(RetoPools.flat(null).forIntensity(2), kFallbackRetos);
      expect(RetoPools.flat(const []).forIntensity(2), kFallbackRetos);
    });
  });

  group('RetoPools.pick', () {
    test('rota con el offset y da la vuelta al pool', () {
      final p = RetoPools.flat(['X', 'Y', 'Z']);
      expect(p.pick(1), 'X');
      expect(p.pick(1, 1), 'Y');
      expect(p.pick(1, 3), 'X');
      expect(p.pick(1, 7), 'Y');
    });
  });
}
