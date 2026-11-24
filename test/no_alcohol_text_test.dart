import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Guardia: la app no debe contener textos de alcohol fuera del modo Sorbos
// (lib/core/consequences/) ni del aviso legal (lib/app/credits_screen.dart).
// "bebé"/"bebés" (niño pequeño) no son alcohol: se excluyen con lookahead preciso.
final _patterns = <RegExp>[
  RegExp(r'\bbeb(?!és?(?![a-zA-ZáéíóúñÁÉÍÓÚÑ]))', caseSensitive: false),
  RegExp(r'\btrago', caseSensitive: false),
  RegExp('🍺'),
  RegExp(r'\bborrach', caseSensitive: false),
];

// Solo lib/: en JSON "Hidalgo" es un estado de México (Geografía), legítimo.
final _libOnlyPatterns = <RegExp>[
  RegExp(r'\bhidalgo', caseSensitive: false),
];

// Patrones adicionales solo para assets/content/es/*.json.
final _jsonExtraPatterns = <RegExp>[
  RegExp(r'\balcohol', caseSensitive: false),
  RegExp(r'\balcohólic', caseSensitive: false),
  RegExp(r'\bcerveza', caseSensitive: false),
  RegExp(r'\bwhisky', caseSensitive: false),
  RegExp(r'\bvodka', caseSensitive: false),
  RegExp(r'\bginebra', caseSensitive: false),
  RegExp(r'\bborrach', caseSensitive: false),
  RegExp(r'\bresaca', caseSensitive: false),
];

// Frase permitida (aviso de responsabilidad), se elimina de cada línea antes de aplicar los patrones.
final _allowedPhrase = RegExp(r'obligado a beber', caseSensitive: false);

const _excludedPrefixes = <String>[
  'lib/core/consequences/',
];

const _excludedFiles = <String>{
  'lib/app/credits_screen.dart',
};

bool _isExcluded(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (_excludedFiles.contains(normalized)) return true;
  return _excludedPrefixes.any(normalized.startsWith);
}

List<String> _scan(
  Directory root,
  bool Function(String relative) accept,
  List<RegExp> patterns,
) {
  final hits = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File) continue;
    final relative = entity.path.replaceAll('\\', '/');
    if (!accept(relative)) continue;

    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].replaceAll(_allowedPhrase, '');
      for (final pattern in patterns) {
        if (pattern.hasMatch(line)) {
          hits.add('$relative:${i + 1}: ${lines[i].trim()}');
          break;
        }
      }
    }
  }
  return hits;
}

void main() {
  test('lib/ no contiene textos de alcohol fuera de las excepciones', () {
    final root = Directory('lib');
    expect(root.existsSync(), isTrue, reason: 'Ejecutar desde la raíz del paquete');

    final hits = _scan(
      root,
      (relative) => relative.endsWith('.dart') && !_isExcluded(relative),
      [..._patterns, ..._libOnlyPatterns],
    );

    expect(hits, isEmpty,
        reason: 'Textos de alcohol encontrados en lib/:\n${hits.join('\n')}');
  });

  test('assets/content/es/*.json no contiene textos de alcohol', () {
    final root = Directory('assets/content/es');
    expect(root.existsSync(), isTrue, reason: 'Ejecutar desde la raíz del paquete');

    final hits = _scan(
      root,
      (relative) => relative.endsWith('.json'),
      [..._patterns, ..._jsonExtraPatterns],
    );

    expect(hits, isEmpty,
        reason: 'Textos de alcohol encontrados en assets/content/es:\n${hits.join('\n')}');
  });
}
