import 'package:confetti/confetti.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../../core/consequences/consequence_banner.dart';
import '../../../core/consequences/consequences.dart';
import '../../../core/consequences/retos_filter.dart';
import '../../../core/content/prompts.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../race_result.dart';
import '../race_texts.dart';
import 'race_widgets.dart';

const _retosAsset = 'assets/content/es/retos.json';

class RaceResultScreen extends ConsumerStatefulWidget {
  const RaceResultScreen({super.key});

  @override
  ConsumerState<RaceResultScreen> createState() => _RaceResultScreenState();
}

class _RaceResultScreenState extends ConsumerState<RaceResultScreen> {
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    // Sin All-in ganadores no hay nada que elegir: las fichas pasan a la Copa al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _settle();
      _celebrate();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Confeti y vibración solo si hay algún ganador y el sistema no pide menos animación.
  void _celebrate() {
    final r = ref.read(lastRaceResultProvider);
    if (r == null || !r.outcomes.any((o) => o.won)) return;
    AppFeedback.medium();
    if (MediaQuery.disableAnimationsOf(context)) return;
    _confetti.play();
  }

  /// Otros jugadores a los que puede repartir [playerId] su All-in.
  List<Player> _pool(List<Player> players, String playerId) => [
    for (final p in players)
      if (p.id != playerId) p,
  ];

