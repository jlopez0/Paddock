// Genera los PNG del icono y el splash de Paddock.
// Uso: flutter test tools/gen_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _bg = ui.Color(0xFF0B1611);
const _gold = ui.Color(0xFFE8B84A);
const _size = 1024.0;

/// Letra P geometrica, centrada, dentro de la zona segura (66%).
ui.Path _letterP() {
  const w = 400.0, h = 520.0;
  const x0 = (_size - w) / 2, y0 = (_size - h) / 2;
  final stem = ui.Path()
    ..addRRect(ui.RRect.fromLTRBR(
        x0, y0, x0 + 130, y0 + h, const ui.Radius.circular(24)));
  final bowl = ui.Path()
    ..addRRect(ui.RRect.fromLTRBR(
        x0, y0, x0 + w, y0 + 320, const ui.Radius.circular(160)));
  final hole = ui.Path()
    ..addRRect(ui.RRect.fromLTRBR(
        x0 + 130, y0 + 100, x0 + w - 100, y0 + 220, const ui.Radius.circular(60)));
  final solid = ui.Path.combine(ui.PathOperation.union, stem, bowl);
  return ui.Path.combine(ui.PathOperation.difference, solid, hole);
}

Future<void> _render(String path, {required bool background}) async {
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  if (background) {
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, _size, _size),
        ui.Paint()..color = _bg);
  }
  canvas.drawPath(_letterP(), ui.Paint()..color = _gold..isAntiAlias = true);
  final img = await rec.endRecording().toImage(_size.toInt(), _size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('genera iconos', (tester) async {
    await tester.runAsync(() async {
      await _render('assets/icon/icon.png', background: true);
      await _render('assets/icon/icon_foreground.png', background: false);
      await _render('assets/icon/splash.png', background: false);
    });
  });
}
