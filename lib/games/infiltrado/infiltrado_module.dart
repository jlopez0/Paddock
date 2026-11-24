import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../game_module.dart';
import 'ui/infiltrado_result_screen.dart';
import 'ui/infiltrado_reveal_screen.dart';
import 'ui/infiltrado_setup_screen.dart';
import 'ui/infiltrado_vote_screen.dart';

/// El Infiltrado: todos conocen la palabra menos uno. Se juega pasando el móvil.
class InfiltradoModule extends GameModule {
  const InfiltradoModule();

  @override
  String get id => 'infiltrado';
  @override
  String get title => 'El Infiltrado';
  @override
  String get subtitle => 'Todos saben la palabra menos uno';
  @override
  Color get color => const Color(0xFF8E6BE0);

  @override
  Widget buildEntry(BuildContext context) => const InfiltradoSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
    GoRoute(path: 'reveal', builder: (_, _) => const InfiltradoRevealScreen()),
    GoRoute(path: 'vote', builder: (_, _) => const InfiltradoVoteScreen()),
    GoRoute(path: 'result', builder: (_, _) => const InfiltradoResultScreen()),
  ];
}
