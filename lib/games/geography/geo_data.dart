import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/country.dart';

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final raw = await rootBundle.loadString('assets/content/es/geografia/paises.json');
  final items = (jsonDecode(raw) as Map<String, dynamic>)['items'] as List;
  return items.cast<Map<String, dynamic>>().map(Country.fromJson).toList(growable: false);
});

/// Forma de un país: anillos de puntos (x,y) en una caja de lado mayor 1000.
/// Se dibujan con relleno par-impar, así los huecos (p. ej. Lesoto) salen bien.
class Silhouette {
  Silhouette({required this.width, required this.height, required List<List<int>> rings}) {
    final p = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      p.moveTo(ring[0].toDouble(), ring[1].toDouble());
      for (var i = 2; i < ring.length; i += 2) {
        p.lineTo(ring[i].toDouble(), ring[i + 1].toDouble());
      }
      p.close();
    }
    path = p;
  }

  final int width;
  final int height;
  late final Path path;

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
