import 'dart:math';

/// Motor puro de El Infiltrado (sin UI, sin Flutter).
///
/// Reglas:
/// - Mínimo [InfiltradoEngine.minPlayers] jugadores. Con 5 o más puede haber
///   2 infiltrados; con menos, solo 1.
/// - Los civiles ven la palabra y su categoría; los infiltrados solo la
///   categoría. La revelación es pasar el móvil de mano en mano, en el orden
///   de [InfiltradoDeal.players].
/// - Se vota a un sospechoso. Si hay empate se hace una segunda ronda solo
///   entre los empatados; si vuelve a haber empate, nadie es acusado.
/// - Si el acusado es infiltrado ("pillado"), tiene una última oportunidad:
///   si acierta la palabra, gana igualmente.
/// - Fichas: infiltrados ganan -> los demás pierden 1 cada uno. Se pilla al
///   infiltrado -> cada infiltrado pierde 2. (Con 2 infiltrados basta con
///   pillar a uno para que el grupo gane y los dos pierdan.)
enum InfiltradoRole { civil, impostor }

/// Lo que ve un jugador en su tarjeta al revelarla.
class RevealCard {
  const RevealCard({
    required this.role,
    required this.category,
    required this.word,
  });

  final InfiltradoRole role;
  final String category;

  /// `null` para el infiltrado: solo conoce la categoría.
  final String? word;

  bool get isImpostor => role == InfiltradoRole.impostor;
}

/// Reparto de una ronda.
class InfiltradoDeal {
  InfiltradoDeal._({
    required List<String> players,
    required this.word,
    required this.category,
    required Set<String> impostors,
  }) : players = List.unmodifiable(players),
       impostors = Set.unmodifiable(impostors);

  /// Ids de jugador, en el orden en que se pasa el móvil.
  final List<String> players;
  final String word;
  final String category;
  final Set<String> impostors;

  Iterable<String> get civils => players.where((p) => !impostors.contains(p));

  InfiltradoRole roleOf(String player) {
    if (!players.contains(player)) {
      throw ArgumentError.value(player, 'player', 'no está en la partida');
    }
    return impostors.contains(player)
        ? InfiltradoRole.impostor
        : InfiltradoRole.civil;
  }

  RevealCard cardFor(String player) {
    final role = roleOf(player);
    return RevealCard(
      role: role,
      category: category,
      word: role == InfiltradoRole.civil ? word : null,
    );
  }
}

/// Resultado de una votación.
class VoteResult {
  const VoteResult({
    required this.tally,
    required this.leaders,
    required this.accused,
    required this.needsRunoff,
  });

  /// Votos recibidos por cada jugador (solo los que recibieron alguno).
  final Map<String, int> tally;

  /// Jugadores con más votos (más de uno si hay empate).
  final List<String> leaders;

  /// Acusado final, o `null` si hay que desempatar o el desempate también
  /// empató.
  final String? accused;

  /// `true` si hay empate y toca una segunda ronda entre [leaders].
  final bool needsRunoff;
}

/// Resultado final de la ronda.
class InfiltradoOutcome {
  const InfiltradoOutcome({
    required this.accused,
    required this.caught,
    required this.guessedWord,
    required this.impostorsWin,
    required this.deltas,
  });

  /// Jugador acusado (`null` si el desempate empató).
  final String? accused;

  /// El acusado era infiltrado.
  final bool caught;

  /// El infiltrado pillado acertó la palabra en su última oportunidad.
  final bool guessedWord;

  final bool impostorsWin;

  /// Fichas por jugador (todos los jugadores aparecen; 0 si no cambia).
  final Map<String, int> deltas;
}

class InfiltradoEngine {
  const InfiltradoEngine._();

  static const minPlayers = 3;

  /// Mínimo de jugadores para jugar con 2 infiltrados.
  static const minPlayersForTwoImpostors = 5;

  /// Fichas que pierde cada infiltrado pillado.
  static const caughtPenalty = 2;

  /// Fichas que pierde cada civil si el infiltrado se salva.
  static const escapedPenalty = 1;

  /// Infiltrados permitidos para [playerCount] jugadores (0 si no hay
  /// jugadores suficientes).
  static int maxImpostors(int playerCount) {
    if (playerCount < minPlayers) return 0;
    return playerCount >= minPlayersForTwoImpostors ? 2 : 1;
  }