  /// Envía las fichas de esta carrera a la Copa, una sola vez (el `roundId` evita duplicados).
  /// Si [force] es falso y hay All-in ganadores sin repartir, espera: la elección se puede
  /// cambiar hasta que se sale de la pantalla (entonces se llama con `force`).
  void _settle({bool force = false}) {
    final r = ref.read(lastRaceResultProvider);
    if (r == null || r.settled) return;
    final players = ref.read(playersProvider);
    final ids = {for (final p in players) p.id};
    final outcomes = [
      for (final o in r.outcomes)
        if (ids.contains(o.bet.playerId)) o,
    ];
    if (!force) {
      for (final o in outcomes) {
        if (!(o.won && o.isAllIn)) continue;
        final pool = _pool(players, o.bet.playerId).map((p) => p.id).toSet();
        final chosen = (r.allInTargets[o.bet.playerId] ?? const <String>{})
            .intersection(pool);
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
      playSound(AppSound.chipSoft);
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
        body: const SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Aún no ha cruzado nadie la meta',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      );
    }
    final players = ref.watch(playersProvider);
    final byId = {for (final p in players) p.id: p};
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    final adult = ref.watch(settingsProvider.select((s) => s.adultConfirmed));
    final retosPrompts = ref.watch(promptsProvider(_retosAsset)).asData?.value;
    final retos = retosPrompts == null
        ? null
        : filterRetos(retosPrompts, adultConfirmed: adult);

    final known = [
      for (final o in result.outcomes)
        if (byId.containsKey(o.bet.playerId)) o,
    ];
    final winners = known.where((o) => o.won).toList();
    final settlement = settleChips(known, result.allInTargets);
    final losses = <String, int>{
      for (final e in settlement.losses.entries)
        if (e.value > 0 && byId.containsKey(e.key)) e.key: e.value,
    };
    // Por qué paga cada uno: lo que apostó y falló, o el All-in que le reparten.
    final reasons = <String, List<String>>{};
    for (final o in known) {
      if (!o.won) {
        (reasons[o.bet.playerId] ??= []).add(
          'Apostó ${betText(o.bet)} a ${o.bet.suit.label} y falló',
        );
      } else if (o.isAllIn) {
        final pool = _pool(players, o.bet.playerId).map((p) => p.id).toSet();
        final chosen = (result.allInTargets[o.bet.playerId] ?? const <String>{})
            .intersection(pool);
        for (final t in chosen.take(o.allIns)) {
          (reasons[t] ??= []).add(
            'Le reparte un All-in ${byId[o.bet.playerId]!.name}',
          );
        }
      }
    }
    final lossesByName = {
      for (final e in losses.entries) byId[e.key]!.name: e.value,
    };
    final gainsByName = {
      for (final w in winners)
        if ((settlement.deltas[w.bet.playerId] ?? 0) > 0)
          byId[w.bet.playerId]!.name: settlement.deltas[w.bet.playerId]!,
    };
    final outcomeByPlayer = {for (final o in known) o.bet.playerId: o};

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _settle(force: true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Carrera de caballos'),
          leading: IconButton(
            tooltip: 'Cerrar',
            icon: AppIcon.close.widget(),
            onPressed: () => _leave(() => context.go('/')),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    _Podium(standings: result.standings),
                    const SizedBox(height: 8),
                    Text(
                      '${result.draws} cartas sacadas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    if (winners.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: AppIcon.confetti,
                        title: 'Cobran',
                        color: AppColors.success,
                      ),
                      for (final (i, o) in winners.indexed)
                        _WinnerTicket(
                          outcome: o,
                          player: byId[o.bet.playerId]!,
                          pool: _pool(players, o.bet.playerId),
                          targets:
                              result.allInTargets[o.bet.playerId] ?? const {},
                          locked: result.settled,
                          mode: mode,
                          stampDelayMs: 150 * i,
                          onToggle: (target, max) => _toggleTarget(
                            result,
                            byId[o.bet.playerId]!,
                            target,
                            max,
                          ),
                        ),
                      if (gainsByName.isNotEmpty)
                        Text(
                          chipsLine('Cobran', gainsByName, gain: true),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                    if (losses.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: AppIcon.coins,
                        title: 'Pagan',
                        color: AppColors.danger,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          chipsLine('Pagan', lossesByName, gain: false),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      _Payers(
                        losses: losses,
                        players: byId,
                        outcomes: outcomeByPlayer,
                        reasons: reasons,
                        mode: mode,
                        retos: retos,
                      ),
                    ],
                    if (winners.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Nadie acertó. Pagan todos.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              // Confeti solo con ganador; capa propia para no repintar la lista.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConfettiWidget(
                          confettiController: _confetti,
                          blastDirectionality: BlastDirectionality.explosive,
                          shouldLoop: false,
                          numberOfParticles: 14,
                          maxBlastForce: 22,
                          minBlastForce: 8,
                          gravity: 0.25,
                          colors: const [
                            AppColors.gold,
                            AppColors.success,
                            AppColors.paper,
                            AppColors.burgundy,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
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
                  onPressed: () => _leave(
                    () => context.pushReplacement('/game/carrera/race'),
                  ),
                  icon: AppIcon.replay.widget(color: Colors.black),
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
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final AppIcon icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Row(
      children: [
        icon.widget(size: 28),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Podium extends StatelessWidget {
  const _Podium({required this.standings});

  final List<Suit> standings;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
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
                      tween: Tween(begin: reduce ? 1 : 0, end: 1),
                      duration: reduce
                          ? Duration.zero
                          : Duration(milliseconds: 500 + 200 * i),
                      curve: Curves.easeOutBack,
                      builder: (c, t, child) =>
                          Transform.scale(scale: t, child: child),
                      child: Image.asset(
                        PlayingCard.horseAsset(standings[order[i]]),
                        height: order[i] == 0 ? 130 : 95,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: heights[i],
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: standings[order[i]].color.withValues(
                          alpha: 0.25,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        border: Border.all(color: standings[order[i]].color),
                      ),
                      child: MedalIcon(order[i] + 1, size: 36),
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

/// Boleto de quien acierta: palo, apuesta y sello "COBRA". Si es All-in, también
/// la elección de a quién reparte.
class _WinnerTicket extends StatelessWidget {
  const _WinnerTicket({
    required this.outcome,
    required this.player,
    required this.pool,
    required this.targets,
    required this.locked,
    required this.mode,
    required this.onToggle,
    required this.stampDelayMs,
  });

  final BetOutcome outcome;
  final Player player;
  final List<Player> pool;
  final Set<String> targets;
  final bool locked;
  final ConsequenceMode mode;
  final int stampDelayMs;
  final void Function(Player target, int max) onToggle;

  @override
  Widget build(BuildContext context) {
    final bet = outcome.bet;
    final max = allInTargetCount(pool.length);
    final chosen = targets.where((id) => pool.any((p) => p.id == id)).length;
    final title = outcome.isAllIn
        ? '${player.name} reparte ${allInCountText(outcome.allIns)}'
        : '${player.name} cobra ${chipsText(outcome.chips)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TicketCard(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        stub: InkText(
          child: Row(
            children: [
              RaceChip(outcome.chips, allIn: outcome.isAllIn, size: 40),
              const Spacer(),
              RaceStamp.cobra(delayMs: stampDelayMs),
            ],
          ),
        ),
        child: InkText(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PlayerAvatar(player),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Apostó ${betText(bet)} a ${bet.suit.label}',
                          style: TextStyle(
                            color: raceInk.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Image.asset(
                    PlayingCard.horseAsset(bet.suit),
                    height: 44,
                    excludeFromSemantics: true,
                  ),
                ],
              ),
              if (outcome.isAllIn)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(color: AppColors.text),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          max == 0
                              ? 'No hay a quién repartir los All-in.'
                              : '${allInShareText(mode, max)} ($chosen/$max)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          allInCupNote,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
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
                                  onSelected:
                                      locked ||
                                          (!targets.contains(p.id) &&
                                              chosen >= max)
                                      ? null
                                      : (_) => onToggle(p, max),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quién paga y por qué, un boleto por jugador con el sello "PAGA". Misma lógica que
/// `ConsequenceBanner`, más el motivo y, en retos y sorbos, una línea aparte con lo que se
/// registra en la Copa. No hay transferencias entre jugadores.
class _Payers extends StatelessWidget {
  const _Payers({
    required this.losses,
    required this.players,
    required this.outcomes,
    required this.reasons,
    required this.mode,
    required this.retos,
  });

  final Map<String, int> losses;
  final Map<String, Player> players;
  final Map<String, BetOutcome> outcomes;
  final Map<String, List<String>> reasons;
  final ConsequenceMode mode;
  final List<String>? retos;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pool = (retos == null || retos!.isEmpty) ? kFallbackRetos : retos!;
    var retoIndex = 0;
    var stampIndex = 0;
    final rows = <Widget>[];
    for (final e in losses.entries) {
      final loss = resolveLoss(e.value, mode);
      if (loss.amount == 0) continue;
      final reto = mode == ConsequenceMode.retos
          ? pool[retoIndex++ % pool.length]
          : null;
      final cup = cupLineFor(mode, e.value);
      final why = reasons[e.key]?.join(' · ');
      final player = players[e.key];
      final outcome = outcomes[e.key];
      final lostAllIn =
          outcome != null &&
          !outcome.won &&
          outcome.isAllIn &&
          e.value == kAllInChips;
      final muted = TextStyle(
        color: raceInk.withValues(alpha: 0.72),
        fontSize: 13,
      );
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TicketCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            stub: InkText(
              child: Row(
                children: [
                  RaceChip(e.value, allIn: lostAllIn, size: 40),
                  const Spacer(),
                  RaceStamp.paga(delayMs: 150 * stampIndex++),
                ],
              ),
            ),
            child: InkText(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (player != null) ...[
                    PlayerAvatar(player),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                player?.name ?? '',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: raceInk,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                ConsequenceBanner.amountText(loss),
                                textAlign: TextAlign.end,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: raceInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (why != null) Text(why, style: muted),
                        if (reto != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            reto,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: raceInk,
                            ),
                          ),
                        ],
                        if (cup != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(cup, style: muted),
                          ),
                      ],
                    ),
                  ),
                  if (outcome != null) ...[
                    const SizedBox(width: 8),
                    Image.asset(
                      PlayingCard.horseAsset(outcome.bet.suit),
                      height: 44,
                      excludeFromSemantics: true,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}
