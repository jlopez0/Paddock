import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Identidad visual: nada de emoji ni iconos de Material en `lib/`.
///
/// Excepcion documentada de emoji: la constante `kShareTrophy` de
/// `lib/app/cup_screen.dart` (texto que se comparte fuera de la app).
///
/// Excepciones de `Icons.` de Material: ninguna por ahora. Si hiciera falta
/// un widget de plataforma, anadir aqui su ruta con el motivo.
const _iconsExceptions = <String, String>{};

bool _isEmoji(int c) =>
    (c >= 0x1F300 && c <= 0x1FAFF) ||
    (c >= 0x2600 && c <= 0x27BF) ||
    c == 0x2B50 ||
    (c >= 0x1F1E6 && c <= 0x1F1FF);

String _rel(File f) => f.path.replaceAll(r'\', '/');

void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('lib/ no contiene emoji (salvo kShareTrophy)', () {
    final found = <String>[];
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (_rel(f).endsWith('lib/app/cup_screen.dart') &&
            line.startsWith('const kShareTrophy')) {
          continue;
        }
        if (line.runes.any(_isEmoji)) {
          found.add('${_rel(f)}:${i + 1}');
        }
      }
    }
    expect(found, isEmpty, reason: 'Emoji en: ${found.join(', ')}');
  });

  test('lib/ no usa Icons. de Material', () {
    final re = RegExp(r'\bIcons\.');
    final found = <String>[];
    for (final f in files) {
      if (_iconsExceptions.keys.any(_rel(f).endsWith)) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (re.hasMatch(lines[i])) found.add('${_rel(f)}:${i + 1}');
      }
    }
    expect(found, isEmpty, reason: 'Icons. en: ${found.join(', ')}');
  });
}
