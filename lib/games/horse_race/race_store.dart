import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import 'domain/bets.dart';
import 'domain/cards.dart';
import 'domain/race_engine.dart';

class RaceSettings {
  const RaceSettings({this.length = 6, this.obstacles = true, this.doubleForWinners = false, this.music = true});

  final int length;
  final bool obstacles;

  /// Si está activo, quien acierta reparte el doble de lo apostado.
  final bool doubleForWinners;

  /// Suena la obertura de Guillermo Tell durante la carrera.
  final bool music;

  RaceConfig get config => RaceConfig(length: length, obstacles: obstacles);
  int get winMultiplier => doubleForWinners ? 2 : 1;

  RaceSettings copyWith({int? length, bool? obstacles, bool? doubleForWinners, bool? music}) => RaceSettings(
        length: length ?? this.length,
        obstacles: obstacles ?? this.obstacles,
        doubleForWinners: doubleForWinners ?? this.doubleForWinners,
        music: music ?? this.music,
      );

  Map<String, dynamic> toJson() =>
      {'length': length, 'obstacles': obstacles, 'double': doubleForWinners, 'music': music};

  factory RaceSettings.fromJson(Map<String, dynamic> j) => RaceSettings(
        length: j['length'] as int? ?? 6,
        obstacles: j['obstacles'] as bool? ?? true,
        doubleForWinners: j['double'] as bool? ?? false,
        music: j['music'] as bool? ?? true,
      );
}

class PlayerRaceStats {
  const PlayerRaceStats({this.races = 0, this.hits = 0, this.sipsDrunk = 0, this.sipsGiven = 0});

  final int races;
  final int hits;
  final int sipsDrunk;
  final int sipsGiven;

  double get hitRate => races == 0 ? 0 : hits / races;

  PlayerRaceStats add(BetOutcome o) => PlayerRaceStats(
        races: races + 1,
        hits: hits + (o.won ? 1 : 0),
        sipsDrunk: sipsDrunk + (o.won ? 0 : o.sips),
        sipsGiven: sipsGiven + (o.won ? o.sips : 0),
      );

  Map<String, dynamic> toJson() => {'r': races, 'h': hits, 'd': sipsDrunk, 'g': sipsGiven};

  factory PlayerRaceStats.fromJson(Map<String, dynamic> j) => PlayerRaceStats(
        races: j['r'] as int,
        hits: j['h'] as int,
        sipsDrunk: j['d'] as int,
        sipsGiven: j['g'] as int,
      );
}

class RaceStats {
  const RaceStats({this.byPlayer = const {}, this.winsBySuit = const {}});

  final Map<String, PlayerRaceStats> byPlayer;
  final Map<Suit, int> winsBySuit;

  int get totalRaces => winsBySuit.values.fold(0, (a, b) => a + b);
}

/// Configuración + apuestas de la carrera en curso. Se guarda para la revancha.
class RaceSetup {
  const RaceSetup({this.settings = const RaceSettings(), this.bets = const []});

  final RaceSettings settings;
  final List<Bet> bets;

  RaceSetup copyWith({RaceSettings? settings, List<Bet>? bets}) =>
      RaceSetup(settings: settings ?? this.settings, bets: bets ?? this.bets);
}

final raceSetupProvider = NotifierProvider<RaceSetupController, RaceSetup>(RaceSetupController.new);

class RaceSetupController extends Notifier<RaceSetup> {
  static const _key = 'race.setup.v1';

  @override
  RaceSetup build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const RaceSetup();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return RaceSetup(
        settings: RaceSettings.fromJson(j['settings'] as Map<String, dynamic>),
        bets: (j['bets'] as List).cast<Map<String, dynamic>>().map(Bet.fromJson).toList(),
      );
    } catch (_) {
      return const RaceSetup();
    }
  }

  void setSettings(RaceSettings s) => _save(state.copyWith(settings: s));

  void setBets(List<Bet> bets) => _save(state.copyWith(bets: List.unmodifiable(bets)));

  void _save(RaceSetup s) {
    state = s;
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode({
            'settings': s.settings.toJson(),
            'bets': s.bets.map((b) => b.toJson()).toList(),
          }),
        );
  }
}

final raceStatsProvider = NotifierProvider<RaceStatsController, RaceStats>(RaceStatsController.new);

class RaceStatsController extends Notifier<RaceStats> {
  static const _key = 'race.stats.v1';

  @override
  RaceStats build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const RaceStats();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return RaceStats(
        byPlayer: (j['players'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PlayerRaceStats.fromJson(v as Map<String, dynamic>)),
        ),
        winsBySuit: (j['suits'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(Suit.values.byName(k), v as int)),
      );
    } catch (_) {
      return const RaceStats();
    }
  }

  void record(Suit winner, List<BetOutcome> outcomes) {
    final players = {...state.byPlayer};
    for (final o in outcomes) {
      players[o.bet.playerId] = (players[o.bet.playerId] ?? const PlayerRaceStats()).add(o);
    }
    final suits = {...state.winsBySuit};
    suits[winner] = (suits[winner] ?? 0) + 1;
    _save(RaceStats(byPlayer: players, winsBySuit: suits));
  }

  void reset() => _save(const RaceStats());

  void _save(RaceStats s) {
    state = s;
    ref.read(sharedPreferencesProvider).setString(
          _key,
          jsonEncode({
            'players': s.byPlayer.map((k, v) => MapEntry(k, v.toJson())),
            'suits': s.winsBySuit.map((k, v) => MapEntry(k.name, v)),
          }),
        );
  }
}
