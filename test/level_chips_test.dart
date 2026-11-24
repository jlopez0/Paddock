import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/prompt_deck/game_colors.dart';
import 'package:paddock/games/prompt_deck/level_chips.dart';
import 'package:shared_preferences/shared_preferences.dart';

double _contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final x = lum(a), y = lum(b);
  return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
}

void main() {
  test('contraste local >= 4,5:1 sobre las superficies oscuras', () {
    const surfaces = [
      Color(0xFF0B1611), // background
      Color(0xFF13241B), // surface
      Color(0xFF1C3326), // surfaceHigh
      Color(0xFF2B4636), // outline / chip seleccionado
    ];
    for (final s in surfaces) {
      expect(_contrast(GameColors.mutedText, s), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(GameColors.infiltradoText, s),
        greaterThanOrEqualTo(4.5),
      );
    }
  });

  Future<Set<PromptLevel>> pumpChips(
    WidgetTester tester, {
    bool adult = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final levels = <PromptLevel>{PromptLevel.suave};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => StatefulBuilder(
              builder: (context, setState) => Scaffold(
                body: LevelChips(
                  levels: levels,
                  color: const Color(0xFF8E6BE0),
                  onToggle: (l) async {
                    if (!levels.contains(l) &&
                        !await ensureLevelAllowed(context, ref, l)) {
                      return;
                    }
                    setState(() {
                      if (!levels.remove(l)) levels.add(l);
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return levels;
  }

  testWidgets('chips con check, selección múltiple y Atrevido pide +18', (
    tester,
  ) async {
    final levels = await pumpChips(tester);
    expect(find.byType(FilterChip), findsNWidgets(PromptLevel.values.length));
    expect(
      tester
          .widgetList<FilterChip>(find.byType(FilterChip))
          .every((c) => c.showCheckmark == true),
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('level-picante')));
    await tester.pumpAndSettle();
    expect(levels, {PromptLevel.suave, PromptLevel.picante});

    await tester.tap(find.byKey(const ValueKey('level-atrevido')));
    await tester.pumpAndSettle();
    expect(find.text('Solo para mayores de 18'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(levels.contains(PromptLevel.atrevido), isFalse);

    await tester.tap(find.byKey(const ValueKey('level-atrevido')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tengo 18 o más'));
    await tester.pumpAndSettle();
    expect(levels.contains(PromptLevel.atrevido), isTrue);
  });
}
