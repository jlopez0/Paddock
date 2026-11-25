import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:paddock/app/app_icons.dart';
import 'package:paddock/core/content/prompts.dart';
import 'package:paddock/core/storage.dart';
import 'package:paddock/games/abecedario/ui/abecedario_setup_screen.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_module.dart';
import 'package:paddock/games/prompt_deck/prompt_deck_screens.dart';
import 'package:paddock/games/registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget screen, double scale) async {
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        for (final g in gameModules.whereType<PromptDeckModule>())
          promptsProvider(g.contentAsset).overrideWith(
            (ref) async => const [
              Prompt(id: 'a', level: PromptLevel.suave, fields: {'texto': 'x'}),
            ],
          ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.6, 2.0]) {
    for (final game in gameModules.whereType<PromptDeckModule>()) {
      testWidgets('preparación de ${game.id} con letra $scale en 320x568', (
        tester,
      ) async {
        await _pump(tester, PromptDeckSetupScreen(game: game), scale);
        expect(tester.takeException(), isNull);
        // El título entero, sin recortes, y la cabecera con icono de juego.
        expect(find.text(game.title), findsOneWidget);
        final title = tester.renderObject<RenderParagraph>(
          find.text(game.title),
        );
        expect(title.didExceedMaxLines, isFalse);
        expect(find.byType(GameIcon), findsOneWidget);
        await tester.scrollUntilVisible(find.text('NIVEL'), 200);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('preparación de abecedario con letra $scale en 320x568', (
      tester,
    ) async {
      await _pump(tester, const AbecedarioSetupScreen(), scale);
      expect(tester.takeException(), isNull);
      expect(find.byType(GameIcon), findsOneWidget);
      expect(find.text('Abecedario'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('NIVEL'), 200);
      await tester.scrollUntilVisible(
        find.text('Jugar · 27 letras'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
