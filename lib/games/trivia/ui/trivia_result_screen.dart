import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../trivia_data.dart';

class TriviaResultScreen extends ConsumerWidget {
  const TriviaResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(lastTriviaResultProvider);
    if (r == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('No hay ninguna partida')));
    }
    final ratio = r.total == 0 ? 0.0 : r.correct / r.total;
    final message = switch (ratio) {
      1.0 => '¡Perfecto! 🧠',
      >= 0.8 => '¡Gran nivel!',
      >= 0.5 => 'Nada mal',
      _ => 'A seguir practicando',
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                        value: ratio, strokeWidth: 12, color: triviaColor, backgroundColor: AppColors.surfaceHigh),
                  ),
                  Text('${r.correct}/${r.total}', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => context.go('/'), child: const Text('Menú'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: triviaColor, foregroundColor: Colors.black),
                  onPressed: () => context.pushReplacement('/game/trivia/play'),
                  child: const Text('Otra partida'),
                ),
              ),
            ],
          ),
          if (r.mistakes.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('FALLADAS',
                style: TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12)),
            const SizedBox(height: 8),
            for (final m in r.mistakes)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.question.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text('Respondiste: ${m.given}',
                          style: const TextStyle(color: AppColors.danger, decoration: TextDecoration.lineThrough)),
                      Text('Correcta: ${m.question.answer}',
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
