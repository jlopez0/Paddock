import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/games/game_module.dart';
import 'package:habinson/games/prompt_deck/prompt_deck_module.dart';
import 'package:habinson/games/registry.dart';

/// Guardia de la Copa (opción C, docs/research/ux_previa.md): solo Carrera e Infiltrado
/// anotan en la Copa. Si un juego nuevo quiere sumar, hay que decidirlo a propósito y
/// tocar este test.
class _SinCopa extends GameModule {
  const _SinCopa();

  @override
  String get id => 'sin-copa';
  @override
  String get title => 't';
  @override
  String get subtitle => 's';
  @override
  Color get color => const Color(0xFF000000);
  @override
  Widget buildEntry(BuildContext context) => const SizedBox.shrink();
}

void main() {
  test('GameModule no suma a la Copa salvo que lo diga', () {
    expect(const _SinCopa().scoresCup, isFalse);
  });

  test('los juegos que suman a la Copa son exactamente Carrera e Infiltrado', () {
    final ids = {
      for (final g in gameModules)
        if (g.scoresCup) g.id,
    };
    expect(ids, {'carrera', 'infiltrado'});
  });

  test('ningún mazo de cartas suma a la Copa', () {
    final decks = gameModules.whereType<PromptDeckModule>();
    expect(decks.map((g) => g.id), containsAll(['yo-nunca', 'quien-es-mas-probable']));
    expect(decks.where((g) => g.scoresCup), isEmpty);
  });

  test('solo Carrera e Infiltrado llaman a SessionNotifier.award', () {
    // Los únicos archivos de lib/ que escriben en la Copa. El controlador de la sesión
    // define el método; los otros dos son los resultados de los juegos que suman.
    const allowed = {
      'lib/core/session/session_controller.dart',
      'lib/games/horse_race/ui/race_result_screen.dart',
      'lib/games/infiltrado/infiltrado_store.dart',
    };
    final callers = <String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final text = f.readAsStringSync();
      // `.award(` o `award(` con el notifier; ignora palabras como "reward".
      if (RegExp(r'(^|[^A-Za-z0-9_])award\(').hasMatch(text)) {
        callers.add(f.path.replaceAll('\\', '/'));
      }
    }
    expect(callers, allowed);
  });
}
