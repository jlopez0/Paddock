import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/app/theme.dart';

double _lum(Color c) {
  double f(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  test('brassText y textMuted cumplen 4.5:1 sobre los fondos', () {
    for (final bg in [
      AppColors.background,
      AppColors.surface,
      AppColors.surfaceHigh,
    ]) {
      expect(contrast(AppColors.brassText, bg), greaterThanOrEqualTo(4.5));
      expect(contrast(AppColors.textMuted, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('titulos de AppBar: Alfa Slab One >= 20 px, centrados', () {
    final t = buildAppTheme().appBarTheme;
    expect(t.centerTitle, isTrue);
    expect(t.titleTextStyle!.fontFamily, AppFonts.display);
    expect(t.titleTextStyle!.fontSize, greaterThanOrEqualTo(kDisplayMinSize));
  });

  test('escala de titulos limitada a 1.3', () {
    expect(clampedTitleScaler(const TextScaler.linear(2)).scale(10), 13);
  });

  testWidgets('AppTitle limita la escala a 1.3 con textScaler 2.0', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AppTitle('Ajustes'),
        ),
      ),
    );
    final t = tester.widget<Text>(find.text('Ajustes'));
    expect(t.textScaler!.scale(10), 13);
  });

  test('numero 1-8 del menu (brassText) legible sobre sus fondos', () {
    for (final bg in [AppColors.surface, AppColors.surfaceHigh]) {
      expect(contrast(AppColors.brassText, bg), greaterThanOrEqualTo(4.5));
    }
  });
}
