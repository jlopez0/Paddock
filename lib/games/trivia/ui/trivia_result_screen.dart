import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../trivia_data.dart';
import 'quiz_cup_section.dart';
import 'quiz_fx.dart';

class TriviaResultScreen extends ConsumerWidget {
  const TriviaResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(lastTriviaResultProvider);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: QuizEmptyState(
            message: 'Aquí no hay partida',
            actionLabel: 'Menú',
            onAction: () => context.go('/'),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle('Resultado'),
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: AppIcon.close.widget(),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            QuizResultCard(
              correct: r.correct,
              total: r.total,
              stub: QuizStubBadge(
                text: r.mistakes.isEmpty
                    ? 'Sin un solo fallo'
                    : r.mistakes.length == 1
                    ? '1 fallo'
                    : '${r.mistakes.length} fallos',
              ),
            ),
            QuizCupSection(
              roundId: r.roundId,
              gameId: 'trivia',
              correct: r.correct,
              total: r.total,
              color: triviaColor,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Menú'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: triviaColor,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () =>
                        context.pushReplacement('/game/trivia/play'),
                    child: const Text('Otra vuelta'),
                  ),
                ),
              ],
            ),
            if (r.mistakes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'FALLOS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              for (final m in r.mistakes)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.question.text,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Dijiste: ${m.given}',
                          style: const TextStyle(
                            color: AppColors.danger,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'Correcta: ${m.question.answer}',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
