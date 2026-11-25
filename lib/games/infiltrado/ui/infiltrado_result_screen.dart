import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../../prompt_deck/game_colors.dart';
import '../../../core/consequences/consequence_banner.dart';
import '../../../core/consequences/retos_filter.dart';
import '../../../core/content/prompts.dart';
import '../../../core/players/player.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/settings/app_feedback.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/infiltrado_engine.dart';
import '../infiltrado_store.dart';
import 'infiltrado_widgets.dart';

/// Última oportunidad del infiltrado pillado y resultado de la ronda.
class InfiltradoResultScreen extends ConsumerStatefulWidget {
  const InfiltradoResultScreen({super.key});

  @override
  ConsumerState<InfiltradoResultScreen> createState() =>
      _InfiltradoResultScreenState();
}

class _InfiltradoResultScreenState
    extends ConsumerState<InfiltradoResultScreen> {
  final _guess = TextEditingController();

  @override
  void dispose() {
    _guess.dispose();
    super.dispose();
  }

  void _resolve({String? guess}) {
    AppFeedback.medium();
    ref.read(infiltradoGameProvider.notifier).finish(guess: guess);
  }

  void _again() {
    final players = ref.read(playersProvider);
    final setup = ref.read(infiltradoSetupProvider);
    final ids = setup.playerIds;
    final chosen = [
      for (final p in players)
        if (ids == null || ids.contains(p.id)) p,
    ];
    final words =
        ref.read(infiltradoWordsProvider).asData?.value ?? kFallbackWords;
    final result = ref
        .read(infiltradoGameProvider.notifier)
        .start(players: chosen, setup: setup, words: words);
    if (result == InfiltradoStart.ok) {
      context.pushReplacement('/game/infiltrado/reveal');
      return;
    }
    // Sin jugadores o sin palabras: se vuelve a la configuración, que explica el motivo.
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(infiltradoGameProvider);
    if (game == null) return const InfiltradoNoGame();
    final byId = {for (final p in ref.watch(playersProvider)) p.id: p};
    String nameOf(String id) =>
        (byId[id] ?? Player(id: id, name: '?', colorIndex: 0)).name;

    final outcome = game.outcome;
    final Widget body;
    if (outcome == null) {
      body = _LastChance(
        impostor: nameOf(game.round.accused ?? ''),
        category: game.deal.category,
        controller: _guess,
        onCheck: () => _resolve(guess: _guess.text),
        onGiveUp: () => _resolve(),
      );
    } else {
      body = _Outcome(
        game: game,
        outcome: outcome,
        nameOf: nameOf,
        onAgain: _again,
      );
    }

    // Mientras falta la última oportunidad, atrás pide confirmación; con el
    // resultado ya cerrado y las fichas en la Copa, se puede salir libremente.
    final content = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: outcome != null,
        title: AppTitle(outcome == null ? 'Última oportunidad' : 'Resultado'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: body,
        ),
      ),
    );
    return outcome == null ? InfiltradoLeaveGuard(child: content) : content;
  }
}

class _LastChance extends StatelessWidget {
  const _LastChance({
    required this.impostor,
    required this.category,
    required this.controller,
    required this.onCheck,
    required this.onGiveUp,
  });

  final String impostor;
  final String category;
  final TextEditingController controller;
  final VoidCallback onCheck;
  final VoidCallback onGiveUp;

  @override
  Widget build(BuildContext context) => InfiltradoBody(
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(onPressed: onCheck, child: const Text('Comprobar')),
        const SizedBox(height: 8),
        TextButton(onPressed: onGiveUp, child: const Text('Ni idea')),
      ],
    ),
    children: [
      Center(
        child: AppIcon.target.widget(
          size: 56,
          semanticLabel: 'Última oportunidad',
        ),
      ),
      const SizedBox(height: 12),
      SlabText('¡$impostor era el infiltrado!', size: 24),
      const SizedBox(height: 8),
      Text(
        'Última oportunidad: si acierta la palabra de "$category", gana igualmente. '
        'Los demás, mirad a otro lado.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: GameColors.mutedText, fontSize: 16),
      ),
      const SizedBox(height: 20),
      TextField(
        controller: controller,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => onCheck(),
        decoration: const InputDecoration(hintText: 'La palabra era…'),
      ),
    ],
  );
}

