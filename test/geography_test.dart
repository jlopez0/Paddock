import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/games/geography/domain/country.dart';
import 'package:paddock/games/geography/domain/quiz.dart';
import 'package:paddock/games/geography/domain/text_match.dart';

List<Country> loadCountries() {
  final j = jsonDecode(File('assets/content/es/geografia/paises.json').readAsStringSync()) as Map<String, dynamic>;
  return (j['items'] as List).cast<Map<String, dynamic>>().map(Country.fromJson).toList();
}

QuizConfig config(GeoCategory c, {bool options = true, int count = 0, Set<Continent>? regions}) =>
    QuizConfig(category: c, withOptions: options, regions: regions ?? Continent.values.toSet(), count: count);

void main() {
  group('texto', () {
    test('normaliza tildes, mayúsculas, signos y artículo inicial', () {
      expect(normalizeText('  El Cairo '), 'cairo');
      expect(normalizeText("Côte d'Ivoire"), 'cote d ivoire');
      expect(normalizeText('MÉXICO'), 'mexico');
      expect(normalizeText('Washington D. C.'), 'washington d c');
      expect(normalizeText('El Salvador'), 'salvador');
    });

    test('levenshtein', () {
      expect(levenshtein('casa', 'casa'), 0);
      expect(levenshtein('casa', 'cosa'), 1);
      expect(levenshtein('', 'abc'), 3);
      expect(levenshtein('kitten', 'sitting'), 3);
    });
  });

  group('datos', () {
    final countries = loadCountries();

    test('193 países, ids únicos, todos con bandera y capital', () {
      expect(countries.length, 193);
      expect(countries.map((c) => c.iso).toSet().length, 193);
      for (final c in countries) {
        expect(File(c.flagAsset).existsSync(), isTrue, reason: 'bandera de ${c.name}');
        expect(c.capital.trim(), isNotEmpty, reason: 'capital de ${c.name}');
      }
    });

    test('hay siluetas para todos los países marcados y en cada continente', () {
      final shapes = jsonDecode(File('assets/geo/siluetas.json').readAsStringSync()) as Map<String, dynamic>;
      for (final c in countries.where((c) => c.hasSilhouette)) {
        expect(shapes.containsKey(c.iso.toUpperCase()), isTrue, reason: 'silueta de ${c.name}');
      }
      for (final k in Continent.values) {
        expect(countries.where((c) => c.continent == k && c.hasSilhouette), isNotEmpty, reason: k.label);
      }
    });
  });

  group('motor', () {
    final countries = loadCountries();
    QuizEngine engine([int seed = 1]) => QuizEngine(countries, random: Random(seed));

    test('con opciones: 4 distintas, la correcta incluida, sin repetir país', () {
      for (final cat in GeoCategory.values) {
        for (var seed = 0; seed < 5; seed++) {
          final qs = engine(seed).generate(config(cat));
          expect(qs, isNotEmpty);
          expect(qs.map((q) => q.country.iso).toSet().length, qs.length, reason: 'país repetido en ${cat.name}');
          for (final q in qs) {
            expect(q.options.length, 4);
            expect(q.options.map(normalizeText).toSet().length, 4);
            expect(q.options, contains(q.answer));
          }
        }
      }
    });

    test('sin opciones: no hay opciones', () {
      final qs = engine().generate(config(GeoCategory.flags, options: false));
      expect(qs.every((q) => q.options.isEmpty), isTrue);
    });

    test('respeta región, cantidad y elegibilidad', () {
      final eu = engine().generate(config(GeoCategory.flags, regions: {Continent.europa}));
      expect(eu.every((q) => q.country.continent == Continent.europa), isTrue);

      expect(engine().generate(config(GeoCategory.flags, count: 10)).length, 10);
      expect(engine().generate(config(GeoCategory.flags)).length, 193);

      final sil = engine().generate(config(GeoCategory.silhouettes));
      expect(sil.every((q) => q.country.hasSilhouette), isTrue);

      final cap = engine().generate(config(GeoCategory.capitals));
      expect(cap.every((q) => q.country.hasUsableCapital), isTrue);
      expect(cap.any((q) => q.country.name == 'Singapur'), isFalse);
    });

    test('los distractores de capitales son del mismo continente cuando hay de sobra', () {
      final qs = engine().generate(config(GeoCategory.capitals, regions: {Continent.europa}));
      final byCapital = {for (final c in countries) c.capital: c};
      for (final q in qs) {
        for (final o in q.options) {
          expect(byCapital[o]!.continent, q.country.continent);
        }
      }
    });

    test('mezcla usa varios tipos de pregunta', () {
      final kinds = engine().generate(config(GeoCategory.mix)).map((q) => q.kind).toSet();
      expect(kinds.length, QuestionKind.values.length);
    });

    test('respuestas escritas: tildes, alias y erratas', () {
      final e = engine();
      Question q(String name, QuestionKind k) => e.generate(config(GeoCategory.mix, options: false)).firstWhere(
            (x) => x.country.name == name && x.kind == k,
            orElse: () => e.generate(config(GeoCategory.flags, options: false)).firstWhere((x) => x.country.name == name),
          );

      final mexico = q('México', QuestionKind.flag);
      expect(e.isCorrect(mexico, 'mexico'), isTrue);
      expect(e.isCorrect(mexico, '  MÉXICO '), isTrue);
      expect(e.isCorrect(mexico, 'Mexicoo'), isTrue); // errata
      expect(e.isCorrect(mexico, ''), isFalse);
      expect(e.isCorrect(mexico, 'Perú'), isFalse);

      final usa = q('Estados Unidos', QuestionKind.flag);
      expect(e.isCorrect(usa, 'EEUU'), isTrue);
      expect(e.isCorrect(usa, 'usa'), isTrue);
    });

    test('nunca acepta otro país parecido', () {
      final e = engine();
      final qs = e.generate(config(GeoCategory.flags, options: false));
      Question q(String name) => qs.firstWhere((x) => x.country.name == name);
      expect(e.isCorrect(q('Níger'), 'Nigeria'), isFalse);
      expect(e.isCorrect(q('Nigeria'), 'Níger'), isFalse);
      expect(e.isCorrect(q('Austria'), 'Australia'), isFalse);
      expect(e.isCorrect(q('Australia'), 'Austria'), isFalse);
      expect(e.isCorrect(q('Dominica'), 'República Dominicana'), isFalse);
      expect(e.isCorrect(q('Guinea'), 'Guinea-Bisáu'), isFalse);
      expect(e.isCorrect(q('Omán'), 'Mali'), isFalse);
    });

    test('capitales con alias', () {
      final e = engine();
      final qs = e.generate(config(GeoCategory.capitals, options: false));
      Question q(String name) => qs.firstWhere((x) => x.country.name == name);
      expect(e.isCorrect(q('Bolivia'), 'La Paz'), isTrue);
      expect(e.isCorrect(q('Bolivia'), 'sucre'), isTrue);
      expect(e.isCorrect(q('Egipto'), 'Cairo'), isTrue);
      expect(e.isCorrect(q('Egipto'), 'El Cairo'), isTrue);
      expect(e.isCorrect(q('Ucrania'), 'Kyiv'), isTrue);
      expect(e.isCorrect(q('Francia'), 'Lyon'), isFalse);
      expect(e.isCorrect(q('Francia'), 'Paris'), isTrue);
    });
  });
}
