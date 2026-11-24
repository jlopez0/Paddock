import 'package:material_ui/material_ui.dart';

import 'game_module.dart';
import 'geography/geography_module.dart';
import 'horse_race/horse_race_module.dart';
import 'infiltrado/infiltrado_module.dart';
import 'prompt_deck/prompt_deck_module.dart';
import 'abecedario/abecedario_module.dart';
import 'trivia/trivia_module.dart';

/// Juegos disponibles, en el orden en que aparecen en el menú.
const List<GameModule> gameModules = [
  HorseRaceModule(),
  InfiltradoModule(),
  TriviaModule(),
  GeographyModule(),
  AbecedarioModule(),
  PromptDeckModule(
    id: 'quien-es-mas-probable',
    title: '¿Quién es más probable?',
    subtitle: 'Señala al más probable',
    color: Color(0xFF3FA796),
    contentAsset: 'assets/content/es/quien_es_mas_probable.json',
    style: PromptCardStyle.question,
    rule: 'A la de tres, todos señalan. El más señalado pierde una ficha',
    payMode: PromptPayMode.single,
  ),
  PromptDeckModule(
    id: 'que-preferirias',
    title: '¿Qué preferirías?',
    subtitle: 'Dos opciones, ninguna buena',
    color: Color(0xFFB57BEE),
    contentAsset: 'assets/content/es/que_preferirias.json',
    style: PromptCardStyle.choice,
    rule: 'A la de tres, todos eligen. La minoría pierde una ficha',
    payMode: PromptPayMode.single,
  ),
  PromptDeckModule(
    id: 'yo-nunca',
    title: 'Yo nunca',
    subtitle: 'Confiesa… o paga',
    color: Color(0xFFE5575C),
    contentAsset: 'assets/content/es/yo_nunca.json',
    style: PromptCardStyle.statement,
    prefix: 'Yo nunca',
    rule: 'Quien lo haya hecho, pierde una ficha',
    payMode: PromptPayMode.multi,
  ),
];
