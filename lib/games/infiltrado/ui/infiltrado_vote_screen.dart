import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../prompt_deck/game_colors.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import '../infiltrado_store.dart';
import 'infiltrado_widgets.dart';

enum _Phase { debate, cover, pick, runoff }

/// Debate (con temporizador opcional) y votación secreta pasando el móvil.
class InfiltradoVoteScreen extends ConsumerStatefulWidget {
  const InfiltradoVoteScreen({super.key});

  @override
  ConsumerState<InfiltradoVoteScreen> createState() =>
      _InfiltradoVoteScreenState();
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
      playSound(AppSound.tap);
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
    final caught =
        result.accused != null && game.deal.impostors.contains(result.accused);
    // Si lo pillan, el infiltrado tiene aún su última oportunidad en la pantalla de resultado.
    if (!caught) controller.finish();
    context.pushReplacement('/game/infiltrado/result');
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(infiltradoGameProvider);
    if (game == null) return const InfiltradoNoGame();
    final byId = {for (final p in ref.watch(playersProvider)) p.id: p};
    Player playerOf(String id) =>
        byId[id] ?? Player(id: id, name: '?', colorIndex: 0);

    final Widget body;
    switch (_phase) {
      case _Phase.debate:
        body = _Debate(remaining: _remaining, onDone: _startVoting);
      case _Phase.runoff:
        final names = [
          for (final id in game.round.runoffCandidates ?? <String>{})
            playerOf(id).name,
        ];
        body = InfiltradoBody(
          footer: FilledButton(
            onPressed: () => setState(() => _phase = _Phase.cover),
            child: const Text('Segunda votación'),
          ),
          children: [
            Center(
              child: AppIcon.scales.widget(size: 56, semanticLabel: 'Empate'),
            ),
            const SizedBox(height: 12),
            const SlabText('¡Empate!', size: 30),
            const SizedBox(height: 8),
            Text(
              'Se vuelve a votar solo entre ${names.join(' y ')}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: GameColors.mutedText, fontSize: 16),
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
        final candidates =
            game.round.runoffCandidates ?? game.deal.players.toSet();
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                InfiltradoTopBar(
                  title: _phase == _Phase.debate ? 'Debate' : 'Votación',
                ),
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
      footer: FilledButton(onPressed: onDone, child: const Text('A votar')),
      children: [
        Semantics(
          liveRegion: over,
          label: over ? 'Se acabó el tiempo' : 'Tiempo restante $time',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
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
        ),
        const SizedBox(height: 16),
        const Text(
          'Una pista por cabeza, sin decir la palabra. '
          'Descubrid quién va de farol.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GameColors.mutedText, fontSize: 16),
        ),
      ],
    );
  }
}

/// Papeleta de voto: papel con la casilla a marcar. Al elegirla aparece la
/// cruz en burdeos y el borde se engrosa.
class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.player,
    required this.selected,
    required this.onTap,
  });

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
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.paper,
          border: Border.all(
            color: selected ? AppColors.burgundy : AppColors.brass,
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Row(
          children: [
            PlayerAvatar(player, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: infiltradoInk,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(painter: _BallotBoxPainter(marked: selected)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Casilla de la papeleta; marcada lleva una cruz burdeos.
class _BallotBoxPainter extends CustomPainter {
  const _BallotBoxPainter({required this.marked});

  final bool marked;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(4),
    );
    canvas.drawRRect(
      box,
      Paint()
        ..color = AppColors.brass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    if (!marked) return;
    final x = Paint()
      ..color = AppColors.burgundy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const m = 7.0;
    canvas.drawLine(
      const Offset(m, m),
      Offset(size.width - m, size.height - m),
      x,
    );
    canvas.drawLine(Offset(size.width - m, m), Offset(m, size.height - m), x);
  }

  @override
  bool shouldRepaint(_BallotBoxPainter old) => old.marked != marked;
}
