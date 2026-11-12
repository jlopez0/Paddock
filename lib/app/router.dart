import 'package:go_router/go_router.dart';

import '../core/players/players_screen.dart';
import '../games/registry.dart';
import 'credits_screen.dart';
import 'home_screen.dart';

/// Todas las rutas cuelgan de `/`, así `context.go()` siempre deja el menú debajo.
final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const HomeScreen(),
      routes: [
        GoRoute(path: 'players', builder: (_, _) => const PlayersScreen()),
        GoRoute(path: 'credits', builder: (_, _) => const CreditsScreen()),
        for (final game in gameModules)
          GoRoute(
            path: game.path.substring(1),
            builder: (context, _) => game.buildEntry(context),
            routes: game.subRoutes,
          ),
      ],
    ),
  ],
);
