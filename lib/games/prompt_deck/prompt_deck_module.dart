import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/prompts.dart';
import '../game_module.dart';
import 'prompt_deck_logic.dart';
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

/// Qué consecuencia enseña la carta. Ningún mazo marca personas ni anota en la Copa: la
/// mesa lo resuelve sola y la app solo recuerda lo que toca en Retos y Sorbos.
enum PromptPayMode {
  /// Sin consecuencia (¿Qué preferirías?).
  none,

  /// Cada carta lleva una intensidad aleatoria de 1 a 3 (D20) que paga quien lo haya hecho
  /// (Yo nunca). En Retos y Sorbos, banner "Quien lo haya hecho" bajo la carta (un reto del
  /// nivel que toca, o "N sorbos · o agua o reto"); en Fichas, nada. El titular no se
  /// repite en la carta: solo en [stake].
  fixed,

  /// Cada carta anuncia una apuesta (en Retos "¡Por un reto!", en Sorbos "Por 2 sorbos";
  /// en Fichas no se muestra) y la mesa la resuelve sola (¿Quién es más probable?).
  stake,
}

/// Juego de "mazo de cartas de texto". Sirve para cualquier juego que consista
/// en ir pasando cartas leídas de un fichero JSON: basta con crear una instancia
/// nueva en `registry.dart` y su fichero en `assets/content/es/`.
class PromptDeckModule extends GameModule {
  const PromptDeckModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.contentAsset,
    required this.style,
    required this.rule,
    this.prefix,
    this.payMode = PromptPayMode.none,
    this.rounds = kPromptDefaultRounds,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String subtitle;
  @override
  final Color color;

  final String contentAsset;
  final PromptCardStyle style;

  /// Regla que se muestra bajo cada carta.
  final String rule;

  /// Prefijo para las cartas de tipo [PromptCardStyle.statement].
  final String? prefix;

  /// Consecuencia que enseña la carta (ver [PromptPayMode]). Los mazos nunca anotan en
  /// la Copa: `scoresCup` se queda en `false`.
  final PromptPayMode payMode;

  /// Cartas por partida: dura siempre lo mismo y no revela cuántas cartas hay guardadas.
  final int rounds;

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
