import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../trivia/ui/quiz_fx.dart';
import '../domain/geo_map.dart';
import '../domain/quiz.dart';
import '../geo_data.dart';
import '../geo_store.dart';
import 'geo_widgets.dart';

class GeoQuizScreen extends ConsumerStatefulWidget {
  const GeoQuizScreen({super.key});

  @override
  ConsumerState<GeoQuizScreen> createState() => _GeoQuizScreenState();
}

class _GeoQuizScreenState extends ConsumerState<GeoQuizScreen> {
  late final GeoSetup _setup = ref.read(geoSetupProvider);
  GeoQuiz? _engine;
  List<Question> _questions = const [];

  int _index = 0;
  int _correct = 0;
  int _streak = 0;
  final List<QuizMistake> _mistakes = [];

  /// Resultado de la pregunta actual: `null` = sin responder.
  bool? _wasCorrect;
  String? _picked;
  String? _typed;

  /// Modo mental: ya se ha destapado la respuesta y falta decir si se acertó.
  bool _revealed = false;

  final _text = TextEditingController();
  final _focus = FocusNode();
  Timer? _autoNext;

  Question get _q => _questions[_index];
  bool get _answered => _wasCorrect != null;

  @override
  void dispose() {
    _autoNext?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _answer({String? option, String? typed, bool giveUp = false}) {
    if (_answered) return;
    final bool ok;
    if (giveUp) {
      ok = false;
    } else if (option != null) {
      ok = option == _q.answer;
    } else {
      ok = _engine!.isCorrect(_q, typed ?? '');
    }
    ok ? AppFeedback.light() : AppFeedback.heavy();
    playSound(ok ? AppSound.correct : AppSound.wrong);
    setState(() {
      _wasCorrect = ok;
      _picked = option;
      _typed = giveUp ? null : typed;
      if (ok) {
        _correct++;
        _streak++;
      } else {
        _streak = 0;
        _mistakes.add(QuizMistake(_q, giveUp ? null : (option ?? typed)));
      }
    });
    if (ok) _autoNext = Timer(const Duration(milliseconds: 850), _next);
  }

  void _next() {
    _autoNext?.cancel();
    if (!mounted) return;
    if (_index + 1 >= _questions.length) {
      _finish();
      return;
    }
    setState(() {
      _index++;
      _wasCorrect = null;
      _picked = null;
      _typed = null;
      _revealed = false;
      _text.clear();
    });
    if (_setup.mode == AnswerMode.typed) _focus.requestFocus();
  }

  void _finish() {
    final records = ref.read(geoRecordsProvider.notifier);
    final isRecord = records.submit(_setup.recordKey, _correct);
    ref
        .read(lastQuizResultProvider.notifier)
        .set(
          QuizResult(
            setup: _setup,
            total: _questions.length,
            correct: _correct,
            mistakes: List.unmodifiable(_mistakes),
            newRecord: isRecord,
            best: max(
              _correct,
              ref.read(geoRecordsProvider)[_setup.recordKey] ?? 0,
            ),
          ),
        );
    context.pushReplacement('/game/geografia/result');
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
    final quizAsync = ref.watch(geoQuizProvider(_setup.category));
    final quiz = quizAsync.value;
    ref.watch(silhouettesProvider); // precarga las siluetas
    if (quiz == null) {
      if (quizAsync.hasError) {
        return Scaffold(
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
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_engine == null) {
      _engine = quiz;
      _questions = quiz.generate(_setup.config);
    }
    final map = switch (_engine) {
      final MapQuizEngine m => m.map,
      _ => null,
    };
    if (_questions.isEmpty) {
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

    final q = _q;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => Column(
              children: [
                _Header(
                  index: _index,
                  total: _questions.length,
                  streak: _streak,
                  onClose: _exit,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(a),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_index),
                      child: _Prompt(question: q, map: map),
                    ),
                  ),
                ),
                // Las respuestas se desplazan si no caben (letra grande, pantallas pequeñas).
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: max(200.0, box.maxHeight * 0.6),
                    ),
                    child: SingleChildScrollView(
                      child: switch (_setup.mode) {
                        AnswerMode.options => _Options(
                          question: q,
                          picked: _picked,
                          answered: _answered,
                          onPick: (o) => _answer(option: o),
                        ),
                        AnswerMode.reveal => _RevealAnswer(
                          question: q,
                          revealed: _revealed,
                          onReveal: () {
                            AppFeedback.selection();
                            setState(() => _revealed = true);
                          },
                          onScore: (ok) {
                            _answer(option: ok ? q.answer : null, giveUp: !ok);
                            _autoNext?.cancel();
                            _next();
                          },
                        ),
                        AnswerMode.typed => _TypedAnswer(
                          controller: _text,
                          focus: _focus,
                          question: q,
                          answered: _answered,
                          wasCorrect: _wasCorrect,
                          typed: _typed,
                          onSubmit: () => _answer(typed: _text.text),
                          onGiveUp: () => _answer(giveUp: true),
                        ),
                      },
                    ),
                  ),
                ),
                // El hueco del botón está siempre reservado para que nada salte al fallar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: AnimatedOpacity(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    opacity: _answered && !_wasCorrect! ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !(_answered && !_wasCorrect!),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: geoColor,
                            foregroundColor: const Color(0xFF042320),
                          ),
                          onPressed: _next,
                          child: Text(
                            _index + 1 >= _questions.length
                                ? 'Ver resultado'
                                : 'Siguiente',
                          ),
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

class _Header extends StatelessWidget {
  const _Header({
    required this.index,
    required this.total,
    required this.streak,
    required this.onClose,
  });

