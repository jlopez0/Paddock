import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/settings/app_feedback.dart';
import '../infiltrado_store.dart';
import 'infiltrado_widgets.dart';

enum _Phase { debate, cover, pick, runoff }

/// Debate (con temporizador opcional) y votación secreta pasando el móvil.
class InfiltradoVoteScreen extends ConsumerStatefulWidget {
  const InfiltradoVoteScreen({super.key});

  @override
  ConsumerState<InfiltradoVoteScreen> createState() => _InfiltradoVoteScreenState();
}

class _InfiltradoVoteScreenState extends ConsumerState<InfiltradoVoteScreen> {
  late _Phase _phase;
  Timer? _timer;
  int _remaining = 0;

  int _voter = 0;
  String? _selected;
  final Map<String, String> _votes = {};

  @override
  void initState() {
    super.initState();
    final seconds = ref.read(infiltradoGameProvider)?.debateSeconds ?? 0;
    if (seconds > 0) {
      _phase = _Phase.debate;
      _remaining = seconds;
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    } else {
      _phase = _Phase.cover;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer t) {
    if (!mounted) return;
    setState(() => _remaining--);
    if (_remaining <= 0) {
      t.cancel();
      AppFeedback.heavy();
    }
  }

  void _startVoting() {
    _timer?.cancel();
    setState(() => _phase = _Phase.cover);
  }

  void _confirm(InfiltradoGame game) {
    final target = _selected;
    if (target == null) return;
    AppFeedback.light();
    _votes[game.deal.players[_voter]] = target;
    if (_voter < game.deal.players.length - 1) {
      setState(() {
        _voter++;
        _selected = null;
        _phase = _Phase.cover;
      });
      return;
    }
    final result = game.round.vote(Map.of(_votes));
    if (result.needsRunoff) {
      setState(() {
        _voter = 0;
        _selected = null;
        _votes.clear();
        _phase = _Phase.runoff;
      });
      return;
    }
    final controller = ref.read(infiltradoGameProvider.notifier);
    controller.setLastVote(result);
    final caught = result.accused != null && game.deal.impostors.contains(result.accused);
    // Si lo pillan, el infiltrado tiene aún su última oportunidad en la pantalla de resultado.
    if (!caught) controller.finish();
    context.pushReplacement('/game/infiltrado/result');
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(infiltradoGameProvider);
    if (game == null) return const InfiltradoNoGame();
    final byId = {for (final p in ref.watch(playersProvider)) p.id: p};
    Player playerOf(String id) => byId[id] ?? Player(id: id, name: '?', colorIndex: 0);

    final Widget body;
    switch (_phase) {
      case _Phase.debate:
        body = _Debate(remaining: _remaining, onDone: _startVoting);
      case _Phase.runoff:
        final names = [for (final id in game.round.runoffCandidates ?? <String>{}) playerOf(id).name];
        body = InfiltradoBody(
          footer: FilledButton(
            onPressed: () => setState(() => _phase = _Phase.cover),
            child: const Text('Segunda votación'),
          ),
          children: [
            const Text('⚖️', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text(
              '¡Empate!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Se vuelve a votar solo entre ${names.join(' y ')}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        );
      case _Phase.cover:
        final voter = playerOf(game.deal.players[_voter]);
        body = PassPhoneCover(
          player: voter,
          heading: 'Voto secreto: pasa el móvil a',
          progress: 'Voto ${_voter + 1} de ${game.deal.players.length}',
          buttonLabel: 'Soy ${voter.name}, votar',
          onContinue: () => setState(() => _phase = _Phase.pick),
        );
      case _Phase.pick:
        final voterId = game.deal.players[_voter];
        final candidates = game.round.runoffCandidates ?? game.deal.players.toSet();
        final targets = [
          for (final id in game.deal.players)
            if (id != voterId && candidates.contains(id)) playerOf(id),
        ];
        body = InfiltradoBody(
          footer: FilledButton(
            onPressed: _selected == null ? null : () => _confirm(game),
            child: const Text('Confirmar voto'),
          ),
          children: [
            Text(
              '${playerOf(voterId).name}, ¿quién es el infiltrado?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            for (final t in targets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TargetTile(
                  player: t,
                  selected: _selected == t.id,
                  onTap: () {
                    AppFeedback.selection();
                    setState(() => _selected = t.id);
                  },
                ),
              ),
          ],
        );
    }

    return InfiltradoLeaveGuard(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                InfiltradoTopBar(title: _phase == _Phase.debate ? 'Debate' : 'Votación'),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Debate extends StatelessWidget {
  const _Debate({required this.remaining, required this.onDone});

  final int remaining;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final secs = remaining < 0 ? 0 : remaining;
    final time = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final over = remaining <= 0;
    return InfiltradoBody(
      footer: FilledButton(onPressed: onDone, child: const Text('Pasar a votar')),
      children: [
        Semantics(
          liveRegion: over,
          label: over ? 'Se acabó el tiempo' : 'Tiempo restante $time',
          excludeSemantics: true,
          child: Text(
            over ? '¡Tiempo!' : time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w900,
              color: over ? AppColors.danger : AppColors.text,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Cada uno da una pista sobre la palabra sin decirla. '
          'Descubrid quién no la conoce.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
      ],
    );
  }
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({required this.player, required this.selected, required this.onTap});

  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Votar a ${player.name}',
    excludeSemantics: true,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? player.color.withValues(alpha: 0.18) : AppColors.surface,
          border: Border.all(color: selected ? player.color : AppColors.outline, width: 2),
        ),
        child: Row(
          children: [
            PlayerAvatar(player, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: player.color),
          ],
        ),
      ),
    ),
  );
}
