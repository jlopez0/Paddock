import '../content/prompts.dart';

/// Textos de reto permitidos: `suave` y `picante` siempre; `atrevido` solo si
/// el usuario ha confirmado ser mayor de edad ([adultConfirmed]).
List<String> filterRetos(Iterable<Prompt> prompts, {required bool adultConfirmed}) => [
      for (final p in prompts)
        if ((p.level != PromptLevel.atrevido || adultConfirmed) && p['texto'].isNotEmpty) p['texto'],
    ];
