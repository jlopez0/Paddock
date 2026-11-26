import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/content/prompts.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_logic.dart';

List<Prompt> _cards(int n, {PromptLevel level = PromptLevel.suave}) => [
  for (var i = 0; i < n; i++)
    Prompt(id: 'c$i', level: level, fields: {'texto': 't$i'}),
];

void main() {
  group('drawDeck', () {
    test('una partida tiene como mucho `rounds` cartas, sin repetir', () {
      final r = drawDeck(
        all: _cards(40),
        levels: {PromptLevel.suave},
        played: const {},
        rounds: 15,
        random: Random(1),
      );
      expect(r.cards.length, 15);
      expect(r.cards.map((c) => c.id).toSet().length, 15);
    });

    test('solo entran cartas de los niveles elegidos', () {
      final all = [
        ..._cards(10),
        for (var i = 0; i < 10; i++)
          Prompt(
            id: 'p$i',
            level: PromptLevel.picante,
            fields: const {'texto': 'x'},
          ),
      ];
      final r = drawDeck(
        all: all,
        levels: {PromptLevel.picante},
        played: const {},
        rounds: 5,
        random: Random(2),
      );
      expect(r.cards.every((c) => c.level == PromptLevel.picante), isTrue);
    });

    test('la partida siguiente evita las cartas ya jugadas', () {
      final all = _cards(40);
      final first = drawDeck(
        all: all,
        levels: {PromptLevel.suave},
        played: const {},
        rounds: 15,
        random: Random(3),
      );
      final second = drawDeck(
        all: all,
        levels: {PromptLevel.suave},
        played: first.played,
        rounds: 15,
        random: Random(4),
      );
      final firstIds = first.cards.map((c) => c.id).toSet();
      expect(second.cards.any((c) => firstIds.contains(c.id)), isFalse);
      expect(second.played.length, 30);
    });

    test('si quedan menos sin jugar que `rounds`, se vuelve a barajar todo', () {
      final all = _cards(20);
      final r = drawDeck(
        all: all,
        levels: {PromptLevel.suave},
        played: {for (var i = 0; i < 10; i++) 'c$i'},
        rounds: 15,
        random: Random(5),
      );
      expect(r.cards.length, 15);
      // El historial empieza de cero con esta partida.
      expect(r.played, r.cards.map((c) => c.id).toSet());
    });

    test('con menos cartas que `rounds`, se juegan todas las que haya', () {
      final r = drawDeck(
        all: _cards(4),
        levels: {PromptLevel.suave},
        played: const {},
        rounds: 15,
        random: Random(6),
      );
      expect(r.cards.length, 4);
    });

    test('sin cartas en los niveles elegidos, la partida está vacía', () {
      final r = drawDeck(
        all: _cards(4),
        levels: {PromptLevel.atrevido},
        played: const {},
        rounds: 15,
        random: Random(7),
      );
      expect(r.cards, isEmpty);
    });
  });

  group('rollStakes', () {
    test('una apuesta por carta, entre 1 y el tope de la ronda', () {
      final s = rollStakes(200, Random(8));
      expect(s.length, 200);
      expect(s.every((v) => v >= 1 && v <= kRoundCap), isTrue);
      // Con 200 tiradas salen todos los valores posibles.
      expect(s.toSet(), {for (var v = 1; v <= kRoundCap; v++) v});
    });
  });

  group('stakeHeadline', () {
    test('Fichas: no hay titular de apuesta', () {
      for (final n in [1, 2, 3]) {
        expect(stakeHeadline(n, ConsequenceMode.puntos), isNull);
      }
    });

    test('Retos: "¡Por un reto!" sea cual sea la intensidad', () {
      for (final n in [1, 2, 3, 9]) {
        expect(stakeHeadline(n, ConsequenceMode.retos), '¡Por un reto!');
      }
      expect(stakeHeadline(0, ConsequenceMode.retos), isNull);
    });

    test('Sorbos: sin exclamación, con agua o reto y con tope de 3', () {
      expect(stakeHeadline(1, ConsequenceMode.sorbos), 'Por 1 sorbo · o agua o reto');
      expect(stakeHeadline(2, ConsequenceMode.sorbos), 'Por 2 sorbos · o agua o reto');
      expect(stakeHeadline(9, ConsequenceMode.sorbos), 'Por 3 sorbos · o agua o reto');
    });
  });
}
