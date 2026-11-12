import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/country.dart';
import 'domain/geo_map.dart';
import 'domain/quiz.dart';

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final raw = await rootBundle.loadString('assets/content/es/geografia/paises.json');
  final items = (jsonDecode(raw) as Map<String, dynamic>)['items'] as List;
  return items.cast<Map<String, dynamic>>().map(Country.fromJson).toList(growable: false);
});

/// Mapa de regiones por id (`eeuu`, `espana`…).
final geoMapProvider = FutureProvider.family<GeoMap, String>((ref, id) async {
  final raw = await rootBundle.loadString('assets/content/es/geografia/mapas/$id.json');
  return GeoMap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});

/// Motor de preguntas para una categoría (países del mundo o un mapa).
final geoQuizProvider = FutureProvider.family<GeoQuiz, GeoCategory>((ref, category) async {
  if (category.isMap) return MapQuizEngine(await ref.watch(geoMapProvider(category.mapId!).future));
  return QuizEngine(await ref.watch(countriesProvider.future));
});

/// Construye un [Path] a partir de anillos planos x0,y0,x1,y1… (relleno par-impar).
Path pathFromRings(Iterable<List<int>> rings) {
  final p = Path()..fillType = PathFillType.evenOdd;
  for (final ring in rings) {
    p.moveTo(ring[0].toDouble(), ring[1].toDouble());
    for (var i = 2; i < ring.length; i += 2) {
      p.lineTo(ring[i].toDouble(), ring[i + 1].toDouble());
    }
    p.close();
  }
  return p;
}

/// Forma de un país: anillos de puntos (x,y) en una caja de lado mayor 1000.
class Silhouette {
  Silhouette({required this.width, required this.height, required List<List<int>> rings})
      : path = pathFromRings(rings);

  final int width;
  final int height;
  final Path path;

  factory Silhouette.fromJson(Map<String, dynamic> j) => Silhouette(
        width: j['w'] as int,
        height: j['h'] as int,
        rings: (j['p'] as List).map((r) => (r as List).cast<int>()).toList(),
      );
}

/// Siluetas por código ISO en minúsculas.
final silhouettesProvider = FutureProvider<Map<String, Silhouette>>((ref) async {
  final raw = await rootBundle.loadString('assets/geo/siluetas.json');
  return {
    for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
      e.key.toLowerCase(): Silhouette.fromJson(e.value as Map<String, dynamic>),
  };
});
