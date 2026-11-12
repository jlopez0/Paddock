import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/games/geography/domain/geo_map.dart';
import 'package:paddock/games/geography/domain/quiz.dart';
import 'package:paddock/games/geography/domain/text_match.dart';

GeoMap loadMap(String id) => GeoMap.fromJson(
    jsonDecode(File('assets/content/es/geografia/mapas/$id.json').readAsStringSync()) as Map<String, dynamic>);

QuizConfig config(GeoCategory c, {bool options = true, int count = 0}) =>
    QuizConfig(category: c, withOptions: options, regions: const {}, count: count);

void main() {
  const expected = {
    GeoCategory.usStates: 50,
    GeoCategory.mxStates: 32,
    GeoCategory.esProvinces: 50,
    GeoCategory.jpPrefectures: 47,
  };

  for (final MapEntry(key: cat, value: count) in expected.entries) {
    group(cat.label, () {
      final map = loadMap(cat.mapId!);

      test('tiene $count regiones con nombre único y forma', () {
        expect(map.regions.length, count);
        final names = map.regions.map((r) => normalizeText(r.name)).toSet();
        expect(names.length, count, reason: 'nombres repetidos');
        for (final r in map.regions) {
          expect(r.rings, isNotEmpty, reason: r.name);
          expect(r.bounds.$1, greaterThanOrEqualTo(0));
          expect(r.bounds.$3, lessThanOrEqualTo(map.width + 1));
          expect(r.bounds.$4, lessThanOrEqualTo(map.height + 1));
        }
      });

      test('ningún alias coincide con el nombre de otra región', () {
        final owner = <String, String>{};
        for (final r in map.regions) {
          for (final n in r.acceptedNames) {
            final k = normalizeText(n);
            expect(owner[k] == null || owner[k] == r.id, isTrue, reason: '"$n" es de ${owner[k]} y de ${r.id}');
            owner[k] = r.id;
          }
        }
      });

      test('genera preguntas con 4 opciones cercanas y sin repetir', () {
        final e = MapQuizEngine(map, random: Random(3));
        final qs = e.generate(config(cat));
        expect(qs.length, count);
        expect(qs.map((q) => q.region!.id).toSet().length, count);
        for (final q in qs) {
          expect(q.kind, QuestionKind.region);
          expect(q.options.length, 4);
          expect(q.options, contains(q.answer));
          expect(q.options.map(normalizeText).toSet().length, 4);
        }
        expect(e.generate(config(cat, count: 10)).length, 10);
        expect(e.generate(config(cat, options: false)).every((q) => q.options.isEmpty), isTrue);
      });
    });
  }

  test('respuestas escritas en mapas: nombre en español, inglés o local', () {
    void check(String mapId, String region, Map<String, bool> inputs) {
      final map = loadMap(mapId);
      final e = MapQuizEngine(map);
      final q = e.generate(config(GeoCategory.usStates, options: false)).firstWhere((x) => x.answer == region);
      inputs.forEach((input, ok) => expect(e.isCorrect(q, input), ok, reason: '$region ← "$input"'));
    }

    check('eeuu', 'Nueva York', {'nueva york': true, 'New York': true, 'Nueva Jersey': false});
    check('eeuu', 'Virginia', {'virginia': true, 'Virginia Occidental': false});
    check('eeuu', 'Hawái', {'hawai': true, 'Hawaii': true});
    check('espana', 'Lleida', {'Lérida': true, 'lleida': true, 'León': false});
    check('espana', 'A Coruña', {'La Coruña': true, 'coruña': true});
    check('espana', 'Islas Baleares', {'baleares': true, 'Illes Balears': true});
    check('mexico', 'Ciudad de México', {'CDMX': true, 'Distrito Federal': true, 'Estado de México': false});
    check('mexico', 'Estado de México', {'Edomex': true, 'Ciudad de México': false});
    check('japon', 'Tokio', {'tokyo': true, 'Kioto': false});
    check('japon', 'Hokkaido', {'Hokkaidō': true});
  });
}
