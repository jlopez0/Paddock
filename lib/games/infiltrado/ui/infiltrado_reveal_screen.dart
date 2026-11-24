import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../prompt_deck/game_colors.dart';
import '../../../core/players/player.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/settings/app_feedback.dart';
import '../domain/infiltrado_engine.dart';
import '../infiltrado_store.dart';
import 'infiltrado_widgets.dart';

/// Pasa el móvil de mano en mano: cada jugador ve en privado su tarjeta.
/// La palabra solo se pinta tras pulsar "ver mi tarjeta" y desaparece al pasar.
class InfiltradoRevealScreen extends ConsumerStatefulWidget {
  const InfiltradoRevealScreen({super.key});

  @override
  ConsumerState<InfiltradoRevealScreen> createState() => _InfiltradoRevealScreenState();
}

class _InfiltradoRevealScreenState extends ConsumerState<InfiltradoRevealScreen> {
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
                InfiltradoTopBar(title: 'Roles', trailing: '${_index + 1}/${deal.players.length}'),
                Expanded(
                  child: _shown
                      ? _CardView(
                          player: player,
                          card: deal.cardFor(id),
                          buttonLabel: last ? 'Ocultar y empezar el debate' : 'Ocultar y pasar el móvil',
                          onNext: next,
                        )
                      : PassPhoneCover(
                          player: player,
                          heading: 'Pasa el móvil a',
                          progress: 'Jugador ${_index + 1} de ${deal.players.length}',
                          buttonLabel: 'Soy ${player.name}, ver mi tarjeta',
                          onContinue: () {
                            AppFeedback.medium();
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
    final accent = impostor ? AppColors.danger : infiltradoColor;
    return InfiltradoBody(
      footer: FilledButton(onPressed: onNext, child: Text(buttonLabel, textAlign: TextAlign.center)),
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: accent, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  player.name,
                  style: const TextStyle(color: GameColors.mutedText, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Text(
                  'CATEGORÍA',
                  style: const TextStyle(
                    color: GameColors.mutedText,
                    letterSpacing: 1.2,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  card.category,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 24),
                if (impostor) ...[
                  Semantics(
                    label: 'Infiltrado',
                    excludeSemantics: true,
                    child: const Text('🕵️', style: TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Eres el infiltrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: accent),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No conoces la palabra. Disimula y averigua cuál es.',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    'LA PALABRA',
                    style: TextStyle(
                      color: GameColors.mutedText,
                      letterSpacing: 1.2,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.word!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: GameColors.infiltradoText),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Da pistas sin decirla. Cuidado: el infiltrado escucha.',
                    textAlign: TextAlign.center,
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
