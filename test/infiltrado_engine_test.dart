import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/games/infiltrado/domain/infiltrado_engine.dart';

void main() {
  const four = ['ana', 'beto', 'carla', 'dani'];
  const five = ['ana', 'beto', 'carla', 'dani', 'eva'];

  InfiltradoDeal dealWith(
    List<String> players, {
    int impostors = 1,
    int seed = 1,
  }) => InfiltradoEngine.deal(
    players: players,
    word: 'Paella',
    category: 'Comida',
    impostors: impostors,
    random: Random(seed),
  );

  Map<String, String> everyoneVotes(
    InfiltradoDeal d,
    String target, {
    String? targetVotes,
  }) => {
    for (final p in d.players)
      p: p == target
          ? (targetVotes ?? d.players.firstWhere((x) => x != p))
          : target,
  };

  group('reparto', () {
    test('mismo seed, mismo reparto', () {
      expect(
        dealWith(four, seed: 7).impostors,
        dealWith(four, seed: 7).impostors,
      );
    });

    test('distintas semillas pueden dar distintos infiltrados', () {
      final seen = {
        for (var s = 0; s < 30; s++) dealWith(four, seed: s).impostors.first,
      };
      expect(seen.length, greaterThan(1));
    });

    test('1 infiltrado: los demás son civiles', () {
      final d = dealWith(four);
      expect(d.impostors.length, 1);
      expect(d.civils.length, 3);
      expect(d.players, four);
    });

    test('2 infiltrados con 5 jugadores', () {
      final d = dealWith(five, impostors: 2);
      expect(d.impostors.length, 2);
      expect(d.civils.length, 3);
    });

    test('el infiltrado solo ve la categoría; el civil, la palabra', () {
      final d = dealWith(four);
      final imp = d.cardFor(d.impostors.first);
      expect(imp.isImpostor, isTrue);
      expect(imp.word, isNull);
      expect(imp.category, 'Comida');
      final civ = d.cardFor(d.civils.first);
      expect(civ.isImpostor, isFalse);
      expect(civ.word, 'Paella');
    });

    test('mínimo de 3 jugadores', () {
      expect(() => dealWith(['a', 'b']), throwsArgumentError);
      expect(dealWith(['a', 'b', 'c']).players.length, 3);
      expect(InfiltradoEngine.maxImpostors(2), 0);
      expect(InfiltradoEngine.maxImpostors(4), 1);
      expect(InfiltradoEngine.maxImpostors(5), 2);
    });

    test('rechaza 2 infiltrados con pocos jugadores, 0 o 3', () {
      expect(() => dealWith(four, impostors: 2), throwsArgumentError);
      expect(() => dealWith(five, impostors: 0), throwsArgumentError);
      expect(() => dealWith(five, impostors: 3), throwsArgumentError);
    });

    test('rechaza ids repetidos y textos vacíos', () {
      expect(() => dealWith(['a', 'a', 'b']), throwsArgumentError);
      expect(
        () => InfiltradoEngine.deal(players: four, word: ' ', category: 'x'),
        throwsArgumentError,
      );
    });
  });

  group('votación', () {
    test('mayoría clara: acusado directo', () {
      final d = dealWith(four);
      final imp = d.impostors.first;
      final round = InfiltradoRound(d);
      final r = round.vote(everyoneVotes(d, imp));
      expect(r.accused, imp);
      expect(r.needsRunoff, isFalse);
      expect(r.tally[imp], 3);
      expect(round.isVoteClosed, isTrue);
    });

    test('empate: segunda ronda solo entre los empatados', () {
      final d = dealWith(four);
      final round = InfiltradoRound(d);
      final r = round.vote({
        'ana': 'beto',
        'beto': 'ana',
        'carla': 'beto',
        'dani': 'ana',
      });
      expect(r.needsRunoff, isTrue);
      expect(r.accused, isNull);
      expect(r.leaders, ['ana', 'beto']);
      expect(round.runoffCandidates, {'ana', 'beto'});
      expect(round.isVoteClosed, isFalse);

      // En la segunda ronda no se puede votar a quien no empató.
      expect(
        () => round.vote({
          'ana': 'beto',
          'beto': 'ana',
          'carla': 'dani',
          'dani': 'ana',
        }),
        throwsArgumentError,
      );

      final r2 = round.vote({
        'ana': 'beto',
        'beto': 'ana',
        'carla': 'beto',
        'dani': 'beto',
      });
      expect(r2.accused, 'beto');
      expect(round.isVoteClosed, isTrue);
    });

    test('segundo empate: nadie acusado y el infiltrado se salva', () {
      final d = dealWith(four);
      final round = InfiltradoRound(d);
      final tie = {
        'ana': 'beto',
        'beto': 'ana',
        'carla': 'beto',
        'dani': 'ana',
      };
      round.vote(tie);
      final r2 = round.vote(tie);
      expect(r2.accused, isNull);
      expect(r2.needsRunoff, isFalse);
      final out = round.resolve();
      expect(out.caught, isFalse);
      expect(out.impostorsWin, isTrue);
    });

    test('voto inválido: autovoto, faltan votantes, objetivo desconocido', () {
      final d = dealWith(four);
      expect(
        () => InfiltradoRound(
          d,
        ).vote({'ana': 'ana', 'beto': 'ana', 'carla': 'ana', 'dani': 'ana'}),
        throwsArgumentError,
      );
      expect(
        () => InfiltradoRound(d).vote({'ana': 'beto'}),
        throwsArgumentError,
      );
      expect(
        () => InfiltradoRound(
          d,
        ).vote({'ana': 'zoe', 'beto': 'ana', 'carla': 'ana', 'dani': 'ana'}),
        throwsArgumentError,
      );
    });

    test('no se puede votar ni resolver en mal estado', () {
      final d = dealWith(four);
      final round = InfiltradoRound(d);
      expect(round.resolve, throwsStateError);
      round.vote(everyoneVotes(d, d.impostors.first));
      expect(
        () => round.vote(everyoneVotes(d, d.impostors.first)),
        throwsStateError,
      );
    });
  });

  group('resultado y fichas', () {
    test('se pilla al infiltrado: pierde 2 y los demás 0', () {
      final d = dealWith(four);
      final imp = d.impostors.first;
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, imp));
      final out = round.resolve(guess: 'Tortilla');
      expect(out.caught, isTrue);
      expect(out.guessedWord, isFalse);
      expect(out.impostorsWin, isFalse);
      expect(out.deltas[imp], -2);
      for (final c in d.civils) {
        expect(out.deltas[c], 0);
      }
    });

    test('se acusa a un civil: los demás pierden 1, el infiltrado 0', () {
      final d = dealWith(four);
      final civ = d.civils.first;
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, civ));
      final out = round.resolve();
      expect(out.caught, isFalse);
      expect(out.impostorsWin, isTrue);
      expect(out.deltas[d.impostors.first], 0);
      for (final c in d.civils) {
        expect(out.deltas[c], -1);
      }
    });

    test('última oportunidad: si acierta la palabra gana igualmente', () {
      final d = dealWith(four);
      final imp = d.impostors.first;
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, imp));
      final out = round.resolve(guess: '  PAELLA ');
      expect(out.caught, isTrue);
      expect(out.guessedWord, isTrue);
      expect(out.impostorsWin, isTrue);
      expect(out.deltas[imp], 0);
      for (final c in d.civils) {
        expect(out.deltas[c], -1);
      }
    });

    test('la palabra se compara sin tildes ni mayúsculas', () {
      expect(InfiltradoEngine.wordMatches('  CAMION ', 'Camión'), isTrue);
      expect(
        InfiltradoEngine.wordMatches('piña  colada', 'Piña colada'),
        isTrue,
      );
      expect(InfiltradoEngine.wordMatches('pina', 'Piña'), isTrue);
      expect(InfiltradoEngine.wordMatches('pera', 'Piña'), isFalse);
      expect(InfiltradoEngine.wordMatches('', 'Paella'), isFalse);
    });

    test('adivinar sin que lo pillen no cambia nada', () {
      final d = dealWith(four);
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, d.civils.first));
      final out = round.resolve(guess: 'Paella');
      expect(out.guessedWord, isFalse);
      expect(out.impostorsWin, isTrue);
    });

    test('2 infiltrados: pillar a uno hace perder 2 a ambos', () {
      final d = dealWith(five, impostors: 2);
      final caught = d.impostors.first;
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, caught));
      final out = round.resolve();
      expect(out.impostorsWin, isFalse);
      for (final i in d.impostors) {
        expect(out.deltas[i], -2);
      }
      for (final c in d.civils) {
        expect(out.deltas[c], 0);
      }
    });

    test('2 infiltrados: si se salvan, los 3 civiles pierden 1', () {
      final d = dealWith(five, impostors: 2);
      final round = InfiltradoRound(d)..vote(everyoneVotes(d, d.civils.first));
      final out = round.resolve();
      expect(out.deltas.values.where((v) => v == -1).length, 3);
      for (final i in d.impostors) {
        expect(out.deltas[i], 0);
      }
    });
  });
}
