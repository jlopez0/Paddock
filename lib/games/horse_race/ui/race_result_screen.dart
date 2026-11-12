import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../race_result.dart';

class RaceResultScreen extends ConsumerWidget {
  const RaceResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(lastRaceResultProvider);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No hay ninguna carrera terminada')),
      );
    }
    final winners = result.outcomes.where((o) => o.won).toList();
    final losers = result.outcomes.where((o) => !o.won).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _Podium(standings: result.standings),
          const SizedBox(height: 8),
          Text('${result.draws} cartas sacadas',
              textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          if (winners.isNotEmpty)
            _OutcomeSection(
              title: '🎉 Reparten',
              color: AppColors.success,
              outcomes: winners,
            ),
          if (losers.isNotEmpty)
            _OutcomeSection(
              title: '🍺 Beben',
              color: AppColors.danger,
              outcomes: losers,
            ),
          if (winners.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text('Nadie acertó. ¡A beber todos!', textAlign: TextAlign.center),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/game/carrera'),
                child: const Text('Cambiar apuestas'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.pushReplacement('/game/carrera/race'),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Revancha'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.standings});

  final List<Suit> standings;

  @override
  Widget build(BuildContext context) {
    // Orden visual: 2º, 1º, 3º.
    const order = [1, 0, 2];
    const heights = [70.0, 100.0, 50.0];
    return SizedBox(
      height: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 500 + 200 * i),
                      curve: Curves.easeOutBack,
                      builder: (c, t, child) => Transform.scale(scale: t, child: child),
                      child: Image.asset(PlayingCard.horseAsset(standings[order[i]]),
                          height: order[i] == 0 ? 130 : 95),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: heights[i],
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: standings[order[i]].color.withValues(alpha: 0.25),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        border: Border.all(color: standings[order[i]].color),
                      ),
                      child: Text('${order[i] + 1}º',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutcomeSection extends ConsumerWidget {
  const _OutcomeSection({required this.title, required this.color, required this.outcomes});

  final String title;
  final Color color;
  final List<BetOutcome> outcomes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 8),
          for (final o in outcomes)
            if (players.byId(o.bet.playerId) case final p?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    leading: PlayerAvatar(p),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Apostó ${o.bet.isHidalgo ? "hidalgo 💀" : o.bet.sips} a ${o.bet.suit.label}'),
                    trailing: Text(
                      o.label,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
