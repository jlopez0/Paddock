import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:habinson/app/app_icons.dart';
import 'package:habinson/app/theme.dart';

/// Hoja de contacto de todos los iconos (revision visual). Escribe un PNG en
/// el directorio indicado por PADDOCK_ICON_SHEET_DIR, si existe la variable.
void main() {
  testWidgets('hoja de contacto de iconos', (tester) async {
    for (final f in {
      'PhosphorDuotone': 'assets/fonts/Phosphor-Duotone.ttf',
      'PhosphorFill': 'assets/fonts/Phosphor-Fill.ttf',
      'Figtree': 'assets/fonts/Figtree[wght].ttf',
      'AlfaSlabOne': 'assets/fonts/AlfaSlabOne-Regular.ttf',
    }.entries) {
      final loader = FontLoader(f.key)
        ..addFont(
          Future.value(ByteData.sublistView(File(f.value).readAsBytesSync())),
        );
      await tester.runAsync(loader.load);
    }
    await tester.pump();

    final cells = <(String, Widget)>[
      for (final i in AppIcon.values) ('AppIcon.${i.name}', i.widget(size: 96)),
      for (final k in GameIconKind.values)
        ('game.${k.id}', GameIcon.kind(k, size: 96)),
      for (final c in [...CategoryIcon.triviaIds, ...CategoryIcon.geoIds])
        ('cat.$c', CategoryIcon(c, size: 96)),
      for (final l in LevelIcon.ids) ('level.$l', LevelIcon(l, size: 96)),
    ];

    final key = GlobalKey();
    tester.view.physicalSize = const Size(1500, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(12),
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (name, w) in cells)
                  SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        w,
                        const SizedBox(height: 4),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Figtree',
                            fontSize: 12,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpAndSettle();
    final dir = Platform.environment['PADDOCK_ICON_SHEET_DIR'];
    if (dir == null) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(dir).createSync(recursive: true);
      File('$dir/contacto.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
    await tester.pumpAndSettle();
  });
}
