import 'cards.dart';

class Bet {
  const Bet({required this.playerId, required this.suit, required this.sips});

  final String playerId;
  final Suit suit;
  final int sips;

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
  const BetOutcome({required this.bet, required this.won, required this.sips});

  final Bet bet;
  final bool won;

  /// Tragos que reparte (si ganó) o que bebe (si perdió).
  final int sips;
}

/// Quien acierta reparte lo apostado × [winMultiplier]; quien falla bebe lo apostado.
List<BetOutcome> settleBets(List<Bet> bets, Suit winner, {int winMultiplier = 1}) => [
      for (final b in bets)
        b.suit == winner
            ? BetOutcome(bet: b, won: true, sips: b.sips * winMultiplier)
            : BetOutcome(bet: b, won: false, sips: b.sips),
    ];
