import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content/prompts.dart';
import '../../core/players/player.dart';
import '../../core/session/session_controller.dart';
import '../../core/storage.dart';
import 'domain/infiltrado_engine.dart';

/// Identificador del juego en la Copa y en la ruta.
const kInfiltradoId = 'infiltrado';

const kInfiltradoAsset = 'assets/content/es/infiltrado.json';

/// Duraciones del debate en segundos (0 = sin temporizador).
const kDebateOptions = [0, 120, 180, 300];

/// Una palabra secreta con su categoría.
class InfiltradoWord {
  const InfiltradoWord({
    required this.id,
    required this.level,
    required this.category,
    required this.word,
  });

  final String id;
  final PromptLevel level;
  final String category;
  final String word;
}

/// Palabras de reserva si no se puede leer `assets/content/es/infiltrado.json`.
const List<InfiltradoWord> kFallbackWords = [
  InfiltradoWord(
    id: 'inf_test_01',
    level: PromptLevel.suave,
    category: 'Comida',
    word: 'Tortilla',
  ),
  InfiltradoWord(
    id: 'inf_test_02',
    level: PromptLevel.suave,
    category: 'Comida',
    word: 'Paella',
  ),
  InfiltradoWord(
    id: 'inf_test_03',
    level: PromptLevel.suave,
    category: 'Lugares',
    word: 'Playa',
  ),
  InfiltradoWord(
    id: 'inf_test_04',
    level: PromptLevel.suave,
    category: 'Lugares',
    word: 'Biblioteca',
  ),
  InfiltradoWord(
    id: 'inf_test_05',
    level: PromptLevel.suave,
    category: 'Profesiones',
    word: 'Bombero',
  ),
  InfiltradoWord(
    id: 'inf_test_06',
    level: PromptLevel.suave,
    category: 'Profesiones',
    word: 'Fontanero',
  ),
  InfiltradoWord(
    id: 'inf_test_07',
    level: PromptLevel.suave,
    category: 'Objetos',
    word: 'Paraguas',
  ),
  InfiltradoWord(
    id: 'inf_test_08',
    level: PromptLevel.suave,
    category: 'Objetos',
    word: 'Linterna',
  ),
  InfiltradoWord(
    id: 'inf_test_09',
    level: PromptLevel.suave,
    category: 'Animales',
    word: 'Delfín',
  ),
  InfiltradoWord(
    id: 'inf_test_10',
    level: PromptLevel.suave,
    category: 'Animales',
    word: 'Jirafa',
  ),
];

/// Parsea `{ "version": 1, "items": [{id, nivel, categoria, palabra}] }`.
/// Ignora entradas incompletas o con nivel desconocido (nunca lanza por una).
List<InfiltradoWord> parseInfiltradoWords(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  final out = <InfiltradoWord>[];
  for (final raw in (data['items'] as List)) {
    if (raw is! Map<String, dynamic>) continue;
    final id = raw['id'];
    final category = raw['categoria'];
    final word = raw['palabra'];
    final level = PromptLevel.tryParse(raw['nivel'] as String?);
    if (id is! String ||
        category is! String ||
        word is! String ||
        level == null) {
      continue;
    }
    if (category.trim().isEmpty || word.trim().isEmpty) continue;
    out.add(
      InfiltradoWord(
        id: id,
        level: level,
        category: category.trim(),
        word: word.trim(),
      ),
    );
  }
  return out;
}

/// Palabras del juego. Si el fichero no existe o está vacío usa [kFallbackWords].
final infiltradoWordsProvider = FutureProvider<List<InfiltradoWord>>((
  ref,
) async {
  try {
    final words = parseInfiltradoWords(
      await rootBundle.loadString(kInfiltradoAsset),
    );
    if (words.isNotEmpty) return words;
  } catch (_) {
    // Sin fichero de contenido: se usa el mínimo de prueba.
  }
  return kFallbackWords;
});

/// Configuración de la partida (clave `infiltrado.setup.v1`).
class InfiltradoSetup {
  const InfiltradoSetup({
    this.playerIds,
    this.impostors = 1,
    this.levels = const {PromptLevel.suave},
    this.debateSeconds = 0,
  });

  /// Jugadores elegidos. `null` = nunca se ha configurado (se eligen todos).
  final Set<String>? playerIds;
  final int impostors;
  final Set<PromptLevel> levels;
  final int debateSeconds;

  InfiltradoSetup copyWith({
    Set<String>? playerIds,
    int? impostors,
    Set<PromptLevel>? levels,
    int? debateSeconds,
  }) => InfiltradoSetup(
    playerIds: playerIds ?? this.playerIds,
    impostors: impostors ?? this.impostors,
    levels: levels ?? this.levels,
    debateSeconds: debateSeconds ?? this.debateSeconds,
  );

  Map<String, dynamic> toJson() => {
    'players': ?playerIds?.toList(),
    'impostors': impostors,
    'levels': levels.map((l) => l.name).toList(),
    'debate': debateSeconds,
  };

