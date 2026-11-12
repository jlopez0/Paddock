import 'package:flutter/painting.dart';

enum Suit {
  oros('Oros', Color(0xFFE8B84A)),
  copas('Copas', Color(0xFFE5575C)),
  espadas('Espadas', Color(0xFF4FA3F7)),
  bastos('Bastos', Color(0xFF5BC27A));

  const Suit(this.label, this.color);

  final String label;
  final Color color;
}

/// Carta de la baraja española (1–12). El 11 es el caballo.
class PlayingCard {
  const PlayingCard(this.suit, this.rank);

  final Suit suit;
  final int rank;

  static const horseRank = 11;

  String get asset => 'assets/cards/${suit.name}_$rank.png';
  static const backAsset = 'assets/cards/reverso.png';
  static String horseAsset(Suit s) => 'assets/cards/${s.name}_$horseRank.png';

  @override
  bool operator ==(Object other) => other is PlayingCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${suit.name}_$rank';
}
