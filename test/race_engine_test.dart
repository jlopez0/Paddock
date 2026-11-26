import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/games/horse_race/domain/bets.dart';
import 'package:habinson/games/horse_race/domain/cards.dart';
import 'package:habinson/games/horse_race/domain/race_engine.dart';

void main() {
  group('RaceEngine', () {
    test('reparte 44 cartas sin caballos entre obstáculos y mazo', () {
      final e = RaceEngine(random: Random(1));
      expect(e.obstacles.length, 5);
      expect(e.deckCount, 39);
      final all = {...e.obstacles};
      expect(all.any((c) => c.rank == PlayingCard.horseRank), isFalse);
      expect(e.positions.values, everyElement(0));
    });

    test('cada carta avanza a su palo y el primero en la meta gana', () {
      for (var seed = 0; seed < 200; seed++) {
        final e = RaceEngine(random: Random(seed));
        var guard = 0;
        while (!e.isFinished && guard++ < 500) {
          final before = e.positions;
          final events = e.draw();
          final adv = events.whereType<HorseAdvanced>().single;
          final revealed = events.whereType<ObstacleRevealed>().toList();
          final after = e.positions;
          for (final s in Suit.values) {
            final delta = (s == adv.card.suit ? 1 : 0) -
                revealed.where((o) => o.card.suit == s).length;
            final expected = before[s]! + delta;
            // Un obstáculo nunca deja a un caballo por debajo de la salida.
            expect(after[s], expected < 0 ? 0 : expected, reason: 'seed $seed');
          }
        }
        expect(e.isFinished, isTrue, reason: 'seed $seed');
        expect(e.positions[e.winner]!, 6);
        expect(e.standings.first, e.winner);
        expect(e.positions.values.where((p) => p >= 6).length, 1);
      }
    });

    test('el obstáculo k solo se descubre cuando todos han llegado a k', () {
      for (var seed = 0; seed < 200; seed++) {
        final e = RaceEngine(random: Random(seed));
        while (!e.isFinished) {
          final minBefore = e.positions.values.reduce(min);
          final adv = e.draw();
          for (final o in adv.whereType<ObstacleRevealed>()) {
            // Tras el avance, todos estaban como mínimo en la casilla k.
            expect(o.column, lessThanOrEqualTo(minBefore + 1));
          }
        }
        expect(e.revealedObstacles, lessThanOrEqualTo(5));
      }
    });

    test('sin obstáculos no se descubre nada y la pista es configurable', () {
      final e = RaceEngine(config: const RaceConfig(length: 4, obstacles: false), random: Random(3));
      expect(e.obstacles, isEmpty);
      expect(e.deckCount, 44);
      while (!e.isFinished) {
        expect(e.draw().whereType<ObstacleRevealed>(), isEmpty);
      }
      expect(e.positions[e.winner]!, 4);
    });

    test('si se agota el mazo se rebaraja el descarte', () {
      // Pista de 9 con 8 obstáculos: el mazo (36) puede agotarse antes de que haya ganador.
      var reshuffles = 0;
      for (var seed = 0; seed < 3000; seed++) {
        final e = RaceEngine(config: const RaceConfig(length: 9), random: Random(seed));
        while (!e.isFinished) {
          final deckBefore = e.deckCount;
          final discardBefore = e.draws;
          final events = e.draw();
          if (events.any((ev) => ev is DeckReshuffled)) {
            reshuffles++;
            expect(deckBefore, 0);
            // Todo el descarte vuelve al mazo, menos la carta recién sacada.
            expect(e.deckCount, discardBefore - 1);
          }
        }
      }
      expect(reshuffles, greaterThan(0));
    });

    test('draw() tras terminar no hace nada', () {
      final e = RaceEngine(random: Random(9));
      while (!e.isFinished) {
        e.draw();
      }
      final draws = e.draws;
      expect(e.draw(), isEmpty);
      expect(e.draws, draws);
    });
  });

  test('settleBets: aciertos reparten (con multiplicador), fallos pierden', () {
    const bets = [
      Bet(playerId: 'a', suit: Suit.copas, chips: 3),
      Bet(playerId: 'b', suit: Suit.oros, chips: 5),
    ];
    final r = settleBets(bets, Suit.copas, winMultiplier: 2);
    expect(r[0].won, isTrue);
    expect(r[0].chips, 6);
    expect(r[0].label, '6 fichas');
    expect(r[1].won, isFalse);
    expect(r[1].chips, 5);
    expect(r[1].chipValue, 5);
  });

  test('settleBets: All-in pierde 1 All-in y, si gana, reparte 2 (con o sin multiplicador)', () {
    const bets = [
      Bet(playerId: 'a', suit: Suit.copas, chips: Bet.allIn),
      Bet(playerId: 'b', suit: Suit.oros, chips: Bet.allIn),
    ];
    for (final mult in [1, 2]) {
      final r = settleBets(bets, Suit.copas, winMultiplier: mult);
      expect([r[0].won, r[0].allIns, r[0].label], [true, 2, 'All-in ×2']);
      expect([r[1].won, r[1].allIns, r[1].label], [false, 1, 'All-in']);
      expect(r[1].chipValue, kAllInChips);
    }
  });
}

