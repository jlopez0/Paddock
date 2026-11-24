import 'dart:math';

import 'cards.dart';

/// Fichas que vale un All-in en la Copa (supuesto del producto, ver `docs/decisions.md`).
const int kAllInChips = 10;

/// Cuántos All-in reparte quien apuesta All-in y acierta (a personas distintas).
const int kAllInShares = 2;

class Bet {
  const Bet({required this.playerId, required this.suit, required this.chips});

  final String playerId;
  final Suit suit;

  /// Fichas apostadas (1–5), o [allIn].
  final int chips;

  /// Apuesta máxima: All-in (vale [kAllInChips] fichas).
  static const allIn = 0;

  static const minChips = 1;
  static const maxChips = 5;

  bool get isAllIn => chips == allIn;

  Bet copyWith({Suit? suit, int? chips}) => Bet(
    playerId: playerId,
    suit: suit ?? this.suit,
    chips: chips ?? this.chips,
  );

  /// Ajusta unas fichas guardadas al rango válido: 0 es All-in, el resto se recorta a 1–5.
  static int normalizeChips(int raw) =>
      raw == allIn ? allIn : raw.clamp(minChips, maxChips);

  Map<String, dynamic> toJson() => {
    'player': playerId,
    'suit': suit.name,
    'chips': chips,
  };

  /// Lee también el formato antiguo (clave `sips`, de 1 a 10 y 0 para el vaso entero).
  factory Bet.fromJson(Map<String, dynamic> j) {
    final raw = ((j['chips'] ?? j['sips']) as num?)?.toInt() ?? 2;
    return Bet(
      playerId: j['player'] as String,
      suit: Suit.values.byName(j['suit'] as String),
      chips: normalizeChips(raw),
    );
  }
}

class BetOutcome {
  const BetOutcome({
    required this.bet,
    required this.won,
    required this.chips,
    this.allIns = 0,
  });

  final Bet bet;
  final bool won;

  /// Fichas que reparte (si ganó) o que pierde (si perdió). 0 si fue All-in.
  final int chips;

  /// All-in que reparte (si ganó) o que paga (si perdió).
  final int allIns;

  bool get isAllIn => allIns > 0;

  /// Fichas totales en juego (un All-in vale [kAllInChips]).
  int get chipValue => chips + allIns * kAllInChips;

  /// Texto para mostrar: `3 fichas`, `All-in` o `All-in ×2`.
  String get label {
    if (isAllIn) return allIns > 1 ? 'All-in ×$allIns' : 'All-in';
    return chips == 1 ? '1 ficha' : '$chips fichas';
  }
}

/// Quien acierta reparte lo apostado × [winMultiplier]; quien falla pierde lo apostado.
/// Un All-in ganador reparte siempre [kAllInShares] All-in; uno perdedor paga 1.
List<BetOutcome> settleBets(
  List<Bet> bets,
  Suit winner, {
  int winMultiplier = 1,
}) => [
  for (final b in bets)
    b.suit == winner
        ? (b.isAllIn
              ? BetOutcome(bet: b, won: true, chips: 0, allIns: kAllInShares)
              : BetOutcome(bet: b, won: true, chips: b.chips * winMultiplier))
        : (b.isAllIn
              ? BetOutcome(bet: b, won: false, chips: 0, allIns: 1)
              : BetOutcome(bet: b, won: false, chips: b.chips)),
];

/// A cuántas personas puede repartir un All-in ganador si hay [others] jugadores más.
int allInTargetCount(int others) => min(kAllInShares, max(0, others));

/// Fichas resultantes de una carrera.
class RaceSettlement {
  const RaceSettlement({required this.deltas, required this.losses});

  /// Neto por jugador (positivo = gana, negativo = pierde). Es lo que va a la Copa.
  final Map<String, int> deltas;

  /// Fichas que paga cada jugador (sin netear con lo que gana). Es lo que muestra el banner.
  final Map<String, int> losses;
}

/// Calcula las fichas de cada jugador. [allInTargets] es, para cada jugador con un All-in
/// ganador, a quién reparte sus All-in (se ignoran repetidos, él mismo y lo que pase de
/// [kAllInShares]). Un All-in ganador gana [kAllInChips] por cada persona elegida.
RaceSettlement settleChips(
  List<BetOutcome> outcomes,
  Map<String, Set<String>> allInTargets,
) {
  final deltas = <String, int>{};
  final losses = <String, int>{};
  void add(Map<String, int> m, String id, int v) => m[id] = (m[id] ?? 0) + v;

  for (final o in outcomes) {
    final id = o.bet.playerId;
    if (!o.won) {
      add(losses, id, o.chipValue);
      add(deltas, id, -o.chipValue);
    } else if (o.isAllIn) {
      final targets = [
        for (final t in allInTargets[id] ?? const <String>{})
          if (t != id) t,
      ].take(o.allIns).toList();
      add(deltas, id, targets.length * kAllInChips);
      for (final t in targets) {
        add(losses, t, kAllInChips);
        add(deltas, t, -kAllInChips);
      }
    } else {
      add(deltas, id, o.chips);
    }
  }
  return RaceSettlement(deltas: deltas, losses: losses);
}
