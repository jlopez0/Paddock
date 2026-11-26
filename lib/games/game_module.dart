import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app/app_icons.dart';
import '../core/consequences/consequences.dart';

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
  Color get color;

  /// Icono del juego (duotono, ver `GameIcon`). Se resuelve por [id].
  Widget icon(double size) => GameIcon(id, size: size);

  /// `true` si el juego anota fichas en la Copa de la noche (llama a `award`). Por defecto
  /// no: solo suman los juegos en los que la app sabe quién gana o pierde por persona
  /// (hoy Carrera e Infiltrado). Lo vigila `test/cup_guard_test.dart`.
  bool get scoresCup => false;

  /// `false` si el juego no se ofrece con el modo de consecuencias [mode] (hoy solo la
  /// Carrera en Retos, D21). El menú lo oculta y su ruta redirige a `/`.
  bool availableIn(ConsequenceMode mode) => true;

  String get path => '/game/$id';

  /// Pantalla de entrada del juego.
  Widget buildEntry(BuildContext context);

  /// Subrutas relativas a [path] (p. ej. `play` → `/game/<id>/play`).
  List<RouteBase> get subRoutes => const [];
}
