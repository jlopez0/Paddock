import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/prompts.dart';
import '../game_module.dart';
import 'prompt_deck_screens.dart';

enum PromptCardStyle {
  /// Una frase con un prefijo opcional ("Yo nunca …").
  statement,

  /// Dos opciones `a` / `b`.
  choice,

  /// Pregunta "¿Quién es más probable que …?": el prefijo y el cierre "?" los pone el estilo
  /// y el `texto` de la carta va sin ellos.
  question,
}

/// Cómo se reparten fichas en la Copa al pasar cada carta.
enum PromptPayMode {
  /// No se registra nada (comportamiento clásico).
  none,

  /// Se marcan varios jugadores (Yo nunca: quienes lo hayan hecho).
  multi,

  /// Se marca a quien pierde la votación (¿Quién es más probable?: el más votado;
  /// ¿Qué preferirías?: la minoría, que puede ser más de uno).
  single,
}

/// Fichas que paga cada jugador marcado en una carta.
const int kPromptPayChips = 1;

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
    this.payMode = PromptPayMode.none,
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

  /// Si no es [PromptPayMode.none], bajo la carta aparece la fila "¿Quién paga?".
  final PromptPayMode payMode;

  /// Ayuda bajo "¿Quién paga?", según el modo y el estilo de la carta.
  String get payHint => switch ((payMode, style)) {
    (PromptPayMode.none, _) => '',
    (PromptPayMode.multi, _) => 'Marca a quien lo haya hecho',
    (PromptPayMode.single, PromptCardStyle.choice) => 'Marca a la minoría',
    (PromptPayMode.single, PromptCardStyle.question) => 'Marca al más votado',
    (PromptPayMode.single, _) => 'Marca a quien pague',
  };

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
            .map(
              PromptLevel.tryParse,
            ) // acepta el antiguo "hot" como "atrevido"
            .whereType<PromptLevel>()
            .toSet();
        return PromptDeckPlayScreen(game: this, levels: levels);
      },
    ),
  ];
}