  final int index;
  final int total;
  final int streak;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final fast = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Salir',
                icon: AppIcon.close.widget(),
                onPressed: onClose,
              ),
              Expanded(
                child: Text(
                  '${index + 1} / $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: AnimatedOpacity(
                  duration: fast
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  opacity: streak >= 2 ? 1 : 0,
                  child: streak >= 2
                      ? Semantics(
                          label: 'Racha de $streak aciertos',
                          excludeSemantics: true,
                          child: _Streak(streak: streak),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: index / total),
                duration: fast
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  color: geoColor,
                  backgroundColor: AppColors.surfaceHigh,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contador de racha: llama + cifra en Alfa Slab One. Late al sumar un acierto.
class _Streak extends StatelessWidget {
  const _Streak({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final fast = MediaQuery.disableAnimationsOf(context);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(streak),
        tween: Tween(begin: fast ? 1 : 0, end: 1),
        duration: fast ? Duration.zero : const Duration(milliseconds: 450),
        builder: (_, v, child) =>
            Transform.scale(scale: 1 + 0.35 * sin(v * pi), child: child),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.flame.widget(size: 24),
            const SizedBox(width: 4),
            Text('$streak', style: quizDisplay(20, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.question, this.map});

  final Question question;
  final GeoMap? map;

  @override
  Widget build(BuildContext context) {
    final c = question.country;
    final (label, body) = switch (question.kind) {
      QuestionKind.region => (map!.question, _map()),
      QuestionKind.flag => ('¿De qué país es esta bandera?', _flag(context)),
      QuestionKind.silhouette => ('¿Qué país tiene esta forma?', _silhouette()),
      QuestionKind.capital => ('¿Cuál es la capital de…?', _bigText(c!.name)),
      QuestionKind.capitalOwner => (
        '¿De qué país es capital…?',
        _bigText(c!.capital),
      ),
    };
    // Todo el enunciado se encoge a la vez si el hueco es bajo (pantallas
    // pequeñas, letra grande): nunca desborda.
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: box.maxWidth),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 16),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _flag(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width - 72, 340.0);
    return FlagView(question.country!, width: width);
  }

  Widget _silhouette() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340, maxHeight: 300),
    child: AspectRatio(
      aspectRatio: 1.15,
      child: SilhouetteView(question.country!.iso),
    ),
  );

  /// Se puede ampliar con dos dedos para ver bien las regiones pequeñas.
  Widget _map() => InteractiveViewer(
    maxScale: 6,
    child: Center(
      child: RegionMapView(map: map!, highlightId: question.region!.id),
    ),
  );

  /// El nombre impreso en un boleto de papel.
  Widget _bigText(String text) => TicketCard(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
    child: SizedBox(
      width: double.infinity,
      child: Text(text, textAlign: TextAlign.center, style: quizDisplay(34)),
    ),
  );
}

class _Options extends StatelessWidget {
  const _Options({
    required this.question,
    required this.picked,
    required this.answered,
    required this.onPick,
  });

  final Question question;
  final String? picked;
  final bool answered;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, o) in question.options.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: QuizOptionTile(
              label: o,
              letter: String.fromCharCode(0x41 + i),
              maxLines: 2,
              state: !answered
                  ? QuizOptionState.idle
                  : o == question.answer
                  ? QuizOptionState.correct
                  : o == picked
                  ? QuizOptionState.wrong
                  : QuizOptionState.dimmed,
              onTap: answered ? null : () => onPick(o),
            ),
          ),
      ],
    );
  }
}

/// Modo mental: piensas la respuesta, la destapas y dices si la acertaste.
class _RevealAnswer extends StatelessWidget {
  const _RevealAnswer({
    required this.question,
    required this.revealed,
    required this.onReveal,
    required this.onScore,
  });

  final Question question;
  final bool revealed;
  final VoidCallback onReveal;
  final ValueChanged<bool> onScore;

  @override
  Widget build(BuildContext context) {
    if (!revealed) {
      return SizedBox(
        width: double.infinity,
        height: 128,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: geoColor,
            foregroundColor: const Color(0xFF042320),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onReveal,
          icon: AppIcon.visibility.widget(color: Colors.black),
          label: const Text('Ver respuesta'),
        ),
      );
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 64,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: geoColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: geoColor, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              question.answer,
              style: quizDisplay(22, color: AppColors.text),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: () => onScore(false),
                  icon: AppIcon.close.widget(color: AppColors.danger),
                  label: const Text('Fallé'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => onScore(true),
                  icon: AppIcon.check.widget(color: Colors.black),
                  label: const Text('Acerté'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypedAnswer extends StatelessWidget {
  const _TypedAnswer({
    required this.controller,
    required this.focus,
    required this.question,
    required this.answered,
    required this.wasCorrect,
    required this.typed,
    required this.onSubmit,
    required this.onGiveUp,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final Question question;
  final bool answered;
  final bool? wasCorrect;
  final String? typed;
  final VoidCallback onSubmit;
  final VoidCallback onGiveUp;

  @override
  Widget build(BuildContext context) {
    if (answered) {
      final ok = wasCorrect!;
      final color = ok ? AppColors.success : AppColors.danger;
      return Shake(
        active: !ok,
        child: Pulse(
          active: ok,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                if (ok)
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 16,
                  ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (ok ? AppIcon.checkCircle : AppIcon.cancel).widget(
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        question.answer,
                        textAlign: TextAlign.center,
                        style: quizDisplay(22, color: AppColors.text),
                      ),
                    ),
                  ],
                ),
                if (!ok && typed != null && typed!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Escribiste: ${typed!.trim()}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focus,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta',
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: geoColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onGiveUp,
                child: const Text('Ni idea'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: geoColor,
                  foregroundColor: const Color(0xFF042320),
                ),
                onPressed: onSubmit,
                child: const Text('Comprobar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
