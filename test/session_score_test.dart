import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/session/session_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

var _now = DateTime(2026, 11, 24, 22);

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    sessionClockProvider.overrideWithValue(() => _now),
  ]);
}

void main() {
  setUp(() {
    _now = DateTime(2026, 11, 24, 22);
    SharedPreferences.setMockInitialValues({});
  });

  test('clasificación con empates comparte puesto', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    n.award('r1', 'carrera', {'ana': 3, 'luis': 3, 'eva': -2, 'pepe': 1});
    n.award('r2', 'trivia', {'pepe': 2, 'eva': 0});
    final s = c.read(sessionProvider).standings;
    expect(s.map((e) => e.playerId), ['ana', 'luis', 'pepe', 'eva']);
    expect(s.map((e) => e.total), [3, 3, 3, -2]);
    expect(s.map((e) => e.rank), [1, 1, 1, 4]);
  });

  test('un mismo roundId no se cuenta dos veces', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    expect(n.award('r1', 'carrera', {'ana': 2}), isTrue);
    expect(n.award('r1', 'carrera', {'ana': 2, 'luis': 5}), isFalse);
    expect(c.read(sessionProvider).events, hasLength(1));
    expect(c.read(sessionProvider).standings.single.total, 2);
  });

  test('rondas vacías o con deltas a cero no registran nada', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    expect(n.award('r1', 'carrera', {}), isFalse);
    expect(n.award('r2', 'carrera', {'ana': 0}), isFalse);
    expect(c.read(sessionProvider).isEmpty, isTrue);
    // y el id sigue libre
    expect(n.award('r1', 'carrera', {'ana': 1}), isTrue);
  });

  test('deshacer quita solo la última ronda', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    expect(n.undoLastRound(), isNull);
    n.award('r1', 'carrera', {'ana': 2, 'luis': -2});
    n.award('r2', 'carrera', {'ana': 1, 'luis': -1});
    expect(n.undoLastRound(), 'r2');
    expect(c.read(sessionProvider).roundIds, ['r1']);
    expect(c.read(sessionProvider).standings.first.total, 2);
    // la ronda deshecha se puede volver a registrar
    expect(n.award('r2', 'carrera', {'ana': 1}), isTrue);
  });

  test('estadísticas por juego y quien más ha perdido', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    n.award('r1', 'carrera', {'ana': 3, 'luis': -2});
    n.award('r2', 'carrera', {'ana': -1, 'luis': 2});
    n.award('r3', 'trivia', {'eva': -4, 'ana': 1});
    final s = c.read(sessionProvider);
    final stats = s.statsByGame;
    expect(stats.map((g) => g.gameId), ['carrera', 'trivia']);
    expect(stats.first.rounds, 2);
    expect(stats.first.standings.map((e) => e.playerId), ['ana', 'luis']);
    expect(s.biggestLosers, ['eva']);
    c.read(sessionProvider.notifier).undoLastRound();
    expect(c.read(sessionProvider).biggestLosers, ['luis']);
  });

  test('biggestLosers vacío si nadie ha perdido; varios si empatan', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    n.award('r1', 'carrera', {'ana': 3});
    expect(c.read(sessionProvider).biggestLosers, isEmpty);
    n.award('r2', 'carrera', {'ana': -2, 'luis': -2});
    expect(c.read(sessionProvider).biggestLosers.toSet(), {'ana', 'luis'});
  });

  test('guarda y recupera entre instancias', () async {
    final c1 = await _container();
    c1.read(sessionProvider.notifier).award('r1', 'carrera', {'ana': 2, 'luis': -1});
    final id = c1.read(sessionProvider).id;

    final c2 = await _container();
    final s = c2.read(sessionProvider);
    expect(s.id, id);
    expect(s.roundIds, ['r1']);
    expect(s.standings.map((e) => e.total), [2, -1]);
    expect(s.events.first.at, _now);
    // y sigue sin duplicar tras recargar
    expect(c2.read(sessionProvider.notifier).award('r1', 'carrera', {'ana': 9}), isFalse);
  });

  test('JSON corrupto o de otra versión da una sesión vacía', () async {
    for (final raw in [
      'no es json',
      '[]',
      '{"v":1,"id":"x","s":1,"e":[{"r":"a"}]}',
      '{"v":2,"id":"x","s":1,"e":[]}',
      '{"v":1,"id":"x","s":"hoy","e":[]}',
    ]) {
      SharedPreferences.setMockInitialValues({'session.v1': raw});
      final c = await _container();
      final s = c.read(sessionProvider);
      expect(s.isEmpty, isTrue, reason: raw);
      expect(s.startedAt, _now, reason: raw);
      // y se puede seguir jugando
      expect(c.read(sessionProvider.notifier).award('r1', 'carrera', {'ana': 1}), isTrue);
    }
  });

  test('isStale pasadas 12 h, y solo con eventos', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    _now = _now.add(const Duration(hours: 30));
    expect(n.isStale, isFalse, reason: 'noche vacía no es antigua');
    n.award('r1', 'carrera', {'ana': 1});
    expect(n.isStale, isFalse);
    _now = _now.add(const Duration(hours: 12));
    expect(n.isStale, isFalse, reason: 'exactamente 12 h todavía no');
    _now = _now.add(const Duration(minutes: 1));
    expect(n.isStale, isTrue);
    // sobrevive a reiniciar la app
    final c2 = await _container();
    expect(c2.read(sessionProvider.notifier).isStale, isTrue);
  });

  test('newNight vacía todo y borra lo guardado', () async {
    final c = await _container();
    final n = c.read(sessionProvider.notifier);
    n.award('r1', 'carrera', {'ana': 1});
    final oldId = c.read(sessionProvider).id;
    _now = _now.add(const Duration(minutes: 5));
    n.newNight();
    final s = c.read(sessionProvider);
    expect(s.isEmpty, isTrue);
    expect(s.id, isNot(oldId));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('session.v1'), isNull);
    expect(n.award('r1', 'carrera', {'ana': 1}), isTrue);
  });
}
