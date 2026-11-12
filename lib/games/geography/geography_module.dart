import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game_module.dart';
import 'ui/geo_quiz_screen.dart';
import 'ui/geo_result_screen.dart';
import 'ui/geo_setup_screen.dart';
import 'ui/geo_widgets.dart';

class GeographyModule extends GameModule {
  const GeographyModule();

  @override
  String get id => 'geografia';
  @override
  String get title => 'Geografía';
  @override
  String get subtitle => 'Banderas, capitales, siluetas y mapas';
  @override
  String get emoji => '🌍';
  @override
  Color get color => geoColor;

  @override
  Widget buildEntry(BuildContext context) => const GeoSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
        GoRoute(path: 'play', builder: (_, _) => const GeoQuizScreen()),
        GoRoute(path: 'result', builder: (_, _) => const GeoResultScreen()),
      ];
}
