import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/app/mascot.dart';

const _outDir =
    'C:/Users/javie/AppData/Local/Temp/claude/77e34b3e76a3fc0a/87635144-aee5-44fa-b15f-2fb433bc3c86/scratchpad/mascot';

Future<void> _render(
  WidgetTester tester,
  String name,
  Widget child, {
  Color bg = const Color(0xFF13241B),
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: key,
        child: Container(
          width: 512,
          height: 512,
          color: bg,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    ),
  );
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(_outDir);
    if (dir.existsSync()) {
      File('$_outDir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    }
  });
}

void main() {
  testWidgets('render PNG de las piezas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(512, 512));
    await _render(tester, 'jockey_neutral', const Jockey(size: 480));
    await _render(
      tester,
      'jockey_celebra',
      const Jockey(pose: JockeyPose.celebra, size: 480),
    );
    await _render(
      tester,
      'trofeo',
      const TrophyIllustration(size: 480),
      bg: const Color(0xFF7A2430),
    );
    await _render(
      tester,
      'pequenos',
      const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Jockey(size: 64),
          Jockey(pose: JockeyPose.celebra, size: 128),
          TrophyIllustration(size: 64),
          TrophyIllustration(size: 128),
        ],
      ),
    );
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('se pinta sin excepciones con textScaler 2.0 y varios tamaños', (
    tester,
  ) async {
    for (final s in [16.0, 64.0, 128.0, 256.0]) {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(
              children: [
                Jockey(size: s),
                Jockey(pose: JockeyPose.celebra, size: s),
                TrophyIllustration(size: s),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Jockey).first), Size(s, s));
    }
  });
}
