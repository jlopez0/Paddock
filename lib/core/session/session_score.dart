import 'dart:convert';

/// Una variación de fichas de un jugador en una ronda de un juego.
class ScoreEvent {
  const ScoreEvent({
    required this.roundId,
    required this.gameId,
    required this.playerId,
    required this.delta,
    required this.at,
  });

  final String roundId;
  final String gameId;
  final String playerId;
  final int delta;
  final DateTime at;

  // Claves cortas: formato `session.v1`, no cambiar sin pasar a `.v2` con migración.
  Map<String, dynamic> toJson() => {
        'r': roundId,
        'g': gameId,
        'p': playerId,
        'd': delta,
        't': at.millisecondsSinceEpoch,
      };

  factory ScoreEvent.fromJson(Map<String, dynamic> json) => ScoreEvent(
        roundId: json['r'] as String,
        gameId: json['g'] as String,
        playerId: json['p'] as String,
        delta: json['d'] as int,
        at: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
      );
}

/// Total de fichas de un jugador, con su puesto (los empates comparten puesto: 1, 1, 3...).
class Standing {
  const Standing({required this.playerId, required this.total, required this.rank});

  final String playerId;
  final int total;
  final int rank;
}

/// Resumen de un juego dentro de la noche.
class GameStats {
  const GameStats({required this.gameId, required this.rounds, required this.standings});

  final String gameId;
  final int rounds;
  final List<Standing> standings;
}

/// La noche en curso: una lista de eventos de la que se deduce todo lo demás.
class Session {
  const Session({required this.id, required this.startedAt, this.events = const []});

  /// Noche vacía que empieza en `now`.
  factory Session.empty(DateTime now) =>
      Session(id: now.microsecondsSinceEpoch.toRadixString(36), startedAt: now);

  static const version = 1;

  /// Pasadas estas horas la noche se considera antigua (no caduca sola).
  static const staleAfter = Duration(hours: 12);

  final String id;
  final DateTime startedAt;
  final List<ScoreEvent> events;

  bool get isEmpty => events.isEmpty;

  /// `true` si la noche tiene eventos y empezó hace más de 12 h.
  bool isStale(DateTime now) => !isEmpty && now.difference(startedAt) > staleAfter;

  bool hasRound(String roundId) => events.any((e) => e.roundId == roundId);

  /// Ids de ronda en orden de registro, sin repetir.
  List<String> get roundIds {
    final seen = <String>{};
    return [
      for (final e in events)
        if (seen.add(e.roundId)) e.roundId,
    ];
  }

  /// Devuelve la sesión con la ronda añadida. Si el `roundId` ya existe, o no hay
  /// variaciones distintas de cero, devuelve la misma sesión (idempotente).
  Session withRound({
    required String roundId,
    required String gameId,
    required Map<String, int> deltas,
    required DateTime at,
  }) {
    if (hasRound(roundId)) return this;
    final entries = deltas.entries.where((e) => e.value != 0).toList();
    if (entries.isEmpty) return this;
    return Session(
      id: id,
      // La noche empieza con su primera ronda.
      startedAt: isEmpty ? at : startedAt,
      events: List.unmodifiable([
        ...events,
        for (final e in entries)
          ScoreEvent(roundId: roundId, gameId: gameId, playerId: e.key, delta: e.value, at: at),
      ]),
    );
  }

  /// Devuelve la sesión sin la última ronda registrada.
  Session withoutLastRound() {
    if (isEmpty) return this;
    final last = events.last.roundId;
    return Session(
      id: id,
      startedAt: startedAt,
      events: List.unmodifiable(events.where((e) => e.roundId != last)),
    );
  }

  /// Clasificación general, de más a menos fichas. Los empates comparten puesto
  /// y conservan el orden en que aparecieron por primera vez.
  List<Standing> get standings => _rank(events);

  /// Estadísticas por juego, en el orden en que se jugó cada uno por primera vez.
  List<GameStats> get statsByGame {
    final byGame = <String, List<ScoreEvent>>{};
    for (final e in events) {
      (byGame[e.gameId] ??= []).add(e);
    }
    return [
      for (final entry in byGame.entries)
        GameStats(
          gameId: entry.key,
          rounds: entry.value.map((e) => e.roundId).toSet().length,
          standings: _rank(entry.value),
        ),
    ];
  }

  /// Jugadores que más fichas han perdido (suma de variaciones negativas).
  /// Varios si empatan; vacío si nadie ha perdido.
  List<String> get biggestLosers {
    final lost = <String, int>{};
    for (final e in events) {
      if (e.delta < 0) lost[e.playerId] = (lost[e.playerId] ?? 0) + e.delta;
    }
    if (lost.isEmpty) return const [];
    final worst = lost.values.reduce((a, b) => a < b ? a : b);
    return [
      for (final entry in lost.entries)
        if (entry.value == worst) entry.key,
    ];
  }

  Map<String, dynamic> toJson() => {
        'v': version,
        'id': id,
        's': startedAt.millisecondsSinceEpoch,
        'e': events.map((e) => e.toJson()).toList(),
      };

  String encode() => jsonEncode(toJson());

  /// Lee una sesión guardada. Con cualquier dato corrupto o de otra versión
  /// devuelve una sesión vacía que empieza en `now`.
  static Session decode(String? raw, DateTime now) {
    if (raw == null) return Session.empty(now);
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['v'] != version) return Session.empty(now);
      return Session(
        id: json['id'] as String,
        startedAt: DateTime.fromMillisecondsSinceEpoch(json['s'] as int),
        events: List.unmodifiable(
          (json['e'] as List).map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>)),
        ),
      );
    } catch (_) {
      return Session.empty(now);
    }
  }
}

List<Standing> _rank(List<ScoreEvent> events) {
  final totals = <String, int>{};
  for (final e in events) {
    totals[e.playerId] = (totals[e.playerId] ?? 0) + e.delta;
  }
  final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final result = <Standing>[];
  for (var i = 0; i < sorted.length; i++) {
    final rank = i > 0 && sorted[i].value == sorted[i - 1].value ? result[i - 1].rank : i + 1;
    result.add(Standing(playerId: sorted[i].key, total: sorted[i].value, rank: rank));
  }
  return List.unmodifiable(result);
}
