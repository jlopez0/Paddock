import 'dart:math';

import 'package:material_ui/material_ui.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../trivia_data.dart';
import 'quiz_fx.dart';

class TriviaQuizScreen extends ConsumerStatefulWidget {
  const TriviaQuizScreen({super.key});

  @override
  ConsumerState<TriviaQuizScreen> createState() => _TriviaQuizScreenState();
}

class _TriviaQuizScreenState extends ConsumerState<TriviaQuizScreen> {
  List<TriviaQuestion>? _questions;
  int _index = 0;
  int _correct = 0;
  String? _picked;
  final List<TriviaMistake> _mistakes = [];

  TriviaQuestion get _q => _questions![_index];
  bool get _answered => _picked != null;

  void _pick(String option) {
    if (_answered) return;
    final ok = option == _q.answer;
    ok ? AppFeedback.light() : AppFeedback.heavy();
    playSound(ok ? AppSound.correct : AppSound.wrong);
    setState(() {
      _picked = option;
      if (ok) {
        _correct++;
      } else {
        _mistakes.add(TriviaMistake(_q, option));
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions!.length) {
      ref
          .read(lastTriviaResultProvider.notifier)
          .set(
            TriviaResult(
              total: _questions!.length,
              correct: _correct,
              mistakes: List.of(_mistakes),
            ),
          );
      context.pushReplacement('/game/trivia/result');
      return;
    }
    setState(() {
      _index++;
      _picked = null;
    });
  }

  Future<void> _exit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions == null) {
      final bank = ref.watch(triviaBankProvider);
      return bank.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar el contenido. Vuelve atrás e inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        data: (b) {
          final setup = ref.read(triviaSetupProvider);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _questions == null) {
              setState(
                () => _questions = generateTrivia(
                  b,
                  setup.categories,
                  setup.count,
                  Random(),
                  level: setup.level,
                ),
              );
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    if (_questions!.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: QuizEmptyState(
            message: 'Sin preguntas con estos filtros',
            actionLabel: 'Cambiar ajustes',
            onAction: () => context.pop(),
          ),
        ),
      );
    }

    final total = _questions!.length;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Salir',
                      onPressed: _exit,
                      icon: AppIcon.close.widget(),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_index + (_answered ? 1 : 0)) / total,
                          minHeight: 8,
                          color: triviaColor,
                          backgroundColor: AppColors.surfaceHigh,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_index + 1} / $total',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Pregunta y opciones se desplazan juntas: con letra grande nada se sale de la pantalla.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _QuestionTicket(question: _q),
                            const SizedBox(height: 20),
                            for (final (i, o) in _q.options.indexed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: QuizOptionTile(
                                  label: o,
                                  letter: String.fromCharCode(0x41 + i),
                                  minHeight: 58,
                                  state: !_answered
                                      ? QuizOptionState.idle
                                      : o == _q.answer
                                      ? QuizOptionState.correct
                                      : o == _picked
                                      ? QuizOptionState.wrong
                                      : QuizOptionState.dimmed,
                                  onTap: _answered ? null : () => _pick(o),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  opacity: _answered ? 1 : 0,
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_answered,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: triviaColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: _next,
                      child: Text(
                        _index + 1 >= total ? 'Ver resultado' : 'Siguiente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

/// La pregunta, impresa en un boleto de papel con la categoría en una etiqueta oscura.
class _QuestionTicket extends StatelessWidget {
  const _QuestionTicket({required this.question});

  final TriviaQuestion question;

  @override
  Widget build(BuildContext context) {
    return TicketCard(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: CategoryIcon(question.category.name, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      question.category.label.toUpperCase(),
                      style: const TextStyle(
                        color: triviaColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              question.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.25,
                color: quizInk,
              ),
            ),
            if (question.id.startsWith('ot-')) ...[
              const SizedBox(height: 10),
              Text(
                'Fuente: Open Trivia DB (CC BY-SA 4.0)',
                style: TextStyle(
                  fontSize: 11,
                  color: quizInk.withValues(alpha: 0.65),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
