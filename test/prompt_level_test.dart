import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/core/content/prompts.dart';

void main() {
  test(
    'PromptLevel.tryParse migra "hot" y no lanza con valores desconocidos',
    () {
      expect(PromptLevel.tryParse('hot'), PromptLevel.atrevido);
      expect(PromptLevel.tryParse('atrevido'), PromptLevel.atrevido);
      expect(PromptLevel.tryParse('suave'), PromptLevel.suave);
      expect(PromptLevel.tryParse('xyz'), isNull);
      expect(PromptLevel.tryParse(null), isNull);
    },
  );

  test('mazos, Abecedario y prompts.dart no contienen emoji', () {
    final emoji = RegExp(
      '[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}\u{FE0F}\u{200D}]',
      unicode: true,
    );
    final files = [
      File('lib/core/content/prompts.dart'),
      for (final dir in ['lib/games/prompt_deck', 'lib/games/abecedario'])
        ...Directory(dir)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')),
    ];
    expect(files.length, greaterThan(5));
    for (final f in files) {
      expect(emoji.hasMatch(f.readAsStringSync()), isFalse, reason: f.path);
    }
  });

  test(
    'PromptLevel expone id y etiqueta (sin emoji) y coincide con LevelIcon',
    () {
      expect(PromptLevel.values.map((l) => l.id).toList(), LevelIcon.ids);
      expect(PromptLevel.values.map((l) => l.label).toList(), [
        'Suave',
        'Picante',
        'Atrevido',
      ]);
      for (final l in PromptLevel.values) {
        expect(l.id, l.name);
        expect(PromptLevel.tryParse(l.id), l);
      }
    },
  );
}
