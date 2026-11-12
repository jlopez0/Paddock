import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Contrato de un juego. Para añadir un juego nuevo:
/// 1. Crea su carpeta en `lib/games/<juego>/` con una clase que implemente esto.
/// 2. Añádelo a la lista de `registry.dart`.
/// El menú principal y las rutas se generan automáticamente.
abstract class GameModule {
  const GameModule();

  /// Identificador único; la ruta de entrada es `/game/<id>`.
  String get id;
  String get title;
  String get subtitle;
  String get emoji;
  Color get color;

  String get path => '/game/$id';

  /// Pantalla de entrada del juego.
  Widget buildEntry(BuildContext context);

  /// Subrutas relativas a [path] (p. ej. `play` → `/game/<id>/play`).
  List<RouteBase> get subRoutes => const [];
}
