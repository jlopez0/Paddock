import 'dart:math';

import 'country.dart';
import 'geo_map.dart';
import 'text_match.dart';

/// Qué se muestra y qué hay que adivinar.
enum QuestionKind {
  /// Bandera → nombre del país.
  flag,

  /// País → capital.
  capital,

  /// Capital → país.
  capitalOwner,

  /// Silueta → nombre del país.
  silhouette,

  /// Región marcada en un mapa → su nombre.
  region,
}

const _worldKinds = [QuestionKind.flag, QuestionKind.capital, QuestionKind.capitalOwner, QuestionKind.silhouette];

/// Lo que elige el jugador en la pantalla de inicio.
enum GeoCategory {
  flags('Banderas', '🏳️', 'Bandera → país', [QuestionKind.flag]),
  capitals('Capitales', '🏛️', 'País → capital', [QuestionKind.capital]),
  owners('Capital → país', '📍', '¿De qué país es?', [QuestionKind.capitalOwner]),
  silhouettes('Siluetas', '🗺️', 'Forma → país', [QuestionKind.silhouette]),
  mix('Mezcla', '🎲', 'Un poco de todo', _worldKinds),
  usStates('EE. UU.', '🇺🇸', '50 estados', [QuestionKind.region], mapId: 'eeuu', flagIso: 'us'),
  mxStates('México', '🇲🇽', '32 estados', [QuestionKind.region], mapId: 'mexico', flagIso: 'mx'),
  esProvinces('España', '🇪🇸', '50 provincias', [QuestionKind.region], mapId: 'espana', flagIso: 'es'),
  jpPrefectures('Japón', '🇯🇵', '47 prefecturas', [QuestionKind.region], mapId: 'japon', flagIso: 'jp');

  const GeoCategory(this.label, this.emoji, this.description, this.kinds, {this.mapId, this.flagIso});

  final String label;
  final String emoji;
  final String description;
  final List<QuestionKind> kinds;

  /// Mapa de regiones; `null` en las categorías de países del mundo.
  final String? mapId;
  final String? flagIso;

  bool get isMap => mapId != null;
}

class QuizConfig {
  const QuizConfig({
    required this.category,
    required this.withOptions,
    required this.regions,
    this.count = 10,
  });

  final GeoCategory category;

  /// `true` = 4 opciones (fácil). `false` = escribir la respuesta (difícil).
  final bool withOptions;

  /// Continentes (solo en las categorías de países del mundo).
  final Set<Continent> regions;

  /// Número de preguntas; 0 = todas las disponibles.
  final int count;
}

class Question {
  const Question({
    required this.kind,
    required this.answer,
    required this.accepted,
    this.country,
    this.region,
    this.options = const [],
  });

  final QuestionKind kind;

  /// País de la pregunta (en las categorías del mundo).
  final Country? country;

  /// Región marcada (en las categorías de mapa).
  final MapRegion? region;

  /// Respuesta que se muestra como correcta.
  final String answer;

  /// Todas las formas válidas al escribir (respuesta + alias).
  final List<String> accepted;

  /// 4 opciones barajadas; vacío en el modo sin opciones.
  final List<String> options;
}

/// Comprueba respuestas escritas: tolera tildes, mayúsculas, alias y pequeñas erratas,
/// pero nunca da por buena una respuesta que sea exactamente otra de las posibles.
class AnswerChecker {
  AnswerChecker(Iterable<String> knownAnswers) : _known = knownAnswers.map(normalizeText).toSet();

  final Set<String> _known;

  bool check(List<String> accepted, String input) {
    final typed = normalizeText(input);
    if (typed.isEmpty) return false;
    final ok = accepted.map(normalizeText).toSet();
    if (ok.contains(typed)) return true;
    if (_known.contains(typed)) return false;
    return ok.any((a) => levenshtein(typed, a) <= typoTolerance(a));
  }
}

/// Generador de preguntas de una categoría.
abstract class GeoQuiz {
  int poolSize(QuizConfig config);
  List<Question> generate(QuizConfig config);
  bool isCorrect(Question q, String input);

  static List<T> limit<T>(List<T> list, int count) =>
      count > 0 && list.length > count ? list.sublist(0, count) : list;
}

/// Banderas, capitales y siluetas de los países del mundo.
class QuizEngine implements GeoQuiz {
  QuizEngine(this.countries, {Random? random})
      : _random = random ?? Random(),
        _countryChecker = AnswerChecker(countries.expand((c) => c.acceptedNames)),
        _capitalChecker =
            AnswerChecker(countries.where((c) => c.hasUsableCapital).expand((c) => c.acceptedCapitals));

