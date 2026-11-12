import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
  QuizEngine? _engine;
  List<Question> _questions = const [];

  int _index = 0;
  int _correct = 0;
  int _streak = 0;
  final List<QuizMistake> _mistakes = [];

  /// Resultado de la pregunta actual: `null` = sin responder.
  bool? _wasCorrect;
  String? _picked;
  String? _typed;

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
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
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
      _text.clear();
    });
    if (!_setup.withOptions) _focus.requestFocus();
  }

  void _finish() {
    final records = ref.read(geoRecordsProvider.notifier);
    final isRecord = records.submit(_setup.recordKey, _correct);
    ref.read(lastQuizResultProvider.notifier).set(QuizResult(
          setup: _setup,
          total: _questions.length,
          correct: _correct,
          mistakes: List.unmodifiable(_mistakes),
          newRecord: isRecord,
          best: max(_correct, ref.read(geoRecordsProvider)[_setup.recordKey] ?? 0),
        ));
    context.pushReplacement('/game/geografia/result');
  }

  @override
  Widget build(BuildContext context) {
    final countries = ref.watch(countriesProvider);
    ref.watch(silhouettesProvider); // precarga las siluetas
    final data = countries.value;
    if (data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_engine == null) {
      _engine = QuizEngine(data);
      _questions = _engine!.generate(_setup.config);
    }
    if (_questions.isEmpty) return const Scaffold(body: Center(child: Text('No hay preguntas')));

    final q = _q;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              index: _index,
              total: _questions.length,
              streak: _streak,
              onClose: () => context.pop(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_index), child: _Prompt(question: q)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: _setup.withOptions
                  ? _Options(
                      question: q,
                      picked: _picked,
                      answered: _answered,
                      onPick: (o) => _answer(option: o),
                    )
                  : _TypedAnswer(
                      controller: _text,
                      focus: _focus,
                      question: q,
                      answered: _answered,
                      wasCorrect: _wasCorrect,
                      typed: _typed,
                      onSubmit: () => _answer(typed: _text.text),
                      onGiveUp: () => _answer(giveUp: true),
                    ),
            ),
            // El hueco del botón está siempre reservado para que nada salte al fallar.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
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
                      child: Text(_index + 1 >= _questions.length ? 'Ver resultado' : 'Siguiente'),
                    ),
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

class _Header extends StatelessWidget {
  const _Header({required this.index, required this.total, required this.streak, required this.onClose});

  final int index;
  final int total;
  final int streak;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClose),
              Expanded(
                child: Text('${index + 1} / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
              ),
              SizedBox(
                width: 64,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: streak >= 2 ? 1 : 0,
                  child: Text('🔥 $streak', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                duration: const Duration(milliseconds: 350),
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

class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final c = question.country;
    final (label, body) = switch (question.kind) {
      QuestionKind.flag => ('¿De qué país es esta bandera?', _flag(context)),
      QuestionKind.silhouette => ('¿Qué país tiene esta forma?', _silhouette()),
      QuestionKind.capital => ('¿Cuál es la capital de…?', _bigText(c.name)),
      QuestionKind.capitalOwner => ('¿De qué país es capital…?', _bigText(c.capital)),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
          const SizedBox(height: 20),
          Flexible(child: body),
        ],
      ),
    );
  }

  Widget _flag(BuildContext context) {
    final width = min(MediaQuery.sizeOf(context).width - 72, 340.0);
    return FlagView(question.country, width: width);
  }

  Widget _silhouette() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340, maxHeight: 300),
        child: AspectRatio(aspectRatio: 1.15, child: SilhouetteView(question.country.iso)),
      );

  Widget _bigText(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
      );
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Options extends StatelessWidget {
  const _Options({required this.question, required this.picked, required this.answered, required this.onPick});

  final Question question;
  final String? picked;
  final bool answered;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in question.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OptionButton(
              label: o,
              state: !answered
                  ? _OptionState.idle
                  : o == question.answer
                      ? _OptionState.correct
                      : o == picked
                          ? _OptionState.wrong
                          : _OptionState.dimmed,
              onTap: answered ? null : () => onPick(o),
            ),
          ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.state, required this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color border, Color fill, IconData? icon) = switch (state) {
      _OptionState.idle => (AppColors.outline, AppColors.surface, null),
      _OptionState.correct => (AppColors.success, AppColors.success.withValues(alpha: 0.2), Icons.check_circle_rounded),
      _OptionState.wrong => (AppColors.danger, AppColors.danger.withValues(alpha: 0.2), Icons.cancel_rounded),
      _OptionState.dimmed => (AppColors.outline, AppColors.surface, null),
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: state == _OptionState.dimmed ? 0.35 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: state == _OptionState.idle ? 1 : 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
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
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(question.answer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            if (!ok && typed != null && typed!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Escribiste: ${typed!.trim()}', style: const TextStyle(color: AppColors.textMuted)),
            ],
          ],
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
            Expanded(child: OutlinedButton(onPressed: onGiveUp, child: const Text('Ni idea'))),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: geoColor, foregroundColor: const Color(0xFF042320)),
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
