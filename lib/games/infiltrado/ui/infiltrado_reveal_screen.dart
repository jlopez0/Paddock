import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import '../domain/infiltrado_engine.dart';
import '../infiltrado_store.dart';
import 'infiltrado_widgets.dart';

/// Pasa el móvil de mano en mano: cada jugador ve en privado su tarjeta.
/// La palabra solo se pinta tras pulsar "ver mi tarjeta" y desaparece al pasar.
class InfiltradoRevealScreen extends ConsumerStatefulWidget {
  const InfiltradoRevealScreen({super.key});

  @override
  ConsumerState<InfiltradoRevealScreen> createState() =>
      _InfiltradoRevealScreenState();
}

class _InfiltradoRevealScreenState
    extends ConsumerState<InfiltradoRevealScreen> {
  int _index = 0;
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(infiltradoGameProvider);
    if (game == null) return const InfiltradoNoGame();
    final deal = game.deal;
    final all = ref.watch(playersProvider);
    final byId = {for (final p in all) p.id: p};
    final id = deal.players[_index];
    final player = byId[id] ?? Player(id: id, name: '?', colorIndex: 0);
    final last = _index == deal.players.length - 1;

    void next() {
      AppFeedback.light();
      playSound(AppSound.tap);
      if (last) {
        context.pushReplacement('/game/infiltrado/vote');
        return;
      }
      setState(() {
        _index++;
        _shown = false;
      });
    }

    return InfiltradoLeaveGuard(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                InfiltradoTopBar(
                  title: 'Roles',
                  trailing: '${_index + 1}/${deal.players.length}',
                ),
                Expanded(
                  child: _shown
                      ? _CardView(
                          player: player,
                          card: deal.cardFor(id),
                          buttonLabel: last
                              ? 'Ocultar y empezar el debate'
                              : 'Ocultar y pasar el móvil',
                          onNext: next,
                        )
                      : PassPhoneCover(
                          player: player,
                          heading: 'Pasa el móvil a',
                          progress:
                              'Jugador ${_index + 1} de ${deal.players.length}',
                          buttonLabel: 'Soy ${player.name}, ver mi tarjeta',
                          onContinue: () {
                            AppFeedback.medium();
                            playSound(AppSound.card);
                            setState(() => _shown = true);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({
    required this.player,
    required this.card,
    required this.buttonLabel,
    required this.onNext,
  });

  final Player player;
  final RevealCard card;
  final String buttonLabel;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final impostor = card.isImpostor;
    const label = TextStyle(
      color: infiltradoInkMuted,
      letterSpacing: 1.2,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    return InfiltradoBody(
      footer: FilledButton(
        onPressed: onNext,
        child: Text(buttonLabel, textAlign: TextAlign.center),
      ),
      children: [
        _FlipIn(
          child: TicketCard(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            stub: Text(
              impostor
                  ? 'No sabes la palabra. Escucha, disimula y adivínala.'
                  : 'Da pistas sin decirla. El infiltrado tiene la oreja puesta.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: infiltradoInk,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Column(
              children: [
                Text(
                  player.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: infiltradoInkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('CATEGORÍA', style: label),
                const SizedBox(height: 4),
                SlabText(
                  card.category,
                  size: 24,
                  color: infiltradoInk,
                  fit: true,
                ),
                const SizedBox(height: 24),
                if (impostor) ...[
                  AppIcon.detective.widget(
                    size: 56,
                    color: AppColors.burgundy,
                    semanticLabel: 'Infiltrado',
                  ),
                  const SizedBox(height: 8),
                  SlabText(
                    'Eres el infiltrado',
                    size: 26,
                    color: AppColors.burgundy,
                  ),
                ] else ...[
                  const Text('LA PALABRA', style: label),
                  const SizedBox(height: 4),
                  SlabText(
                    card.word!,
                    size: 36,
                    color: infiltradoInk,
                    fit: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// La tarjeta entra girando sobre su eje vertical, como un boleto que se da
/// la vuelta. Con animaciones desactivadas aparece directamente.
class _FlipIn extends StatelessWidget {
  const _FlipIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = infiltradoReduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 0 : 1, end: 0),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(t * math.pi / 2),
        child: child,
      ),
      child: child,
    );
  }
}
