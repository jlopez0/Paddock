import 'package:flutter/material.dart';

import 'game_module.dart';
import 'horse_race/horse_race_module.dart';
import 'prompt_deck/prompt_deck_module.dart';

/// Juegos disponibles, en el orden en que aparecen en el menú.
const List<GameModule> gameModules = [
  HorseRaceModule(),
  PromptDeckModule(
    id: 'yo-nunca',
    title: 'Yo nunca',
    subtitle: 'Confiesa… o bebe',
    emoji: '🙊',
    color: Color(0xFFE5575C),
    contentAsset: 'assets/content/es/yo_nunca.json',
    style: PromptCardStyle.statement,
    prefix: 'Yo nunca',
    rule: 'Quien lo haya hecho, bebe 🍺',
  ),
  PromptDeckModule(
    id: 'que-preferirias',
    title: '¿Qué preferirías?',
    subtitle: 'Dos opciones, ninguna buena',
    emoji: '🤔',
    color: Color(0xFFB57BEE),
    contentAsset: 'assets/content/es/que_preferirias.json',
    style: PromptCardStyle.choice,
    rule: 'A la de tres, todos eligen. La minoría bebe 🍺',
  ),
];
