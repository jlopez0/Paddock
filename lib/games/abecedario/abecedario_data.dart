import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';

const roscoColor = Color(0xFF4C8DFF);
const roscoAsset = 'assets/content/es/rosco.json';

/// Las 27 letras del rosco, en orden.
const roscoLetters = [
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'Ñ', //
  'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

enum RoscoLevel {
  easy('Fácil', 'facil'),
  medium('Medio', 'medio'),
  hard('Difícil', 'dificil'),
  mixed('Mezcla', '');

  const RoscoLevel(this.label, this.key);

  final String label;

  /// Valor de `dif` en el JSON ('' = cualquiera).
  final String key;
}

class RoscoEntry {
  const RoscoEntry({
    required this.id,
    required this.letter,
    required this.contains,
    required this.answer,
    required this.definition,
    required this.level,
  });

  final String id;
  final String letter;

  /// `true` = "Contiene la X"; `false` = "Empieza por X".
  final bool contains;
  final String answer;
  final String definition;

  /// 'facil' | 'medio' | 'dificil'
  final String level;

  String get clue => contains ? 'Contiene la $letter' : 'Empieza por $letter';

  factory RoscoEntry.fromJson(Map<String, dynamic> j) => RoscoEntry(
        id: j['id'] as String,
        letter: j['letra'] as String,
        contains: j['tipo'] == 'contiene',
        answer: j['resp'] as String,
        definition: j['def'] as String,
        level: j['dif'] as String,
      );
}

List<RoscoEntry> parseRosco(String json) => ((jsonDecode(json) as Map<String, dynamic>)['items'] as List)
    .cast<Map<String, dynamic>>()
    .map(RoscoEntry.fromJson)
    .toList();

final roscoBankProvider =
    FutureProvider<List<RoscoEntry>>((ref) async => parseRosco(await rootBundle.loadString(roscoAsset)));

/// Una definición al azar por cada letra, en orden alfabético y del nivel pedido
/// (si a una letra no le queda ninguna de ese nivel, se usa cualquiera).
List<RoscoEntry> generateRosco(List<RoscoEntry> bank, Random random, {RoscoLevel level = RoscoLevel.mixed}) {
  final out = <RoscoEntry>[];
  for (final l in roscoLetters) {
    final ofLetter = bank.where((e) => e.letter == l).toList();
    final ofLevel = level == RoscoLevel.mixed ? ofLetter : ofLetter.where((e) => e.level == level.key).toList();
    final options = ofLevel.isEmpty ? ofLetter : ofLevel;
    if (options.isNotEmpty) out.add(options[random.nextInt(options.length)]);
  }
  return out;
}

class RoscoSetup {
  const RoscoSetup({this.seconds = 20, this.auto = false, this.readSeconds = 5, this.level = RoscoLevel.mixed});

  final RoscoLevel level;

  /// Tiempo para pensar antes de desvelar la respuesta.
  final int seconds;

  /// Pasar solo a la siguiente letra tras [readSeconds].
  final bool auto;
  final int readSeconds;

  RoscoSetup copyWith({int? seconds, bool? auto, int? readSeconds, RoscoLevel? level}) => RoscoSetup(
        level: level ?? this.level,
        seconds: seconds ?? this.seconds,
        auto: auto ?? this.auto,
        readSeconds: readSeconds ?? this.readSeconds,
      );

  Map<String, dynamic> toJson() => {'seconds': seconds, 'auto': auto, 'read': readSeconds, 'level': level.name};

  factory RoscoSetup.fromJson(Map<String, dynamic> j) =>
      RoscoSetup(
        seconds: j['seconds'] as int,
        auto: j['auto'] as bool,
        readSeconds: j['read'] as int,
        level: RoscoLevel.values.asNameMap()[j['level']] ?? RoscoLevel.mixed,
      );
}

final roscoSetupProvider = NotifierProvider<RoscoSetupController, RoscoSetup>(RoscoSetupController.new);

class RoscoSetupController extends Notifier<RoscoSetup> {
  static const _key = 'rosco.setup.v1';

  @override
  RoscoSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const RoscoSetup();
    try {
      return RoscoSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const RoscoSetup();
    }
  }

  void update(RoscoSetup Function(RoscoSetup s) change) {
    state = change(state);
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(state.toJson()));
  }
}
