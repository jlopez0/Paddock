import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../game_module.dart';
import 'abecedario_data.dart';
import 'ui/abecedario_play_screen.dart';
import 'ui/abecedario_setup_screen.dart';

class AbecedarioModule extends GameModule {
  const AbecedarioModule();

  @override
  String get id => 'abecedario';
  @override
  String get title => 'Abecedario';
  @override
  String get subtitle => 'Una palabra por letra, de la A a la Z';
  @override
  Color get color => abecedarioColor;

  @override
  Widget buildEntry(BuildContext context) => const AbecedarioSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
    GoRoute(path: 'play', builder: (_, _) => const AbecedarioPlayScreen()),
  ];
}
