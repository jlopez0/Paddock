import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/players/players_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container() async {
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('añade, evita duplicados y persiste entre instancias', () async {
    final c1 = await _container();
    final ana = c1.read(playersProvider.notifier).add(' Ana ');
    c1.read(playersProvider.notifier).add('luis');
    final dup = c1.read(playersProvider.notifier).add('ANA');
    expect(dup.id, ana.id);
    expect(c1.read(playersProvider).map((p) => p.name), ['Ana', 'luis']);
    expect(c1.read(playersProvider).map((p) => p.colorIndex).toSet().length, 2);

    final c2 = await _container();
    expect(c2.read(playersProvider).map((p) => p.name), ['Ana', 'luis']);
  });

  test('50 altas seguidas generan ids únicos', () async {
    final c = await _container();
    final n = c.read(playersProvider.notifier);
    for (var i = 0; i < 50; i++) {
      n.add('Jugador $i');
    }
    final ids = c.read(playersProvider).map((p) => p.id).toList();
    expect(ids.length, 50);
    expect(ids.toSet().length, 50);
  });

  test('renombra y elimina', () async {
    final c = await _container();
    final n = c.read(playersProvider.notifier);
    final p = n.add('Pepe');
    n.rename(p.id, 'José');
    expect(c.read(playersProvider).single.name, 'José');
    n.remove(p.id);
    expect(c.read(playersProvider), isEmpty);
  });
}
