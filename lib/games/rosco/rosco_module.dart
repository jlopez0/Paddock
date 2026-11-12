import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game_module.dart';
import 'rosco_data.dart';
import 'ui/rosco_play_screen.dart';
import 'ui/rosco_setup_screen.dart';

class RoscoModule extends GameModule {
  const RoscoModule();

  @override
  String get id => 'rosco';
  @override
  String get title => 'El rosco';
  @override
  String get subtitle => 'Adivina la palabra de cada letra';
  @override
  String get emoji => '🔤';
  @override
  Color get color => roscoColor;

  @override
  Widget buildEntry(BuildContext context) => const RoscoSetupScreen();

  @override
  List<RouteBase> get subRoutes => [GoRoute(path: 'play', builder: (_, _) => const RoscoPlayScreen())];
}
