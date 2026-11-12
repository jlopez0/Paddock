import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/widgets/effects.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../domain/race_engine.dart';
import '../race_result.dart';
import '../race_store.dart';

const _cardAspect = 300 / 460;

class RaceScreen extends ConsumerStatefulWidget {
  const RaceScreen({super.key});

  @override
  ConsumerState<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends ConsumerState<RaceScreen> {
  late final RaceSetup _setup = ref.read(raceSetupProvider);
  late final RaceEngine _engine = RaceEngine(config: _setup.settings.config);

  /// Posiciones que se muestran (van "por detrás" del motor para animar paso a paso).
  final Map<Suit, int> _pos = {for (final s in Suit.values) s: 0};
  int _revealed = 0;
  PlayingCard? _lastCard;
  String? _message;
  Suit? _bumped;
  Suit? _winner;
  bool _busy = false;
  bool _auto = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _wait(int ms) => Future.delayed(Duration(milliseconds: ms));

  Future<void> _draw() async {
    if (_busy || _winner != null) return;
    _busy = true;
    for (final ev in _engine.draw()) {
      if (!mounted) return;
      switch (ev) {
        case DeckReshuffled():
          setState(() => _message = 'Mazo agotado: se baraja de nuevo');
          await _wait(700);
        case HorseAdvanced(:final card):
          HapticFeedback.selectionClick();
          setState(() {
            _lastCard = card;
            _pos[card.suit] = _pos[card.suit]! + 1;
            _message = null;
            _bumped = null;
          });
          await _wait(450);
        case ObstacleRevealed(:final card):
          HapticFeedback.mediumImpact();
          setState(() {
            _revealed++;
            _message = '¡Obstáculo! ${card.suit.label} retrocede';
          });
          await _wait(700);
          if (!mounted) return;
          setState(() {
            _pos[card.suit] = max(0, _pos[card.suit]! - 1);
            _bumped = card.suit;
          });
          await _wait(500);
        case HorseWon(:final suit):
          HapticFeedback.heavyImpact();
          _finish(suit);
      }
    }
    _busy = false;
    if (_auto && _winner == null && mounted) {
      await _wait(250);
      if (_auto && mounted) unawaited(_draw());
    }
  }

  void _finish(Suit winner) {
    final outcomes = settleBets(_setup.bets, winner, winMultiplier: _setup.settings.winMultiplier);
    ref.read(raceStatsProvider.notifier).record(winner, outcomes);
    ref.read(lastRaceResultProvider.notifier).set(RaceResult(
          winner: winner,
          standings: _engine.standings,
          outcomes: outcomes,
          draws: _engine.draws,
        ));
    setState(() {
      _winner = winner;
      _auto = false;
      _message = null;
    });
  }

  void _toggleAuto() {
    setState(() => _auto = !_auto);
    if (_auto) _draw();
  }

  Future<void> _exit() async {
    if (_winner != null || _engine.draws == 0) {
      context.pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Abandonar la carrera?'),
        content: const Text('No contará para las estadísticas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final players = {for (final p in ref.watch(playersProvider)) p.id: p};
    final bettors = <Suit, List<Player>>{
      for (final s in Suit.values)
        s: [
          for (final b in _setup.bets)
            if (b.suit == s && players[b.playerId] != null) players[b.playerId]!,
        ],
    };
    final leaderPos = _pos.values.reduce(max);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.6),
              radius: 1.4,
              colors: [Color(0xFF1A3324), AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _Track(
                          length: _engine.config.length,
                          positions: _pos,
                          obstacles: _engine.obstacles,
                          revealed: _revealed,
                          bettors: bettors,
                          leaderPos: leaderPos,
                          bumped: _bumped,
                          winner: _winner,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SidePanel(
                        lastCard: _lastCard,
                        deckCount: _engine.deckCount,
                        auto: _auto,
                        enabled: _winner == null,
                        onDraw: _draw,
                        onToggleAuto: _toggleAuto,
                        onExit: _exit,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 0,
                  right: 160,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(a),
                          child: c,
                        ),
                      ),
                      child: _message == null
                          ? const SizedBox.shrink()
                          : Container(
                              key: ValueKey(_message),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black54)],
                              ),
                              child: Text(_message!, style: const TextStyle(fontWeight: FontWeight.w800)),
                            ),
                    ),
                  ),
                ),
                if (_winner != null) _WinnerOverlay(winner: _winner!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.length,
    required this.positions,
    required this.obstacles,
    required this.revealed,
    required this.bettors,
    required this.leaderPos,
    required this.bumped,
    required this.winner,
  });

  final int length;
  final Map<Suit, int> positions;
  final List<PlayingCard> obstacles;
  final int revealed;
  final Map<Suit, List<Player>> bettors;
  final int leaderPos;
  final Suit? bumped;
  final Suit? winner;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      const labelW = 86.0;
      const gap = 6.0;
      final cols = length + 1; // salida + casillas + meta
      final cellW = (box.maxWidth - labelW) / cols;
      // 4 calles + fila de obstáculos (algo más baja).
      final laneH = (box.maxHeight - gap * 4) / 4.85;
      final cardH = min(laneH - 8, (cellW - 8) / _cardAspect);
      final cardW = cardH * _cardAspect;
      final obstacleH = laneH * 0.85;
      final obsCardH = min(obstacleH - 6, cardH);

      return Column(
        children: [
          SizedBox(
            height: obstacleH,
            child: Row(
              children: [
                const SizedBox(width: labelW),
                SizedBox(width: cellW),
                for (var i = 0; i < length - 1; i++)
                  SizedBox(
                    width: cellW,
                    child: Center(
                      child: i < obstacles.length
                          ? SizedBox(
                              height: obsCardH,
                              width: obsCardH * _cardAspect,
                              child: FlipCard(
                                revealed: i < revealed,
                                back: _CardImage(PlayingCard.backAsset),
                                front: _CardImage(obstacles[i].asset),
                              ),
                            )
                          : null,
                    ),
                  ),
                SizedBox(width: cellW),
              ],
            ),
          ),
          for (final s in Suit.values) ...[
            const SizedBox(height: gap),
            SizedBox(
              height: laneH,
              child: Row(
                children: [
                  SizedBox(width: labelW, child: _LaneLabel(suit: s, bettors: bettors[s]!)),
                  Expanded(
                    child: _Lane(
                      suit: s,
                      cols: cols,
                      cellW: cellW,
                      cardW: cardW,
                      cardH: cardH,
                      position: positions[s]!,
                      leading: leaderPos > 0 && positions[s] == leaderPos,
                      bumped: bumped == s,
                      winner: winner == s,
                      dimmed: winner != null && winner != s,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _LaneLabel extends StatelessWidget {
  const _LaneLabel({required this.suit, required this.bettors});

  final Suit suit;
  final List<Player> bettors;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(suit.label.toUpperCase(),
            style: TextStyle(color: suit.color, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
        if (bettors.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            height: 22,
            child: Stack(
              children: [
                for (var i = 0; i < min(bettors.length, 4); i++)
                  Positioned(left: i * 14.0, child: PlayerAvatar(bettors[i], size: 22)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.suit,
    required this.cols,
    required this.cellW,
    required this.cardW,
    required this.cardH,
    required this.position,
    required this.leading,
    required this.bumped,
    required this.winner,
    required this.dimmed,
  });

  final Suit suit;
  final int cols;
  final double cellW, cardW, cardH;
  final int position;
  final bool leading, bumped, winner, dimmed;

  @override
  Widget build(BuildContext context) {
    final glow = leading || winner;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: dimmed ? 0.4 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: [
            suit.color.withValues(alpha: 0.22),
            suit.color.withValues(alpha: 0.06),
          ]),
          border: Border.all(color: glow ? suit.color : suit.color.withValues(alpha: 0.25), width: glow ? 2 : 1),
          boxShadow: glow ? [BoxShadow(color: suit.color.withValues(alpha: 0.35), blurRadius: 14)] : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Separadores de casilla y meta.
            for (var c = 1; c < cols; c++)
              Positioned(
                left: c * cellW,
                top: 6,
                bottom: 6,
                child: Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),
              ),
            Positioned(
              left: (cols - 1) * cellW,
              top: 0,
              bottom: 0,
              width: cellW,
              child: const _FinishLine(),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: bumped ? Curves.easeOutCubic : Curves.easeOutBack,
              left: position * cellW + (cellW - cardW) / 2,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 300),
                  scale: winner ? 1.15 : 1,
                  child: Container(
                    width: cardW,
                    height: cardH,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (bumped ? AppColors.danger : Colors.black).withValues(alpha: 0.55),
                          blurRadius: bumped ? 14 : 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: _CardImage(PlayingCard.horseAsset(suit)),
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

class _FinishLine extends StatelessWidget {
  const _FinishLine();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(13)),
      child: Opacity(
        opacity: 0.18,
        child: CustomPaint(painter: _CheckerPainter()),
      ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const s = 10.0;
    final p = Paint()..color = Colors.white;
    for (var y = 0.0; y < size.height; y += s) {
      for (var x = 0.0; x < size.width; x += s) {
        if (((x + y) / s).round().isEven) canvas.drawRect(Rect.fromLTWH(x, y, s, s), p);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => false;
}

class _CardImage extends StatelessWidget {
  const _CardImage(this.asset);
  final String asset;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(asset, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
      );
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.lastCard,
    required this.deckCount,
    required this.auto,
    required this.enabled,
    required this.onDraw,
    required this.onToggleAuto,
    required this.onExit,
  });

  final PlayingCard? lastCard;
  final int deckCount;
  final bool auto, enabled;
  final VoidCallback onDraw, onToggleAuto, onExit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: LayoutBuilder(builder: (context, box) {
        final cardH = min(box.maxHeight * 0.42, 140 / _cardAspect * 0.8);
        final cardW = cardH * _cardAspect;
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  tooltip: auto ? 'Pausar' : 'Automático',
                  onPressed: enabled ? onToggleAuto : null,
                  icon: Icon(auto ? Icons.pause_rounded : Icons.fast_forward_rounded),
                ),
                IconButton.filledTonal(
                  tooltip: 'Salir',
                  onPressed: onExit,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Spacer(),
            // Última carta sacada.
            SizedBox(
              height: cardH,
              width: cardW,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, a) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.6), end: Offset.zero)
                      .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: lastCard == null
                    ? DecoratedBox(
                        key: const ValueKey('empty'),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.outline, width: 2),
                        ),
                        child: const Center(
                          child: Text('Toca el mazo', textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ),
                      )
                    : Container(
                        key: ValueKey(lastCard),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: lastCard!.suit.color.withValues(alpha: 0.6), blurRadius: 16)],
                        ),
                        child: _CardImage(lastCard!.asset),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            // Mazo.
            GestureDetector(
              onTap: enabled && !auto ? onDraw : null,
              child: SizedBox(
                height: cardH,
                width: cardW + 8,
                child: Stack(
                  children: [
                    for (var i = 0; i < min(3, deckCount); i++)
                      Positioned(
                        left: i * 4.0,
                        top: (2 - i) * 3.0,
                        child: SizedBox(
                          height: cardH - 6,
                          width: cardW - 4,
                          child: _CardImage(PlayingCard.backAsset),
                        ),
                      ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$deckCount',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        );
      }),
    );
  }
}

class _WinnerOverlay extends StatelessWidget {
  const _WinnerOverlay({required this.winner});

  final Suit winner;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: Colors.black.withValues(alpha: 0.65))),
            Positioned.fill(child: Confetti(colors: [winner.color, AppColors.gold, Colors.white])),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, s, child) => Transform.scale(scale: s, child: child),
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: winner.color.withValues(alpha: 0.7), blurRadius: 40)],
                      ),
                      child: _CardImage(PlayingCard.horseAsset(winner)),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🏆 ¡GANA!', style: TextStyle(fontSize: 18, color: AppColors.textMuted)),
                      Text(winner.label,
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: winner.color)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.pushReplacement('/game/carrera/result'),
                        icon: const Icon(Icons.local_bar_rounded),
                        label: const Text('¿Quién bebe?'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
