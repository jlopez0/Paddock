import 'package:material_ui/material_ui.dart';

import '../core/consequences/consequences.dart';
import 'game_module.dart';
import 'geography/geography_module.dart';
import 'horse_race/horse_race_module.dart';
import 'infiltrado/infiltrado_module.dart';
import 'prompt_deck/prompt_deck_module.dart';
import 'abecedario/abecedario_module.dart';
import 'trivia/trivia_module.dart';

/// Juegos disponibles, en el orden en que aparecen en el menú: la Carrera siempre
/// la primera, luego los de previa (sin preparación) y después los que piden más puesta en marcha.
const List<GameModule> gameModules = [
  HorseRaceModule(),
  PromptDeckModule(
    id: 'quien-es-mas-probable',
    title: '¿Quién es más probable?',
    subtitle: 'Señalad sin piedad',
    color: Color(0xFF3FA796),
    contentAsset: 'assets/content/es/quien_es_mas_probable.json',
    style: PromptCardStyle.question,
    rule: 'A la de tres, todos señalan. Al más señalado le toca lo que diga la carta',
    payMode: PromptPayMode.stake,
  ),
  PromptDeckModule(
    id: 'yo-nunca',
    title: 'Yo nunca',
    subtitle: 'Aquí se confiesa todo',
    color: Color(0xFFE5575C),
    contentAsset: 'assets/content/es/yo_nunca.json',
    style: PromptCardStyle.statement,
    prefix: 'Yo nunca',
    rule: 'Quien lo haya hecho, que lo confiese',
    payMode: PromptPayMode.fixed,
    rounds: 20,
  ),
  InfiltradoModule(),
  PromptDeckModule(
    id: 'que-preferirias',
    title: '¿Qué preferirías?',
    subtitle: 'Dos opciones, ninguna buena',
    color: Color(0xFFB57BEE),
    contentAsset: 'assets/content/es/que_preferirias.json',
    style: PromptCardStyle.choice,
    rule: 'A la de tres, todos eligen. Defended vuestra elección',
  ),
  AbecedarioModule(),
  TriviaModule(),
  GeographyModule(),
];

/// Juegos que se ofrecen con el modo de consecuencias [mode], en el mismo orden. Con Retos
/// la Carrera no está (D21); en Fichas y Sorbos es la lista completa.
List<GameModule> gamesFor(ConsequenceMode mode) => [
  for (final g in gameModules)
    if (g.availableIn(mode)) g,
];
