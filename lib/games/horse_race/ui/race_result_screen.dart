import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/consequences/consequence_banner.dart';
import '../../../core/consequences/retos_filter.dart';
import '../../../core/content/prompts.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../race_result.dart';

const _retosAsset = 'assets/content/es/retos.json';

class RaceResultScreen extends ConsumerStatefulWidget {
  const RaceResultScreen({super.key});

  @override
  ConsumerState<RaceResultScreen> createState() => _RaceResultScreenState();
}

class _RaceResultScreenState extends ConsumerState<RaceResultScreen> {
  @override
  void initState() {
    super.initState();
    // Sin All-in ganadores no hay nada que elegir: las fichas pasan a la Copa al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _settle();
    });
  }

  /// Otros jugadores a los que puede repartir [playerId] su All-in.
  List<Player> _pool(List<Player> players, String playerId) =>
      [for (final p in players) if (p.id != playerId) p];

  /// Envía las fichas de esta carrera a la Copa, una sola vez (el `roundId` evita duplicados).
  /// Si [force] es falso y hay All-in ganadores sin repartir, espera: la elección se puede
  /// cambiar hasta que se sale de la pantalla (entonces se llama con `force`).
  void _settle({bool force = false}) {
    final r = ref.read(lastRaceResultProvider);
    if (r == null || r.settled) return;
    final players = ref.read(playersProvider);
    final ids = {for (final p in players) p.id};
    final outcomes = [for (final o in r.outcomes) if (ids.contains(o.bet.playerId)) o];
    if (!force) {
      for (final o in outcomes) {
        if (!(o.won && o.isAllIn)) continue;
        final pool = _pool(players, o.bet.playerId).map((p) => p.id).toSet();
        final chosen = (r.allInTargets[o.bet.playerId] ?? const <String>{}).intersection(pool);
        if (chosen.length < allInTargetCount(pool.length)) return;
      }
    }
    final s = settleChips(outcomes, r.allInTargets);
    ref.read(sessionProvider.notifier).award(r.roundId, 'carrera', {
      for (final e in s.deltas.entries)
        if (ids.contains(e.key)) e.key: e.value,
    });
    ref.read(lastRaceResultProvider.notifier).markSettled();
  }

  void _toggleTarget(RaceResult r, Player winner, Player target, int max) {
    final current = {...(r.allInTargets[winner.id] ?? const <String>{})};
    if (!current.remove(target.id)) {
      if (current.length >= max) return;
      current.add(target.id);
    }
    ref.read(lastRaceResultProvider.notifier).setTargets(winner.id, current);
  }

  void _leave(VoidCallback navigate) {
    _settle(force: true);
    navigate();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(lastRaceResultProvider);
    if (result == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No hay ninguna carrera terminada')),
      );
    }
    final players = ref.watch(playersProvider);
    final byId = {for (final p in players) p.id: p};
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    final adult = ref.watch(settingsProvider.select((s) => s.adultConfirmed));
    final retosPrompts = ref.watch(promptsProvider(_retosAsset)).asData?.value;
    final retos = retosPrompts == null ? null : filterRetos(retosPrompts, adultConfirmed: adult);

    final known = [for (final o in result.outcomes) if (byId.containsKey(o.bet.playerId)) o];
    final winners = known.where((o) => o.won).toList();
    final settlement = settleChips(known, result.allInTargets);
    final losses = <String, int>{
      for (final e in settlement.losses.entries)
        if (byId[e.key] case final p?) p.name: e.value,
    };

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _settle(force: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultado'),
          leading: IconButton(
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _leave(() => context.go('/')),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              _Podium(standings: result.standings),
              const SizedBox(height: 8),
              Text('${result.draws} cartas sacadas',
                  textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              if (winners.isNotEmpty) ...[
                const _SectionHeader(title: '🎉 Reparten', color: AppColors.success),
                for (final o in winners)
                  _WinnerCard(
                    outcome: o,
                    player: byId[o.bet.playerId]!,
                    pool: _pool(players, o.bet.playerId),
                    targets: result.allInTargets[o.bet.playerId] ?? const {},
                    locked: result.settled,
                    onToggle: (target, max) =>
                        _toggleTarget(result, byId[o.bet.playerId]!, target, max),
                  ),
              ],
              if (losses.isNotEmpty) ...[
                const _SectionHeader(title: '💸 Pagan', color: AppColors.danger),
                ConsequenceBanner(losses: losses, mode: mode, retos: retos),
              ],
              if (winners.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Nadie acertó. ¡Todos pagan!', textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _leave(() => context.go('/game/carrera')),
                  child: const Text('Cambiar apuestas'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _leave(() => context.pushReplacement('/game/carrera/race')),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Revancha'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      );
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

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({
    required this.outcome,
    required this.player,
    required this.pool,
    required this.targets,
    required this.locked,
    required this.onToggle,
  });

  final BetOutcome outcome;
  final Player player;
  final List<Player> pool;
  final Set<String> targets;
  final bool locked;
  final void Function(Player target, int max) onToggle;

  @override
  Widget build(BuildContext context) {
    final bet = outcome.bet;
    final max = allInTargetCount(pool.length);
    final chosen = targets.where((id) => pool.any((p) => p.id == id)).length;
    final betText = bet.isAllIn ? 'All-in' : (bet.chips == 1 ? '1 ficha' : '${bet.chips} fichas');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: PlayerAvatar(player),
              title: Text(player.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Apostó $betText a ${bet.suit.label}'),
              trailing: Text(
                outcome.label,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.success),
              ),
            ),
            if (outcome.isAllIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      max == 0
                          ? 'No hay a quién repartir los All-in.'
                          : 'Reparte un All-in a $max ${max == 1 ? "persona" : "personas distintas"} ($chosen/$max)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (max > 0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in pool)
                            FilterChip(
                              avatar: PlayerAvatar(p, size: 24),
                              label: Text(p.name),
                              selected: targets.contains(p.id),
                              showCheckmark: false,
                              onSelected: locked || (!targets.contains(p.id) && chosen >= max)
                                  ? null
                                  : (_) => onToggle(p, max),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
