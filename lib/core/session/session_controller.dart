import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';
import 'session_score.dart';

/// Reloj inyectable (los tests lo sustituyen).
final sessionClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// La Copa de la noche: eventos de puntuación de todos los juegos, guardados en el dispositivo.
final sessionProvider = NotifierProvider<SessionScoreController, Session>(
  SessionScoreController.new,
);

class SessionScoreController extends Notifier<Session> {
  static const _key = 'session.v1';

  DateTime _now() => ref.read(sessionClockProvider)();

  @override
  Session build() => Session.decode(
    ref.read(sharedPreferencesProvider).getString(_key),
    _now(),
  );

  /// `true` si la noche tiene más de 12 h (la home ofrece "Nueva noche").
  bool get isStale => state.isStale(_now());

  /// Registra una ronda: `deltas` es jugador -> fichas (positivas o negativas).
  /// No hace nada si `roundId` ya está registrado. Devuelve `true` si se registró.
  bool award(String roundId, String gameId, Map<String, int> deltas) {
    final next = state.withRound(
      roundId: roundId,
      gameId: gameId,
      deltas: deltas,
      at: _now(),
    );
    if (identical(next, state)) return false;
    _save(next);
    return true;
  }

  /// Quita la última ronda registrada. Devuelve su `roundId`, o `null` si no había ninguna.
  String? undoLastRound() {
    if (state.isEmpty) return null;
    final last = state.events.last.roundId;
    _save(state.withoutLastRound());
    return last;
  }

  /// Empieza una noche nueva y borra lo guardado.
  void newNight() {
    state = Session.empty(_now());
    ref.read(sharedPreferencesProvider).remove(_key);
  }

  void _save(Session session) {
    state = session;
    ref.read(sharedPreferencesProvider).setString(_key, session.encode());
  }
}