  /// Reparte los roles. Con la misma semilla y los mismos datos, el reparto
  /// es el mismo.
  static InfiltradoDeal deal({
    required List<String> players,
    required String word,
    required String category,
    int impostors = 1,
    Random? random,
  }) {
    if (players.length < minPlayers) {
      throw ArgumentError.value(
        players.length,
        'players',
        'hacen falta al menos $minPlayers jugadores',
      );
    }
    if (players.toSet().length != players.length) {
      throw ArgumentError.value(players, 'players', 'ids repetidos');
    }
    if (impostors < 1 || impostors > maxImpostors(players.length)) {
      throw ArgumentError.value(
        impostors,
        'impostors',
        'con ${players.length} jugadores solo puede haber '
            '1..${maxImpostors(players.length)} infiltrados',
      );
    }
    if (word.trim().isEmpty || category.trim().isEmpty) {
      throw ArgumentError('palabra y categoría no pueden estar vacías');
    }
    final shuffled = [...players]..shuffle(random ?? Random());
    return InfiltradoDeal._(
      players: players,
      word: word,
      category: category,
      impostors: shuffled.take(impostors).toSet(),
    );
  }

  /// Compara la palabra propuesta con la real, sin mayúsculas, tildes ni
  /// espacios sobrantes.
  static bool wordMatches(String guess, String word) =>
      _normalize(guess) == _normalize(word);

  static String _normalize(String s) {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    final buf = StringBuffer();
    for (final ch in s.trim().toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buf.write(i >= 0 ? to[i] : ch);
    }
    return buf.toString().replaceAll(RegExp(r'\s+'), ' ');
  }
}

/// Estado de una ronda: votación (con posible desempate) y resolución.
class InfiltradoRound {
  InfiltradoRound(this.deal);

  final InfiltradoDeal deal;

  Set<String>? _runoff;
  bool _voteClosed = false;
  String? _accused;

  /// Candidatos de la segunda ronda, o `null` si aún es la primera.
  Set<String>? get runoffCandidates => _runoff;

  bool get isVoteClosed => _voteClosed;

  /// Acusado tras cerrar la votación (`null` si empate sin resolver).
  String? get accused => _accused;

  /// Procesa una votación (`voter -> target`). Deben votar todos los
  /// jugadores y nadie puede votarse a sí mismo. En la segunda ronda solo
  /// se puede votar a los empatados.
  VoteResult vote(Map<String, String> votes) {
    if (_voteClosed) {
      throw StateError('La votación ya está cerrada');
    }
    final players = deal.players.toSet();
    if (votes.keys.toSet().difference(players).isNotEmpty ||
        players.difference(votes.keys.toSet()).isNotEmpty) {
      throw ArgumentError.value(votes, 'votes', 'debe votar cada jugador');
    }
    final allowed = _runoff ?? players;
    for (final e in votes.entries) {
      if (e.key == e.value) {
        throw ArgumentError.value(votes, 'votes', 'nadie puede votarse');
      }
      if (!allowed.contains(e.value)) {
        throw ArgumentError.value(
          votes,
          'votes',
          'voto a un jugador no válido: ${e.value}',
        );
      }
    }

    final tally = <String, int>{};
    for (final t in votes.values) {
      tally[t] = (tally[t] ?? 0) + 1;
    }
    final top = tally.values.reduce(max);
    // Mantiene el orden de la partida para que sea determinista.
    final leaders = deal.players.where((p) => tally[p] == top).toList();

    if (leaders.length == 1) {
      _voteClosed = true;
      _accused = leaders.first;
      return VoteResult(
        tally: tally,
        leaders: leaders,
        accused: _accused,
        needsRunoff: false,
      );
    }
    if (_runoff == null) {
      _runoff = leaders.toSet();
      return VoteResult(
        tally: tally,
        leaders: leaders,
        accused: null,
        needsRunoff: true,
      );
    }
    // Empate también en la segunda ronda: nadie es acusado.
    _voteClosed = true;
    return VoteResult(
      tally: tally,
      leaders: leaders,
      accused: null,
      needsRunoff: false,
    );
  }

  /// Resuelve la ronda tras cerrar la votación. [guess] es la palabra que
  /// propone el infiltrado pillado en su última oportunidad (se ignora si
  /// no lo pillaron).
  InfiltradoOutcome resolve({String? guess}) {
    if (!_voteClosed) {
      throw StateError('La votación aún no ha terminado');
    }
    final caught = _accused != null && deal.impostors.contains(_accused);
    final guessed =
        caught &&
        guess != null &&
        InfiltradoEngine.wordMatches(guess, deal.word);
    final impostorsWin = !caught || guessed;

    final deltas = {for (final p in deal.players) p: 0};
    if (impostorsWin) {
      for (final p in deal.civils) {
        deltas[p] = -InfiltradoEngine.escapedPenalty;
      }
    } else {
      for (final p in deal.impostors) {
        deltas[p] = -InfiltradoEngine.caughtPenalty;
      }
    }
    return InfiltradoOutcome(
      accused: _accused,
      caught: caught,
      guessedWord: guessed,
      impostorsWin: impostorsWin,
      deltas: Map.unmodifiable(deltas),
    );
  }
}
