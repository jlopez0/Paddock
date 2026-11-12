import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';
import 'player.dart';

/// Lista global de jugadores, compartida por todos los juegos y guardada en el dispositivo.
final playersProvider = NotifierProvider<PlayersController, List<Player>>(PlayersController.new);

class PlayersController extends Notifier<List<Player>> {
  static const _key = 'players.v1';

  @override
  List<Player> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(Player.fromJson).toList(growable: false);
  }

  Player? byId(String id) {
    for (final p in state) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Añade un jugador. Devuelve el existente si ya hay uno con ese nombre.
  Player add(String rawName) {
    final name = rawName.trim();
    for (final p in state) {
      if (p.name.toLowerCase() == name.toLowerCase()) return p;
    }
    final used = state.map((p) => p.colorIndex).toSet();
    var color = 0;
    while (used.contains(color) && color < playerPalette.length) {
      color++;
    }
    final player = Player(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name,
      colorIndex: color % playerPalette.length,
    );
    _save([...state, player]);
    return player;
  }

  void rename(String id, String name) =>
      _save([for (final p in state) p.id == id ? p.copyWith(name: name.trim()) : p]);

  void remove(String id) => _save(state.where((p) => p.id != id).toList());

  void _save(List<Player> players) {
    state = List.unmodifiable(players);
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(players.map((p) => p.toJson()).toList()));
  }
}
