import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/players/player_widgets.dart';
import '../core/players/players_controller.dart';
import '../games/game_module.dart';
import '../games/registry.dart';
import 'theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paddock',
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                          Text('Juegos para la previa', style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Créditos',
                      icon: const Icon(Icons.info_outline_rounded),
                      onPressed: () => context.push('/credits'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push('/players'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.groups_rounded, color: AppColors.gold),
                          const SizedBox(width: 12),
                          Expanded(
                            child: players.isEmpty
                                ? const Text('Añade jugadores')
                                : Text('${players.length} jugadores',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          for (final p in players.take(5))
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: PlayerAvatar(p, size: 28),
                            ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverList.separated(
                itemCount: gameModules.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, i) => _GameTile(gameModules[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile(this.game);

  final GameModule game;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(game.path),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [game.color.withValues(alpha: 0.35), game.color.withValues(alpha: 0.08)],
            ),
            border: Border.all(color: game.color.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Text(game.emoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(game.subtitle, style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
