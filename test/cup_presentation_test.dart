import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/session/cup_presentation.dart';
import 'package:paddock/core/session/session_score.dart';

void main() {
  test('groupStandings agrupa empates por puesto', () {
    final s = Session.empty(DateTime(2026, 11, 24)).withRound(
      roundId: 'r',
      gameId: 'g',
      deltas: {'a': 3, 'b': 3, 'c': 1, 'd': -2},
      at: DateTime(2026, 11, 24),
    );
    final g = groupStandings(s.standings);
    expect(g.map((e) => e.rank), [1, 3, 4]);
    expect(g.first.playerIds, ['a', 'b']);
    expect(g.first.isTie, isTrue);
    expect(g[1].isTie, isFalse);
  });

  test('joinNames y ordinal', () {
    expect(joinNames([]), '');
    expect(joinNames(['Ana']), 'Ana');
    expect(joinNames(['Ana', 'Luis']), 'Ana y Luis');
    expect(joinNames(['Ana', 'Luis', 'Eva']), 'Ana, Luis y Eva');
    expect(ordinal(2), '2.º');
  });
}
