import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../game_module.dart';
import 'trivia_data.dart';
import 'ui/trivia_quiz_screen.dart';
import 'ui/trivia_result_screen.dart';
import 'ui/trivia_setup_screen.dart';

class TriviaModule extends GameModule {
  const TriviaModule();

  @override
  String get id => 'trivia';
  @override
  String get title => 'Trivia';
  @override
  String get subtitle => 'Cultura general en 4 opciones';
  @override
  String get emoji => '🧠';
  @override
  Color get color => triviaColor;

  @override
  Widget buildEntry(BuildContext context) => const TriviaSetupScreen();

  @override
  List<RouteBase> get subRoutes => [
        GoRoute(path: 'play', builder: (_, _) => const TriviaQuizScreen()),
        GoRoute(path: 'result', builder: (_, _) => const TriviaResultScreen()),
      ];
}
