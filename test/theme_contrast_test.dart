import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/app/theme.dart';
import 'package:paddock/games/infiltrado/ui/infiltrado_widgets.dart';
import 'package:paddock/games/prompt_deck/game_colors.dart';

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

  test('texto sobre el panel burdeos de la Copa (gold, paper) >= 4.5:1', () {
    expect(
      contrast(AppColors.gold, AppColors.burgundy),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.paper, AppColors.burgundy),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('infiltradoText y mutedText sobre las superficies oscuras', () {
    for (final bg in [
      AppColors.background,
      AppColors.surface,
      AppColors.surfaceHigh,
      AppColors.outline,
    ]) {
      expect(
        contrast(GameColors.infiltradoText, bg),
        greaterThanOrEqualTo(4.5),
      );
      expect(contrast(GameColors.mutedText, bg), greaterThanOrEqualTo(4.5));
    }
  });

  test('tintas sobre papel (infiltradoInk, ink) >= 4.5:1', () {
    for (final c in [
      infiltradoInk,
      infiltradoInkMuted,
      GameColors.ink,
      GameColors.inkMuted,
    ]) {
      expect(contrast(c, AppColors.paper), greaterThanOrEqualTo(4.5));
    }
  });

  test('colores de juego con onPaper sobre papel >= 4.5:1', () {
    for (final c in const [
      Color(0xFF3FA796),
      Color(0xFFB57BEE),
      Color(0xFFE5575C),
      Color(0xFFE8B84A),
      Color(0xFF8E6BE0),
      Color(0xFF4C8DFF),
      Color(0xFF3CC9C0),
      Color(0xFFF2994A),
    ]) {
      expect(
        contrast(GameColors.onPaper(c), AppColors.paper),
        greaterThanOrEqualTo(4.5),
        reason: '$c',
      );
    }
  });
}
