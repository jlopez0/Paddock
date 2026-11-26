import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/consequences/consequences.dart';
import '../game_module.dart';
import 'ui/race_result_screen.dart';
import 'ui/race_screen.dart';
import 'ui/race_setup_screen.dart';
import 'ui/race_stats_screen.dart';

class HorseRaceModule extends GameModule {
  const HorseRaceModule();

  @override
  String get id => 'carrera';
  @override
  String get title => 'Carrera de caballos';
  @override
  String get subtitle => 'Elige palo, apuesta y que corra tu caballo';
  @override
  Color get color => const Color(0xFFE8B84A);

  @override
  bool get scoresCup => true;

  /// En Retos no hay Carrera (D21): la apuesta de 1 a 5 fichas no encaja con "un solo reto
  /// por evento" y cada carrera sumaría reglas propias solo para ese modo.
  @override
  bool availableIn(ConsequenceMode mode) => mode != ConsequenceMode.retos;

  @override
  Widget buildEntry(BuildContext context) => const RaceSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
    GoRoute(path: 'race', builder: (_, _) => const RaceScreen()),
    GoRoute(path: 'result', builder: (_, _) => const RaceResultScreen()),
    GoRoute(path: 'stats', builder: (_, _) => const RaceStatsScreen()),
  ];
}