  final List<Country> countries;
  final Random _random;
  final AnswerChecker _countryChecker;
  final AnswerChecker _capitalChecker;

  bool _eligible(Country c, QuestionKind k) => switch (k) {
        QuestionKind.flag => true,
        QuestionKind.capital || QuestionKind.capitalOwner => c.hasUsableCapital,
        QuestionKind.silhouette => c.hasSilhouette,
        QuestionKind.region => false,
      };

  @override
  int poolSize(QuizConfig config) => countries
      .where((c) =>
          config.regions.contains(c.continent) && config.category.kinds.any((k) => _eligible(c, k)))
      .length;

  @override
  List<Question> generate(QuizConfig config) {
    final pool = countries.where((c) => config.regions.contains(c.continent)).toList()..shuffle(_random);
    final questions = <Question>[];
    for (final country in pool) {
      final kinds = config.category.kinds.where((k) => _eligible(country, k)).toList();
      if (kinds.isEmpty) continue;
      final kind = kinds[_random.nextInt(kinds.length)];
      questions.add(_build(country, kind, config.withOptions));
    }
    return GeoQuiz.limit(questions, config.count);
  }

  Question _build(Country country, QuestionKind kind, bool withOptions) {
    final isCapital = kind == QuestionKind.capital;
    return Question(
      kind: kind,
      country: country,
      answer: isCapital ? country.capital : country.name,
      accepted: isCapital ? country.acceptedCapitals : country.acceptedNames,
      options: withOptions ? _options(country, isCapital) : const [],
    );
  }

  List<String> _options(Country correct, bool capitals) {
    String text(Country c) => capitals ? c.capital : c.name;
    final others = countries.where((c) => c.iso != correct.iso && (!capitals || c.hasUsableCapital)).toList()
      ..shuffle(_random);
    // Primero los del mismo continente, para que no sea evidente.
    others.sort((a, b) =>
        (a.continent == correct.continent ? 0 : 1).compareTo(b.continent == correct.continent ? 0 : 1));
    return pickOptions(text(correct), others.map(text), _random);
  }

  @override
  bool isCorrect(Question q, String input) =>
      (q.kind == QuestionKind.capital ? _capitalChecker : _countryChecker).check(q.accepted, input);
}

/// Regiones de un mapa (estados, provincias…).
class MapQuizEngine implements GeoQuiz {
  MapQuizEngine(this.map, {Random? random})
      : _random = random ?? Random(),
        _checker = AnswerChecker(map.regions.expand((r) => r.acceptedNames));

  final GeoMap map;
  final Random _random;
  final AnswerChecker _checker;

  @override
  int poolSize(QuizConfig config) => map.regions.length;

  @override
  List<Question> generate(QuizConfig config) {
    final pool = [...map.regions]..shuffle(_random);
    return GeoQuiz.limit([
      for (final r in pool)
        Question(
          kind: QuestionKind.region,
          region: r,
          answer: r.name,
          accepted: r.acceptedNames,
          options: config.withOptions ? _options(r) : const [],
        ),
    ], config.count);
  }

  /// Las opciones falsas salen de las regiones cercanas, para que no baste con
  /// saber en qué parte del país está.
  List<String> _options(MapRegion correct) {
    double dist(MapRegion r) {
      final dx = (r.center.$1 - correct.center.$1).toDouble();
      final dy = (r.center.$2 - correct.center.$2).toDouble();
      return dx * dx + dy * dy;
    }

    final near = map.regions.where((r) => r.id != correct.id).toList()..sort((a, b) => dist(a).compareTo(dist(b)));
    final candidates = near.take(8).toList()..shuffle(_random);
    return pickOptions(correct.name, [...candidates, ...near.skip(8)].map((r) => r.name), _random);
  }

  @override
  bool isCorrect(Question q, String input) => _checker.check(q.accepted, input);
}

/// La respuesta + las 3 primeras alternativas distintas, barajadas.
List<String> pickOptions(String answer, Iterable<String> candidates, Random random) {
  final used = {normalizeText(answer)};
  final options = [answer];
  for (final c in candidates) {
    if (options.length == 4) break;
    if (used.add(normalizeText(c))) options.add(c);
  }
  return options..shuffle(random);
}