class _Outcome extends ConsumerWidget {
  const _Outcome({
    required this.game,
    required this.outcome,
    required this.nameOf,
    required this.onAgain,
  });

  final InfiltradoGame game;
  final InfiltradoOutcome outcome;
  final String Function(String) nameOf;
  final VoidCallback onAgain;

  String get _headline {
    if (!outcome.impostorsWin) return '¡Lo habéis pillado!';
    if (outcome.guessedWord) return '¡Acertó la palabra!';
    return 'El infiltrado se escapa';
  }

  String get _detail {
    final accused = outcome.accused;
    if (accused == null) {
      return 'Empate a votos: nadie se sienta en el banquillo.';
    }
    if (!outcome.caught) {
      return 'Acusasteis a ${nameOf(accused)}, pero pasaba por allí.';
    }
    if (outcome.guessedWord) {
      return '${nameOf(accused)} estaba cazado, pero adivinó la palabra y gana igualmente.';
    }
    return 'Acusasteis a ${nameOf(accused)} y era el infiltrado. Buen ojo.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    final adult = ref.watch(settingsProvider.select((s) => s.adultConfirmed));
    final retosPrompts = ref
        .watch(promptsProvider('assets/content/es/retos.json'))
        .asData
        ?.value;
    final retos = retosPrompts == null
        ? null
        : filterRetos(retosPrompts, adultConfirmed: adult);
    final losses = <String, int>{
      for (final e in outcome.deltas.entries)
        if (e.value < 0) nameOf(e.key): -e.value,
    };
    final impostorNames = [for (final id in game.deal.impostors) nameOf(id)];
    final votes = game.lastVote?.tally.entries.toList() ?? const [];
    votes.sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            children: [
              Semantics(
                label: outcome.impostorsWin
                    ? 'Gana el infiltrado'
                    : 'Ganan los civiles',
                excludeSemantics: true,
                child: Center(
                  child: outcome.impostorsWin
                      ? AppIcon.detective.widget(size: 64)
                      : const Jockey(pose: JockeyPose.celebra, size: 88),
                ),
              ),
              const SizedBox(height: 12),
              InfiltradoStamp(outcome.impostorsWin ? 'INFILTRADO' : 'SALVADOS'),
              const SizedBox(height: 16),
              SlabText(_headline, size: 24),
              const SizedBox(height: 6),
              Text(
                _detail,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GameColors.mutedText,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              TicketCard(
                padding: const EdgeInsets.all(16),
                stub: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La palabra era (${game.deal.category})',
                      style: const TextStyle(
                        color: infiltradoInkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      game.deal.word,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: infiltradoInk,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.deal.impostors.length == 1
                          ? 'El infiltrado era'
                          : 'Los infiltrados eran',
                      style: const TextStyle(
                        color: infiltradoInkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      impostorNames.join(' y '),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.burgundy,
                      ),
                    ),
                  ],
                ),
              ),
              if (votes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votos',
                          style: TextStyle(color: GameColors.mutedText),
                        ),
                        const SizedBox(height: 4),
                        for (final e in votes)
                          Row(
                            children: [
                              Expanded(child: Text(nameOf(e.key))),
                              Text(
                                e.value == 1 ? '1 voto' : '${e.value} votos',
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (losses.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConsequenceBanner(losses: losses, mode: mode, retos: retos),
              ],
              const SizedBox(height: 8),
              const Text(
                'Fichas anotadas en la Copa de la noche.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GameColors.mutedText, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: onAgain, child: const Text('Otra ronda')),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push('/copa'),
                child: const Text('Ver la Copa'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/'),
                child: const Text('Menú'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
