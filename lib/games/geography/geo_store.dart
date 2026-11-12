import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import 'domain/country.dart';
import 'domain/quiz.dart';

/// Configuración de la partida; se recuerda entre sesiones.
class GeoSetup {
  const GeoSetup({
    this.category = GeoCategory.flags,
    this.withOptions = true,
    this.regions = const {...Continent.values},
    this.count = 10,
  });

  final GeoCategory category;
  final bool withOptions;
  final Set<Continent> regions;
  final int count;

  QuizConfig get config =>
      QuizConfig(category: category, withOptions: withOptions, regions: regions, count: count);

  GeoSetup copyWith({GeoCategory? category, bool? withOptions, Set<Continent>? regions, int? count}) => GeoSetup(
        category: category ?? this.category,
        withOptions: withOptions ?? this.withOptions,
        regions: regions ?? this.regions,
        count: count ?? this.count,
      );

  /// Clave para los récords: mismo tipo de partida = mismo récord.
  String get recordKey => '${category.name}|${withOptions ? 'op' : 'esc'}|$count|${regions.length == Continent.values.length ? 'mundo' : (regions.map((r) => r.name).toList()..sort()).join('+')}';

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'options': withOptions,
        'regions': regions.map((r) => r.name).toList(),
        'count': count,
      };

  factory GeoSetup.fromJson(Map<String, dynamic> j) {
    final regions = (j['regions'] as List).cast<String>().map(Continent.values.byName).toSet();
    return GeoSetup(
      category: GeoCategory.values.byName(j['category'] as String),
      withOptions: j['options'] as bool,
      regions: regions.isEmpty ? const {...Continent.values} : regions,
      count: j['count'] as int,
    );
  }
}

final geoSetupProvider = NotifierProvider<GeoSetupController, GeoSetup>(GeoSetupController.new);

class GeoSetupController extends Notifier<GeoSetup> {
  static const _key = 'geo.setup.v1';

  @override
  GeoSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const GeoSetup();
    try {
      return GeoSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const GeoSetup();
    }
  }

  void update(GeoSetup Function(GeoSetup s) change) {
    state = change(state);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toJson()));
  }
}

/// Mejor puntuación por tipo de partida.
final geoRecordsProvider = NotifierProvider<GeoRecords, Map<String, int>>(GeoRecords.new);

class GeoRecords extends Notifier<Map<String, int>> {
  static const _key = 'geo.records.v1';

  @override
  Map<String, int> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).cast<String, int>();
    } catch (_) {
      return const {};
    }
  }

  /// Guarda el resultado y dice si es un récord nuevo (y no es el primero de ese tipo).
  bool submit(String key, int correct) {
    final previous = state[key];
    if (previous != null && correct <= previous) return false;
    state = {...state, key: correct};
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state));
    return previous != null;
  }
}

class QuizMistake {
  const QuizMistake(this.question, this.given);

  final Question question;

  /// Lo que respondió; `null` si pulsó "Ni idea".
  final String? given;
}

class QuizResult {
  const QuizResult({
    required this.setup,
    required this.total,
    required this.correct,
    required this.mistakes,
    required this.newRecord,
    required this.best,
  });

  final GeoSetup setup;
  final int total;
  final int correct;
  final List<QuizMistake> mistakes;
  final bool newRecord;
  final int best;
}

final lastQuizResultProvider = NotifierProvider<LastQuizResult, QuizResult?>(LastQuizResult.new);

class LastQuizResult extends Notifier<QuizResult?> {
  @override
  QuizResult? build() => null;

  void set(QuizResult r) => state = r;
}
