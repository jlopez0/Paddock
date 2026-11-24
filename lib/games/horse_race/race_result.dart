import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/bets.dart';
import 'domain/cards.dart';

class RaceResult {
  const RaceResult({
    required this.roundId,
    required this.winner,
    required this.standings,
    required this.outcomes,
    required this.draws,
    this.allInTargets = const {},
    this.settled = false,
  });

  /// Identifica esta carrera en la Copa. Se fija al terminar, así la revancha es otra ronda
  /// y volver a entrar en el resultado no cuenta dos veces.
  final String roundId;
  final Suit winner;
  final List<Suit> standings;
  final List<BetOutcome> outcomes;
  final int draws;

  /// Para cada jugador con un All-in ganador, a quién reparte sus All-in.
  final Map<String, Set<String>> allInTargets;

  /// `true` cuando las fichas ya se han enviado a la Copa.
  final bool settled;

  RaceResult copyWith({Map<String, Set<String>>? allInTargets, bool? settled}) => RaceResult(
        roundId: roundId,
        winner: winner,
        standings: standings,
        outcomes: outcomes,
        draws: draws,
        allInTargets: allInTargets ?? this.allInTargets,
        settled: settled ?? this.settled,
      );
}

/// Resultado de la última carrera, para la pantalla de resultados.
final lastRaceResultProvider = NotifierProvider<LastRaceResult, RaceResult?>(LastRaceResult.new);

class LastRaceResult extends Notifier<RaceResult?> {
  @override
  RaceResult? build() => null;

  void set(RaceResult r) => state = r;

  /// Cambia a quién reparte [winnerId] sus All-in (no hace nada si ya está liquidada).
  void setTargets(String winnerId, Set<String> targets) {
    final r = state;
    if (r == null || r.settled) return;
    state = r.copyWith(allInTargets: {...r.allInTargets, winnerId: Set.unmodifiable(targets)});
  }

  void markSettled() {
    final r = state;
    if (r != null) state = r.copyWith(settled: true);
  }
}