  factory InfiltradoSetup.fromJson(Map<String, dynamic> j) {
    final levels = <PromptLevel>{
      for (final n in (j['levels'] as List? ?? const []))
        ?PromptLevel.tryParse(n as String?),
    };
    final debate = j['debate'] as int? ?? 0;
    return InfiltradoSetup(
      playerIds: (j['players'] as List?)?.cast<String>().toSet(),
      impostors: (j['impostors'] as int? ?? 1).clamp(1, 2),
      levels: levels.isEmpty ? const {PromptLevel.suave} : levels,
      debateSeconds: kDebateOptions.contains(debate) ? debate : 0,
    );
  }
}

final infiltradoSetupProvider =
    NotifierProvider<InfiltradoSetupController, InfiltradoSetup>(
      InfiltradoSetupController.new,
    );

class InfiltradoSetupController extends Notifier<InfiltradoSetup> {
  static const _key = 'infiltrado.setup.v1';

  @override
  InfiltradoSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const InfiltradoSetup();
    try {
      return InfiltradoSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const InfiltradoSetup();
    }
  }

  void set(InfiltradoSetup s) {
    state = s;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(s.toJson()));
  }
}

/// Fuente de azar inyectable (los tests la fijan con una semilla).
final infiltradoRandomProvider = Provider<Random>((ref) => Random());

/// Ids de palabras ya usadas esta noche, para no repetir hasta agotarlas.
final infiltradoUsedProvider =
    NotifierProvider<InfiltradoUsedController, Set<String>>(
      InfiltradoUsedController.new,
    );

class InfiltradoUsedController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void add(String id) => state = {...state, id};
  void reset() => state = const {};
}

/// Palabras que aún se pueden jugar con los [levels] elegidos.
List<InfiltradoWord> availableWords(
  List<InfiltradoWord> words,
  Set<PromptLevel> levels,
  Set<String> used,
) => [
  for (final w in words)
    if (levels.contains(w.level) && !used.contains(w.id)) w,
];

/// Ronda en curso.
class InfiltradoGame {
  const InfiltradoGame({
    required this.roundId,
    required this.deal,
    required this.round,
    required this.debateSeconds,
    this.lastVote,
    this.outcome,
  });

  final String roundId;
  final InfiltradoDeal deal;
  final InfiltradoRound round;
  final int debateSeconds;

  /// Última votación cerrada (para mostrar el recuento en el resultado).
  final VoteResult? lastVote;

  /// `null` hasta que se resuelve (puede faltar la última oportunidad).
  final InfiltradoOutcome? outcome;

  InfiltradoGame copyWith({VoteResult? lastVote, InfiltradoOutcome? outcome}) =>
      InfiltradoGame(
        roundId: roundId,
        deal: deal,
        round: round,
        debateSeconds: debateSeconds,
        lastVote: lastVote ?? this.lastVote,
        outcome: outcome ?? this.outcome,
      );
}

enum InfiltradoStart { ok, notEnoughPlayers, noWords }

final infiltradoGameProvider =
    NotifierProvider<InfiltradoGameController, InfiltradoGame?>(
      InfiltradoGameController.new,
    );

class InfiltradoGameController extends Notifier<InfiltradoGame?> {
  int _counter = 0;

  @override
  InfiltradoGame? build() => null;

  /// Reparte una ronda nueva. [players] son los jugadores elegidos, en el
  /// orden en que se pasa el móvil.
  InfiltradoStart start({
    required List<Player> players,
    required InfiltradoSetup setup,
    required List<InfiltradoWord> words,
  }) {
    if (players.length < InfiltradoEngine.minPlayers) {
      return InfiltradoStart.notEnoughPlayers;
    }
    final used = ref.read(infiltradoUsedProvider);
    final pool = availableWords(words, setup.levels, used);
    if (pool.isEmpty) return InfiltradoStart.noWords;

    final random = ref.read(infiltradoRandomProvider);
    final word = pool[random.nextInt(pool.length)];
    final impostors = setup.impostors.clamp(
      1,
      InfiltradoEngine.maxImpostors(players.length),
    );
    final deal = InfiltradoEngine.deal(
      players: [for (final p in players) p.id],
      word: word.word,
      category: word.category,
      impostors: impostors,
      random: random,
    );
    ref.read(infiltradoUsedProvider.notifier).add(word.id);
    final now = ref.read(sessionClockProvider)();
    state = InfiltradoGame(
      roundId: '$kInfiltradoId-${now.microsecondsSinceEpoch}-${_counter++}',
      deal: deal,
      round: InfiltradoRound(deal),
      debateSeconds: setup.debateSeconds,
    );
    return InfiltradoStart.ok;
  }

  void setLastVote(VoteResult vote) {
    final g = state;
    if (g != null) state = g.copyWith(lastVote: vote);
  }

  /// Resuelve la ronda y suma las fichas a la Copa (una sola vez por ronda).
  /// [guess] es la palabra del infiltrado pillado en su última oportunidad.
  InfiltradoOutcome? finish({String? guess}) {
    final g = state;
    if (g == null) return null;
    if (g.outcome != null) return g.outcome;
    final outcome = g.round.resolve(guess: guess);
    ref
        .read(sessionProvider.notifier)
        .award(g.roundId, kInfiltradoId, outcome.deltas);
    state = g.copyWith(outcome: outcome);
    return outcome;
  }
}
