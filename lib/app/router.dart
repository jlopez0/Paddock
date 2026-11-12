import 'package:go_router/go_router.dart';

import '../core/players/players_screen.dart';
import '../games/registry.dart';
import 'credits_screen.dart';
import 'home_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/players', builder: (_, _) => const PlayersScreen()),
    GoRoute(path: '/credits', builder: (_, _) => const CreditsScreen()),
    for (final game in gameModules)
      GoRoute(
        path: game.path,
        builder: (context, _) => game.buildEntry(context),
        routes: game.subRoutes,
      ),
  ],
);
