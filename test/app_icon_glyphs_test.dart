import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/app/app_icons.dart';

/// Lee la tabla `cmap` (formatos 4 y 12) de un TTF y devuelve los codigos.
Set<int> _cmapCodes(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  final numTables = d.getUint16(4);
  var cmapOff = -1;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + i * 16;
    final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'cmap') cmapOff = d.getUint32(rec + 8);
  }
  expect(cmapOff, greaterThan(0), reason: 'sin tabla cmap');
  final n = d.getUint16(cmapOff + 2);
  final codes = <int>{};
  for (var i = 0; i < n; i++) {
    final sub = cmapOff + d.getUint32(cmapOff + 4 + i * 8 + 4);
    final format = d.getUint16(sub);
    if (format == 12) {
      final groups = d.getUint32(sub + 12);
      for (var g = 0; g < groups; g++) {
        final o = sub + 16 + g * 12;
        final start = d.getUint32(o);
        final end = d.getUint32(o + 4);
        for (var c = start; c <= end; c++) {
          codes.add(c);
        }
      }
    } else if (format == 4) {
      final segX2 = d.getUint16(sub + 6);
      final endO = sub + 14;
      final startO = endO + segX2 + 2;
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(endO + s * 2);
        final start = d.getUint16(startO + s * 2);
        if (start == 0xFFFF) continue;
        for (var c = start; c <= end; c++) {
          codes.add(c);
        }
      }
    }
  }
  return codes;
}

void main() {
  test('cada glifo de AppIcon existe en Phosphor-Duotone.ttf', () {
    final codes = _cmapCodes(File('assets/fonts/Phosphor-Duotone.ttf').readAsBytesSync());
    expect(codes, isNotEmpty);
    for (final i in AppIcon.values) {
      for (final c in i.codePoints) {
        expect(codes.contains(c), isTrue, reason: '${i.name}: U+${c.toRadixString(16)}');
      }
    }
  });
}
