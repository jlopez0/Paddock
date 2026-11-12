import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/prompts.dart';
import '../game_module.dart';
import 'prompt_deck_screens.dart';

enum PromptCardStyle {
  /// Una frase con un prefijo opcional ("Yo nunca …").
  statement,

  /// Dos opciones `a` / `b`.
  choice,
}

/// Juego de "mazo de cartas de texto". Sirve para cualquier juego que consista
/// en ir pasando cartas leídas de un fichero JSON: basta con crear una instancia
/// nueva en `registry.dart` y su fichero en `assets/content/es/`.
class PromptDeckModule extends GameModule {
  const PromptDeckModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.contentAsset,
    required this.style,
    required this.rule,
    this.prefix,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final String emoji;
  @override
  final Color color;

  final String contentAsset;
  final PromptCardStyle style;

  /// Regla que se muestra bajo cada carta.
  final String rule;

  /// Prefijo para las cartas de tipo [PromptCardStyle.statement].
  final String? prefix;

  @override
  Widget buildEntry(BuildContext context) => PromptDeckSetupScreen(game: this);

  @override
  List<RouteBase> get subRoutes => [
        GoRoute(
          path: 'play',
          builder: (context, state) {
            final levels = (state.uri.queryParameters['levels'] ?? '')
                .split(',')
                .where((s) => s.isNotEmpty)
                .map(PromptLevel.values.byName)
                .toSet();
            return PromptDeckPlayScreen(game: this, levels: levels);
          },
        ),
      ];
}
