import 'dart:math';

import 'cards.dart';

/// Reglas de la carrera de caballos con baraja española (48 cartas):
/// - Los 4 caballos (el 11 de cada palo) salen de la casilla 0.
/// - La meta está en la casilla [RaceConfig.length]. Encima de las casillas
///   1..length-1 hay una carta obstáculo boca abajo.
/// - Cada carta del mazo hace avanzar 1 al caballo de su palo.
/// - Cuando todos los caballos han alcanzado la casilla k, se descubre el
///   obstáculo k y el caballo de su palo retrocede 1.
/// - Gana el primer caballo que llega a la meta.
/// - Si el mazo se agota, se barajan los descartes y se sigue.
class RaceConfig {
  const RaceConfig({this.length = 6, this.obstacles = true})
      : assert(length >= 4 && length <= 9);

  /// Casillas hasta la meta. 6 = la versión clásica (5 obstáculos).
  final int length;
  final bool obstacles;

  int get obstacleCount => obstacles ? length - 1 : 0;
}

sealed class RaceEvent {
  const RaceEvent();
}

class HorseAdvanced extends RaceEvent {
  const HorseAdvanced(this.card);
  final PlayingCard card;
}

class ObstacleRevealed extends RaceEvent {
  const ObstacleRevealed(this.column, this.card);

  /// Casilla (1-based) sobre la que estaba el obstáculo.
  final int column;
  final PlayingCard card;
}

class DeckReshuffled extends RaceEvent {
  const DeckReshuffled();
}

class HorseWon extends RaceEvent {
  const HorseWon(this.suit);
  final Suit suit;
}

class RaceEngine {
  RaceEngine({this.config = const RaceConfig(), Random? random})
      : _random = random ?? Random() {
    final cards = [
      for (final s in Suit.values)
        for (var r = 1; r <= 12; r++)
          if (r != PlayingCard.horseRank) PlayingCard(s, r),
    ]..shuffle(_random);
    _obstacles = cards.sublist(0, config.obstacleCount);
    _deck = cards.sublist(config.obstacleCount);
  }

  final RaceConfig config;
  final Random _random;

  late final List<PlayingCard> _obstacles;
  late List<PlayingCard> _deck;
  final List<PlayingCard> _discard = [];
  final Map<Suit, int> _positions = {for (final s in Suit.values) s: 0};
  int _revealed = 0;
  Suit? _winner;
  PlayingCard? _lastCard;
  int _draws = 0;

  Map<Suit, int> get positions => Map.unmodifiable(_positions);
  List<PlayingCard> get obstacles => List.unmodifiable(_obstacles);

  /// Número de obstáculos ya descubiertos (siempre los primeros).
  int get revealedObstacles => _revealed;
  int get deckCount => _deck.length;
  int get draws => _draws;
  PlayingCard? get lastCard => _lastCard;
  Suit? get winner => _winner;
  bool get isFinished => _winner != null;

  /// Palos ordenados de primero a último (empates: orden de la baraja).
  List<Suit> get standings {
    final list = [...Suit.values];
    list.sort((a, b) => _positions[b]!.compareTo(_positions[a]!));
    if (_winner != null) {
      list
        ..remove(_winner)
        ..insert(0, _winner!);
    }
    return list;
  }

  /// Saca una carta y aplica sus efectos. Devuelve los eventos en orden.
  List<RaceEvent> draw() {
    if (isFinished) return const [];
    final events = <RaceEvent>[];

    if (_deck.isEmpty) {
      _deck = [..._discard]..shuffle(_random);
      _discard.clear();
      events.add(const DeckReshuffled());
    }

    final card = _deck.removeLast();
    _discard.add(card);
    _lastCard = card;
    _draws++;
    _positions[card.suit] = _positions[card.suit]! + 1;
    events.add(HorseAdvanced(card));

    if (_positions[card.suit]! >= config.length) {
      _winner = card.suit;
      events.add(HorseWon(card.suit));
      return events;
    }

    while (_revealed < _obstacles.length) {
      final column = _revealed + 1;
      final everyoneThere = _positions.values.every((p) => p >= column);
      if (!everyoneThere) break;
      final obstacle = _obstacles[_revealed];
      _revealed++;
      _positions[obstacle.suit] = max(0, _positions[obstacle.suit]! - 1);
      events.add(ObstacleRevealed(column, obstacle));
    }
    return events;
  }
}
