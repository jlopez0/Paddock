import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/players/player_widgets.dart' show PlayerAvatar;
import '../../../core/players/players_controller.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/settings/app_feedback.dart';
import '../../horse_race/race_texts.dart' show chipsText;
import 'quiz_fx.dart';

/// "¿Quién ha jugado?": anota las fichas de una vuelta de Trivia o Geografía
/// en la Copa. Sin jugadores en la cuadra no aparece y el juego va como siempre.
///
/// La vuelta se anota una sola vez (el [roundId] evita duplicados) y a una sola
/// persona; para la siguiente, otra vuelta. La regla de fichas está en
/// [QuizTier.chips]: solo suma, nunca resta.
class QuizCupSection extends ConsumerStatefulWidget {
  const QuizCupSection({
    super.key,
    required this.roundId,
    required this.gameId,
    required this.correct,
    required this.total,
    required this.color,
  });

  final String roundId;
  final String gameId;
  final int correct;
  final int total;
  final Color color;

  @override
  ConsumerState<QuizCupSection> createState() => _QuizCupSectionState();
}

class _QuizCupSectionState extends ConsumerState<QuizCupSection> {
  String? _selected;

  int get _chips => quizChips(widget.correct, widget.total);

  void _toggle(String id) {
    AppFeedback.light();
    setState(() => _selected = _selected == id ? null : id);
  }

  void _award() {
    final id = _selected;
    if (id == null || _chips == 0) return;
    final done = ref.read(sessionProvider.notifier).award(
      widget.roundId,
      widget.gameId,
      {id: _chips},
    );
    if (done) {
      AppFeedback.medium();
      playSound(AppSound.chip);
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);
    if (players.isEmpty || widget.total <= 0) return const SizedBox.shrink();
    final session = ref.watch(sessionProvider);
    final events = [
      for (final e in session.events)
        if (e.roundId == widget.roundId) e,
    ];
    final locked = events.isNotEmpty;
    final byId = {for (final p in players) p.id: p};
    final chips = _chips;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '¿Quién ha jugado?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (chips > 0) ...[
                    const SizedBox(width: 8),
                    ChipToken(chips, size: 24),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                chips == 0
                    ? 'Esta vuelta no suma fichas. Con la mitad de aciertos ya cae una.'
                    : locked
                    ? 'Ya anotado en la Copa'
                    : 'Esta vuelta vale ${chipsText(chips)} en la Copa',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              if (chips > 0) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in players)
                      FilterChip(
                        key: ValueKey('quiz-cup-${p.id}'),
                        selected: locked
                            ? events.any((e) => e.playerId == p.id)
                            : _selected == p.id,
                        showCheckmark: false,
                        avatar: PlayerAvatar(p, size: 26),
                        label: Text(p.name),
                        selectedColor: widget.color.withValues(alpha: 0.3),
                        side: BorderSide(
                          color:
                              (locked
                                  ? events.any((e) => e.playerId == p.id)
                                  : _selected == p.id)
                              ? widget.color
                              : AppColors.outline,
                        ),
                        onSelected: locked ? null : (_) => _toggle(p.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (locked)
                  PopIn(
                    child: Row(
                      key: const ValueKey('quiz-cup-done'),
                      children: [
                        ChipToken(chips, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${byId[events.first.playerId]?.name ?? 'Jugador'} '
                            'suma ${chipsText(chips)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('quiz-cup-award'),
                      onPressed: _selected == null ? null : _award,
                      child: Text('Anotar ${chipsText(chips)}'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
