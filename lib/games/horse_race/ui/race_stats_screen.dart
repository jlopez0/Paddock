import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../domain/cards.dart';
import '../race_store.dart';

class RaceStatsScreen extends ConsumerWidget {
  const RaceStatsScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Borrar estadísticas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(raceStatsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(raceStatsProvider);
    final players = ref.watch(playersProvider);
    final rows =
        [
          for (final p in players)
            if (stats.byPlayer[p.id] case final s?) (player: p, stats: s),
        ]..sort((a, b) {
          final byHits = b.stats.hits.compareTo(a.stats.hits);
          return byHits != 0
              ? byHits
              : b.stats.hitRate.compareTo(a.stats.hitRate);
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          if (stats.totalRaces > 0)
            IconButton(
              tooltip: 'Borrar',
              icon: AppIcon.delete.widget(),
              onPressed: () => _reset(context, ref),
            ),
        ],
      ),
      body: stats.totalRaces == 0
          ? const SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Jockey(size: 96),
                      SizedBox(height: 12),
                      Text(
                        'Pista sin estrenar',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              top: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    stats.totalRaces == 1
                        ? '1 carrera'
                        : '${stats.totalRaces} carreras',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final s in Suit.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Column(
                                  children: [
                                    Image.asset(
                                      PlayingCard.horseAsset(s),
                                      height: 56,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${stats.winsBySuit[s] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: s.color,
                                      ),
                                    ),
                                    const Text(
                                      'victorias',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  for (final (i, r) in rows.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 32,
                                child: i < 3
                                    ? MedalIcon(i + 1, size: 30)
                                    : Text(
                                        '${i + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: AppFonts.display,
                                          fontSize: 18,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 4),
                              PlayerAvatar(r.player),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.player.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${r.stats.hits}/${r.stats.races} aciertos · '
                                      '${(r.stats.hitRate * 100).round()}%',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _Metric(
                                label: 'fichas perdidas',
                                value: r.stats.chipsLost,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 12),
                              _Metric(
                                label: 'fichas ganadas',
                                value: r.stats.chipsWon,
                                color: AppColors.success,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
      SizedBox(
        width: 56,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
      ),
    ],
  );
}
