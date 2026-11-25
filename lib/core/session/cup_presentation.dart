import 'session_score.dart';

/// Jugadores que comparten puesto en la clasificación (un empate si hay más de uno).
class RankGroup {
  const RankGroup({
    required this.rank,
    required this.total,
    required this.playerIds,
  });

  final int rank;
  final int total;
  final List<String> playerIds;

  bool get isTie => playerIds.length > 1;
}

/// Agrupa la clasificación por puesto, en el mismo orden. Presentación pura:
/// no toca el formato `session.v1`.
List<RankGroup> groupStandings(List<Standing> standings) {
  final groups = <RankGroup>[];
  for (final s in standings) {
    if (groups.isNotEmpty && groups.last.rank == s.rank) {
      final last = groups.removeLast();
      groups.add(
        RankGroup(
          rank: last.rank,
          total: last.total,
          playerIds: [...last.playerIds, s.playerId],
        ),
      );
    } else {
      groups.add(
        RankGroup(rank: s.rank, total: s.total, playerIds: [s.playerId]),
      );
    }
  }
  return groups;
}

/// `1.º`, `2.º`...
String ordinal(int rank) => '$rank.º';

/// `Ana`, `Ana y Luis`, `Ana, Luis y Eva`.
String joinNames(List<String> names) {
  if (names.length < 2) return names.join();
  return '${names.sublist(0, names.length - 1).join(', ')} y ${names.last}';
}
