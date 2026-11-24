import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nivel de una carta. No guarda icono: las pantallas dibujan el de [id] con
/// `LevelIcon` (lib/app/app_icons.dart).
enum PromptLevel {
  suave('Suave'),
  picante('Picante'),
  atrevido('Atrevido');

  const PromptLevel(this.label);

  /// Texto visible del nivel.
  final String label;

  /// Identificador estable ('suave' | 'picante' | 'atrevido'): el de la ruta,
  /// el guardado y `LevelIcon`.
  String get id => name;

  /// Convierte un nombre guardado o recibido por ruta. Acepta el antiguo `hot`
  /// como `atrevido` y devuelve `null` si no se reconoce (nunca lanza).
  static PromptLevel? tryParse(String? name) {
    if (name == 'hot') return PromptLevel.atrevido;
    for (final l in PromptLevel.values) {
      if (l.name == name) return l;
    }
    return null;
  }
}

/// Una carta de contenido. Los campos de texto dependen del juego
/// (p. ej. `texto` en "Yo nunca"; `a` y `b` en "¿Qué preferirías?").
class Prompt {
  const Prompt({required this.id, required this.level, required this.fields});

  final String id;
  final PromptLevel level;
  final Map<String, String> fields;

  String operator [](String key) => fields[key] ?? '';

  /// Devuelve `null` si el nivel es desconocido (la carta se descarta).
  static Prompt? tryFromJson(Map<String, dynamic> j) {
    final level = PromptLevel.tryParse(j['nivel'] as String?);
    if (level == null) return null;
    return Prompt(
      id: j['id'] as String,
      level: level,
      fields: {
        for (final e in j.entries)
          if (e.key != 'id' && e.key != 'nivel') e.key: e.value as String,
      },
    );
  }
}

/// Parsea un fichero de contenido `{ "version": 1, "items": [...] }`.
List<Prompt> parsePrompts(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  return [
    for (final j in (data['items'] as List).cast<Map<String, dynamic>>())
      ?Prompt.tryFromJson(j),
  ];
}

/// Carga (y cachea) un fichero de contenido de `assets/content/`.
final promptsProvider = FutureProvider.family<List<Prompt>, String>((
  ref,
  asset,
) async {
  return parsePrompts(await rootBundle.loadString(asset));
});
