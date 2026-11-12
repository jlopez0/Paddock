import 'cards.dart';

class Bet {
  const Bet({required this.playerId, required this.suit, required this.sips});

  final String playerId;
  final Suit suit;
  /// Tragos apostados (1–10), o [hidalgo] para beberse el vaso entero.
  final int sips;

  /// Apuesta máxima: vaso entero (💀).
  static const hidalgo = 0;

  bool get isHidalgo => sips == hidalgo;

  Bet copyWith({Suit? suit, int? sips}) =>
      Bet(playerId: playerId, suit: suit ?? this.suit, sips: sips ?? this.sips);

  Map<String, dynamic> toJson() => {'player': playerId, 'suit': suit.name, 'sips': sips};

  factory Bet.fromJson(Map<String, dynamic> j) => Bet(
        playerId: j['player'] as String,
        suit: Suit.values.byName(j['suit'] as String),
        sips: j['sips'] as int,
      );
}

class BetOutcome {
  const BetOutcome({required this.bet, required this.won, required this.sips, this.hidalgos = 0});

  final Bet bet;
  final bool won;

  /// Tragos que reparte (si ganó) o que bebe (si perdió). 0 si fue hidalgo.
  final int sips;

  /// Hidalgos que reparte (si ganó) o que bebe (si perdió).
  final int hidalgos;

  bool get isHidalgo => hidalgos > 0;

  /// Texto para mostrar: `3 🍺`, `💀` o `💀💀`.
  String get label => isHidalgo ? "💀" * hidalgos : "$sips 🍺";
}

/// Quien acierta reparte lo apostado × [winMultiplier]; quien falla bebe lo apostado.
/// Un hidalgo ganador reparte [winMultiplier] hidalgos (2 si se reparte el doble).
List<BetOutcome> settleBets(List<Bet> bets, Suit winner, {int winMultiplier = 1}) => [
      for (final b in bets)
        b.suit == winner
            ? (b.isHidalgo
                ? BetOutcome(bet: b, won: true, sips: 0, hidalgos: winMultiplier)
                : BetOutcome(bet: b, won: true, sips: b.sips * winMultiplier))
            : (b.isHidalgo
                ? BetOutcome(bet: b, won: false, sips: 0, hidalgos: 1)
                : BetOutcome(bet: b, won: false, sips: b.sips)),
    ];
