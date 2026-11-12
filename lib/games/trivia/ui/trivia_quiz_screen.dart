import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../trivia_data.dart';

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
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
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
      ref.read(lastTriviaResultProvider.notifier).set(
          TriviaResult(total: _questions!.length, correct: _correct, mistakes: List.of(_mistakes)));
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
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
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('No se pudo cargar: $e'))),
        data: (b) {
          final setup = ref.read(triviaSetupProvider);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _questions == null) {
              setState(() => _questions = generateTrivia(b, setup.categories, setup.count, Random(), level: setup.level));
            }
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
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
                    IconButton(onPressed: _exit, icon: const Icon(Icons.close_rounded)),
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
                    Text('${_index + 1}/$total', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${_q.category.emoji}  ${_q.category.label}'.toUpperCase(),
                              style: const TextStyle(
                                  color: triviaColor, fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 12)),
                          const SizedBox(height: 14),
                          Text(_q.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final o in _q.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _Option(
                      label: o,
                      state: !_answered
                          ? _OptionState.idle
                          : o == _q.answer
                              ? _OptionState.correct
                              : o == _picked
                                  ? _OptionState.wrong
                                  : _OptionState.dimmed,
                      onTap: () => _pick(o),
                    ),
                  ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  opacity: _answered ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_answered,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: triviaColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52)),
                      onPressed: _next,
                      child: Text(_index + 1 >= total ? 'Ver resultado' : 'Siguiente',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({required this.label, required this.state, required this.onTap});

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Tamaño constante en todos los estados: mismo borde, mismo hueco para el icono y altura mínima,
    // para que al responder no se desplace nada.
    final (border, fill, icon) = switch (state) {
      _OptionState.correct => (AppColors.success, AppColors.success.withValues(alpha: 0.2), Icons.check_circle_rounded),
      _OptionState.wrong => (AppColors.danger, AppColors.danger.withValues(alpha: 0.2), Icons.cancel_rounded),
      _ => (AppColors.outline, AppColors.surface, null),
    };
    return AnimatedOpacity(
      opacity: state == _OptionState.dimmed ? 0.35 : 1,
      duration: const Duration(milliseconds: 250),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Expanded(child: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                SizedBox(
                  width: 28,
                  height: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (c, anim) => ScaleTransition(scale: anim, child: c),
                    child: icon == null
                        ? const SizedBox.shrink(key: ValueKey('none'))
                        : Align(
                            key: ValueKey(icon),
                            alignment: Alignment.centerRight,
                            child: Icon(icon, color: border),
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
