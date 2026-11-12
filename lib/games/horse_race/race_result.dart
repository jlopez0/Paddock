import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/bets.dart';
import 'domain/cards.dart';

class RaceResult {
  const RaceResult({required this.winner, required this.standings, required this.outcomes, required this.draws});

  final Suit winner;
  final List<Suit> standings;
  final List<BetOutcome> outcomes;
  final int draws;
}

/// Resultado de la última carrera, para la pantalla de resultados.
final lastRaceResultProvider = NotifierProvider<LastRaceResult, RaceResult?>(LastRaceResult.new);

class LastRaceResult extends Notifier<RaceResult?> {
  @override
  RaceResult? build() => null;

  void set(RaceResult r) => state = r;
}
