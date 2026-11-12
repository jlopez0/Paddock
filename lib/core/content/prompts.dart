import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PromptLevel {
  suave('Suave', '😇'),
  picante('Picante', '🌶️'),
  hot('Hot', '🔥');

  const PromptLevel(this.label, this.emoji);

  final String label;
  final String emoji;
}

/// Una carta de contenido. Los campos de texto dependen del juego
/// (p. ej. `texto` en "Yo nunca"; `a` y `b` en "¿Qué preferirías?").
class Prompt {
  const Prompt({required this.id, required this.level, required this.fields});

  final String id;
  final PromptLevel level;
  final Map<String, String> fields;

  String operator [](String key) => fields[key] ?? '';

  factory Prompt.fromJson(Map<String, dynamic> j) => Prompt(
        id: j['id'] as String,
        level: PromptLevel.values.byName(j['nivel'] as String),
        fields: {
          for (final e in j.entries)
            if (e.key != 'id' && e.key != 'nivel') e.key: e.value as String,
        },
      );
}

/// Parsea un fichero de contenido `{ "version": 1, "items": [...] }`.
List<Prompt> parsePrompts(String json) {
  final data = jsonDecode(json) as Map<String, dynamic>;
  return (data['items'] as List).cast<Map<String, dynamic>>().map(Prompt.fromJson).toList();
}

/// Carga (y cachea) un fichero de contenido de `assets/content/`.
final promptsProvider = FutureProvider.family<List<Prompt>, String>((ref, asset) async {
  return parsePrompts(await rootBundle.loadString(asset));
});
