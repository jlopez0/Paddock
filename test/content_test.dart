import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_module.dart';
import 'package:paddock/games/registry.dart';

void main() {
  final decks = gameModules.whereType<PromptDeckModule>().toList();

  test('hay juegos de cartas registrados y los ids de juego son únicos', () {
    expect(decks, isNotEmpty);
    final ids = gameModules.map((g) => g.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  for (final deck in decks) {
    test('contenido válido: ${deck.contentAsset}', () {
      final prompts = parsePrompts(File(deck.contentAsset).readAsStringSync());
      expect(prompts, isNotEmpty);

      final ids = prompts.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids duplicados');

      for (final level in PromptLevel.values) {
        expect(prompts.where((p) => p.level == level), isNotEmpty, reason: 'sin cartas de ${level.name}');
      }

      final required = switch (deck.style) {
        PromptCardStyle.statement => ['texto'],
        PromptCardStyle.choice => ['a', 'b'],
      };
      for (final p in prompts) {
        for (final f in required) {
          expect(p[f].trim(), isNotEmpty, reason: '${p.id} sin "$f"');
        }
      }
    });
  }
}
