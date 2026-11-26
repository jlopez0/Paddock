import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';

const abecedarioColor = Color(0xFF4C8DFF);
const abecedarioAsset = 'assets/content/es/abecedario.json';

/// Las 27 letras del abecedario, en orden.
const abecedarioLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', //
  'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

enum AbecedarioLevel {
  easy('Fácil', 'facil'),
  medium('Medio', 'medio'),
  hard('Difícil', 'dificil'),
  mixed('Mezcla', '');

  const AbecedarioLevel(this.label, this.key);

  final String label;

  /// Valor de `dif` en el JSON ('' = cualquiera).
  final String key;
}

class AbecedarioEntry {
  const AbecedarioEntry({
    required this.id,
    required this.letter,
    required this.contains,
    required this.answer,
    required this.definition,
    required this.level,
  });

  final String id;
  final String letter;

  /// `true` = "Contiene la X"; `false` = "Comienza por la X".
  final bool contains;
  final String answer;
  final String definition;

  /// 'facil' | 'medio' | 'dificil'
  final String level;

  String get clue =>
      contains ? 'Contiene la $letter' : 'Comienza por la $letter';

  factory AbecedarioEntry.fromJson(Map<String, dynamic> j) => AbecedarioEntry(
    id: j['id'] as String,
    letter: j['letra'] as String,
    contains: j['tipo'] == 'contiene',
    answer: j['resp'] as String,
    definition: j['def'] as String,
    level: j['dif'] as String,
  );
}

List<AbecedarioEntry> parseAbecedario(String json) =>
    ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
        .cast<Map<String, dynamic>>()
        .map(AbecedarioEntry.fromJson)
        .toList();

final abecedarioBankProvider = FutureProvider<List<AbecedarioEntry>>(
  (ref) async => parseAbecedario(await rootBundle.loadString(abecedarioAsset)),
);

/// Una definición al azar por cada letra, en orden alfabético y del nivel pedido
/// (si a una letra no le queda ninguna de ese nivel, se usa cualquiera).
List<AbecedarioEntry> generateAbecedario(
  List<AbecedarioEntry> bank,
  Random random, {
  AbecedarioLevel level = AbecedarioLevel.mixed,
}) {
  final out = <AbecedarioEntry>[];
  for (final l in abecedarioLetters) {
    final ofLetter = bank.where((e) => e.letter == l).toList();
    final ofLevel = level == AbecedarioLevel.mixed
        ? ofLetter
        : ofLetter.where((e) => e.level == level.key).toList();
    final options = ofLevel.isEmpty ? ofLetter : ofLevel;
    if (options.isNotEmpty) out.add(options[random.nextInt(options.length)]);
  }
  return out;
}

class AbecedarioSetup {
  const AbecedarioSetup({
    this.seconds = 20,
    this.auto = false,
    this.readSeconds = 5,
    this.level = AbecedarioLevel.mixed,
  });

  final AbecedarioLevel level;

  /// Tiempo para pensar antes de desvelar la respuesta.
  final int seconds;

  /// Pasar solo a la siguiente letra tras [readSeconds].
  final bool auto;
  final int readSeconds;

  AbecedarioSetup copyWith({
    int? seconds,
    bool? auto,
    int? readSeconds,
    AbecedarioLevel? level,
  }) => AbecedarioSetup(
    level: level ?? this.level,
    seconds: seconds ?? this.seconds,
    auto: auto ?? this.auto,
    readSeconds: readSeconds ?? this.readSeconds,
  );

  Map<String, dynamic> toJson() => {
    'seconds': seconds,
    'auto': auto,
    'read': readSeconds,
    'level': level.name,
  };

  factory AbecedarioSetup.fromJson(Map<String, dynamic> j) => AbecedarioSetup(
    seconds: j['seconds'] as int,
    auto: j['auto'] as bool,
    readSeconds: j['read'] as int,
    level:
        AbecedarioLevel.values.asNameMap()[j['level']] ?? AbecedarioLevel.mixed,
  );
}

final abecedarioSetupProvider =
    NotifierProvider<AbecedarioSetupController, AbecedarioSetup>(
      AbecedarioSetupController.new,
    );

class AbecedarioSetupController extends Notifier<AbecedarioSetup> {
  static const _key = 'abecedario.setup.v1';

  @override
  AbecedarioSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const AbecedarioSetup();
    try {
      return AbecedarioSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AbecedarioSetup();
    }
  }

  void update(AbecedarioSetup Function(AbecedarioSetup s) change) {
    state = change(state);
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(state.toJson()));
  }
}
