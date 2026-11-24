import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/players/players_screen.dart';
import '../core/settings/onboarding_controller.dart';
import '../games/registry.dart';
import 'credits_screen.dart';
import 'cup_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<bool>(ref.read(onboardingProvider));
  ref.listen<bool>(onboardingProvider, (_, seen) => refresh.value = seen);
  ref.onDispose(refresh.dispose);
  return buildRouter(isWelcomeSeen: () => ref.read(onboardingProvider), refresh: refresh);
});

/// Todas las rutas cuelgan de `/`, así `context.go()` siempre deja el menú debajo.
/// La bienvenida +18 (`/welcome`) se fuerza hasta que se ha visto una vez.
GoRouter buildRouter({required bool Function() isWelcomeSeen, Listenable? refresh}) {
  return GoRouter(
    refreshListenable: refresh,
    redirect: (_, state) {
      final seen = isWelcomeSeen();
      final atWelcome = state.matchedLocation == '/welcome';
      if (!seen && !atWelcome) return '/welcome';
      if (seen && atWelcome) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(path: 'players', builder: (_, _) => const PlayersScreen()),
          GoRoute(path: 'copa', builder: (_, _) => const CupScreen()),
          GoRoute(
            path: 'settings',
            builder: (_, _) => const SettingsScreen(),
            routes: [GoRoute(path: 'credits', builder: (_, _) => const CreditsScreen())],
          ),
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
}
