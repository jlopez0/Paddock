import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget buildEntry(BuildContext context) => const RaceSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
    GoRoute(path: 'race', builder: (_, _) => const RaceScreen()),
    GoRoute(path: 'result', builder: (_, _) => const RaceResultScreen()),
    GoRoute(path: 'stats', builder: (_, _) => const RaceStatsScreen()),
  ];
}
