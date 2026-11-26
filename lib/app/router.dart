import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/consequences/consequences.dart';
import '../core/players/players_screen.dart';
import '../core/settings/onboarding_controller.dart';
import '../core/settings/settings_controller.dart';
import '../games/registry.dart';
import 'credits_screen.dart';
import 'cup_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'welcome_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Cualquier cambio de bienvenida o de modo de consecuencias reevalúa las redirecciones.
  final refresh = ValueNotifier<int>(0);
  ref.listen<bool>(onboardingProvider, (_, _) => refresh.value++);
  ref.listen<ConsequenceMode>(
    settingsProvider.select((s) => s.consequenceMode),
    (_, _) => refresh.value++,
  );
  ref.onDispose(refresh.dispose);
  return buildRouter(
    isWelcomeSeen: () => ref.read(onboardingProvider),
    consequenceMode: () => ref.read(settingsProvider).consequenceMode,
    refresh: refresh,
  );
});

/// Todas las rutas cuelgan de `/`, así `context.go()` siempre deja el menú debajo.
/// La bienvenida +18 (`/welcome`) se fuerza hasta que se ha visto una vez. Un juego que no
/// se ofrece con el modo actual (la Carrera en Retos, D21) redirige a `/` en su ruta y subrutas.
GoRouter buildRouter({
  required bool Function() isWelcomeSeen,
  ConsequenceMode Function()? consequenceMode,
  Listenable? refresh,
}) {
  return GoRouter(
    refreshListenable: refresh,
    redirect: (_, state) {
      final seen = isWelcomeSeen();
      final location = state.matchedLocation;
      final atWelcome = location == '/welcome';
      if (!seen && !atWelcome) return '/welcome';
      if (seen && atWelcome) return '/';
      final mode = consequenceMode?.call() ?? ConsequenceMode.puntos;
      for (final g in gameModules) {
        final inside = location == g.path || location.startsWith('${g.path}/');
        if (inside && !g.availableIn(mode)) return '/';
      }
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
            routes: [
              GoRoute(
                path: 'credits',
                builder: (_, _) => const CreditsScreen(),
              ),
            ],
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
