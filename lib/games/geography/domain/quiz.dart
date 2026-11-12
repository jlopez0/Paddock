import 'dart:math';

import 'country.dart';
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
}

/// Lo que elige el jugador en la pantalla de inicio.
enum GeoCategory {
  flags('Banderas', '🏳️', 'Bandera → país', [QuestionKind.flag]),
  capitals('Capitales', '🏛️', 'País → capital', [QuestionKind.capital]),
  owners('Capital → país', '📍', '¿De qué país es?', [QuestionKind.capitalOwner]),
  silhouettes('Siluetas', '🗺️', 'Forma → país', [QuestionKind.silhouette]),
  mix('Mezcla', '🎲', 'Un poco de todo', QuestionKind.values);

  const GeoCategory(this.label, this.emoji, this.description, this.kinds);

  final String label;
  final String emoji;
  final String description;
  final List<QuestionKind> kinds;
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
  final Set<Continent> regions;

  /// Número de preguntas; 0 = todas las disponibles.
  final int count;
}

class Question {
  const Question({
    required this.kind,
    required this.country,
    required this.answer,
    required this.accepted,
    this.options = const [],
  });

  final QuestionKind kind;
  final Country country;

  /// Respuesta que se muestra como correcta.
  final String answer;

  /// Todas las formas válidas al escribir (respuesta + alias).
  final List<String> accepted;

  /// 4 opciones barajadas; vacío en el modo sin opciones.
  final List<String> options;

  bool get answerIsCapital => kind == QuestionKind.capital;
}

class QuizEngine {
  QuizEngine(this.countries, {Random? random}) : _random = random ?? Random() {
    for (final c in countries) {
      for (final n in c.acceptedNames) {
        _countryNames.add(normalizeText(n));
      }
      if (c.hasUsableCapital) {
        for (final n in c.acceptedCapitals) {
          _capitalNames.add(normalizeText(n));
        }
      }
    }
  }

  final List<Country> countries;
  final Random _random;
  final Set<String> _countryNames = {};
  final Set<String> _capitalNames = {};

  bool _eligible(Country c, QuestionKind k) => switch (k) {
        QuestionKind.flag => true,
        QuestionKind.capital || QuestionKind.capitalOwner => c.hasUsableCapital,
        QuestionKind.silhouette => c.hasSilhouette,
      };

  /// Países con al menos una pregunta posible con esta configuración.
  int poolSize(QuizConfig config) => countries
      .where((c) =>
          config.regions.contains(c.continent) && config.category.kinds.any((k) => _eligible(c, k)))
      .length;

  List<Question> generate(QuizConfig config) {
    final pool = countries.where((c) => config.regions.contains(c.continent)).toList()..shuffle(_random);
    final questions = <Question>[];
    for (final country in pool) {
      final kinds = config.category.kinds.where((k) => _eligible(country, k)).toList();
      if (kinds.isEmpty) continue;
      final kind = kinds[_random.nextInt(kinds.length)];
      questions.add(_build(country, kind, config.withOptions));
    }
    return config.count > 0 && questions.length > config.count ? questions.sublist(0, config.count) : questions;
  }

  Question _build(Country country, QuestionKind kind, bool withOptions) {
    final isCapital = kind == QuestionKind.capital;
    final answer = isCapital ? country.capital : country.name;
    return Question(
      kind: kind,
      country: country,
      answer: answer,
      accepted: isCapital ? country.acceptedCapitals : country.acceptedNames,
      options: withOptions ? _options(country, isCapital) : const [],
    );
  }

  List<String> _options(Country correct, bool capitals) {
    String text(Country c) => capitals ? c.capital : c.name;
    final answer = text(correct);
    final used = {normalizeText(answer)};
    final others = countries.where((c) => c.iso != correct.iso && (!capitals || c.hasUsableCapital)).toList()
      ..shuffle(_random);
    // Primero los del mismo continente, para que no sea evidente.
    others.sort((a, b) =>
        (a.continent == correct.continent ? 0 : 1).compareTo(b.continent == correct.continent ? 0 : 1));
    final options = [answer];
    for (final c in others) {
      if (options.length == 4) break;
      if (used.add(normalizeText(text(c)))) options.add(text(c));
    }
    return options..shuffle(_random);
  }

  /// ¿Es correcta la respuesta escrita? Tolera tildes, mayúsculas, alias y pequeñas erratas,
  /// pero nunca da por buena una respuesta que sea exactamente otro país u otra capital.
  bool isCorrect(Question q, String input) {
    final typed = normalizeText(input);
    if (typed.isEmpty) return false;
    final accepted = q.accepted.map(normalizeText).toSet();
    if (accepted.contains(typed)) return true;
    final known = q.answerIsCapital ? _capitalNames : _countryNames;
    if (known.contains(typed)) return false;
    return accepted.any((a) => levenshtein(typed, a) <= typoTolerance(a));
  }
}
