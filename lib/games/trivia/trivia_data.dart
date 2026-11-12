import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';

const triviaColor = Color(0xFFF2994A);
const triviaAsset = 'assets/content/es/trivia.json';

enum TriviaCategory {
  historia('Historia', '🏛️'),
  ciencia('Ciencia', '🔬'),
  naturaleza('Naturaleza', '🌿'),
  arte('Arte y letras', '🎨'),
  deporte('Deporte', '⚽'),
  ocio('Cine y música', '🎬'),
  curiosidades('Curiosidades', '🧩');

  const TriviaCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

class TriviaQuestion {
  const TriviaQuestion({
    required this.id,
    required this.category,
    required this.text,
    required this.answer,
    required this.wrong,
    this.options = const [],
  });

  final String id;
  final TriviaCategory category;
  final String text;
  final String answer;
  final List<String> wrong;

  /// Las 4 opciones ya mezcladas (vacío en el banco sin preparar).
  final List<String> options;

  factory TriviaQuestion.fromJson(Map<String, dynamic> j) => TriviaQuestion(
        id: j['id'] as String,
        category: TriviaCategory.values.byName(j['cat'] as String),
        text: j['q'] as String,
        answer: j['a'] as String,
        wrong: (j['w'] as List).cast<String>(),
      );

  TriviaQuestion shuffled(Random random) => TriviaQuestion(
        id: id,
        category: category,
        text: text,
        answer: answer,
        wrong: wrong,
        options: [answer, ...wrong]..shuffle(random),
      );
}

List<TriviaQuestion> parseTrivia(String json) => ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
    .cast<Map<String, dynamic>>()
    .map(TriviaQuestion.fromJson)
    .toList();

final triviaBankProvider =
    FutureProvider<List<TriviaQuestion>>((ref) async => parseTrivia(await rootBundle.loadString(triviaAsset)));

/// Elige [count] preguntas (0 = todas) de las categorías dadas, mezcladas y con las opciones barajadas.
List<TriviaQuestion> generateTrivia(
    List<TriviaQuestion> bank, Set<TriviaCategory> categories, int count, Random random) {
  final pool = bank.where((q) => categories.contains(q.category)).toList()..shuffle(random);
  final picked = count == 0 ? pool : pool.take(count);
  return [for (final q in picked) q.shuffled(random)];
}

class TriviaSetup {
  const TriviaSetup({this.categories = const {...TriviaCategory.values}, this.count = 10});

  final Set<TriviaCategory> categories;
  final int count;

  TriviaSetup copyWith({Set<TriviaCategory>? categories, int? count}) =>
      TriviaSetup(categories: categories ?? this.categories, count: count ?? this.count);

  Map<String, dynamic> toJson() => {'cats': categories.map((c) => c.name).toList(), 'count': count};

  factory TriviaSetup.fromJson(Map<String, dynamic> j) {
    final cats = (j['cats'] as List).cast<String>().map(TriviaCategory.values.byName).toSet();
    return TriviaSetup(categories: cats.isEmpty ? const {...TriviaCategory.values} : cats, count: j['count'] as int);
  }
}

final triviaSetupProvider = NotifierProvider<TriviaSetupController, TriviaSetup>(TriviaSetupController.new);

class TriviaSetupController extends Notifier<TriviaSetup> {
  static const _key = 'trivia.setup.v1';

  @override
  TriviaSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const TriviaSetup();
    try {
      return TriviaSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TriviaSetup();
    }
  }

  void update(TriviaSetup Function(TriviaSetup s) change) {
    state = change(state);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toJson()));
  }
}

class TriviaMistake {
  const TriviaMistake(this.question, this.given);

  final TriviaQuestion question;
  final String given;
}

class TriviaResult {
  const TriviaResult({required this.total, required this.correct, required this.mistakes});

  final int total;
  final int correct;
  final List<TriviaMistake> mistakes;
}

final lastTriviaResultProvider = NotifierProvider<LastTriviaResult, TriviaResult?>(LastTriviaResult.new);

class LastTriviaResult extends Notifier<TriviaResult?> {
  @override
  TriviaResult? build() => null;

  void set(TriviaResult r) => state = r;
}
