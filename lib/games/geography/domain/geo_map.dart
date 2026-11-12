import 'dart:math';

/// Mapa de divisiones administrativas (estados, provincias…) en coordenadas
/// planas con el lado mayor = 2000.
class GeoMap {
  const GeoMap({
    required this.id,
    required this.title,
    required this.question,
    required this.flagIso,
    required this.width,
    required this.height,
    required this.frames,
    required this.regions,
  });

  final String id;
  final String title;

  /// Texto de la pregunta, p. ej. "¿Qué estado está marcado?".
  final String question;
  final String flagIso;
  final int width;
  final int height;

  /// Recuadros (x, y, ancho, alto) de los territorios desplazados: Alaska, Canarias…
  final List<List<int>> frames;
  final List<MapRegion> regions;

  factory GeoMap.fromJson(Map<String, dynamic> j) => GeoMap(
        id: j['id'] as String,
        title: j['titulo'] as String,
        question: j['pregunta'] as String,
        flagIso: j['bandera'] as String,
        width: j['w'] as int,
        height: j['h'] as int,
        frames: (j['recuadros'] as List).map((f) => (f as List).cast<int>()).toList(),
        regions: (j['regiones'] as List).cast<Map<String, dynamic>>().map(MapRegion.fromJson).toList(),
      );
}

class MapRegion {
  MapRegion({required this.id, required this.name, required this.center, required this.rings, this.aliases = const []}) {
    var x0 = double.infinity, y0 = double.infinity, x1 = -double.infinity, y1 = -double.infinity;
    for (final r in rings) {
      for (var i = 0; i < r.length; i += 2) {
        x0 = min(x0, r[i].toDouble());
        x1 = max(x1, r[i].toDouble());
        y0 = min(y0, r[i + 1].toDouble());
        y1 = max(y1, r[i + 1].toDouble());
      }
    }
    bounds = (x0, y0, x1, y1);
  }

  final String id;
  final String name;
  final List<String> aliases;

  /// Punto interior aproximado (centroide de su parte mayor).
  final (int, int) center;

  /// Anillos como listas planas x0,y0,x1,y1…
  final List<List<int>> rings;
  late final (double, double, double, double) bounds;

  double get size => max(bounds.$3 - bounds.$1, bounds.$4 - bounds.$2);
  List<String> get acceptedNames => [name, ...aliases];

  factory MapRegion.fromJson(Map<String, dynamic> j) {
    final c = (j['c'] as List).cast<int>();
    return MapRegion(
      id: j['id'] as String,
      name: j['nombre'] as String,
      center: (c[0], c[1]),
      rings: (j['p'] as List).map((r) => (r as List).cast<int>()).toList(),
      aliases: (j['alias'] as List?)?.cast<String>() ?? const [],
    );
  }
}
