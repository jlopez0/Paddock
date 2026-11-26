import '../../../core/help/how_to_play.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../trivia_data.dart';
import 'quiz_fx.dart';

class TriviaSetupScreen extends ConsumerWidget {
  const TriviaSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(triviaSetupProvider);
    final bank = ref.watch(triviaBankProvider);
    final controller = ref.read(triviaSetupProvider.notifier);
    final available =
        bank.whenOrNull(
          data: (b) => b
              .where(
                (q) =>
                    setup.categories.contains(q.category) &&
                    setup.level.accepts(q),
              )
              .length,
        ) ??
        0;
    final questions = setup.count == 0
        ? available
        : available.clamp(0, setup.count);

    final theme = Theme.of(context);
    final tinted = theme.copyWith(
      chipTheme: theme.chipTheme.copyWith(
        selectedColor: triviaColor.withValues(alpha: 0.22),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? triviaColor.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? triviaColor : AppColors.text,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.outline),
          ),
        ),
      ),
    );

    return Theme(
      data: tinted,
      child: Scaffold(
        appBar: AppBar(actions: const [HowToPlayButton('trivia')]),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuizSetupHeader(
                  gameId: 'trivia',
                  title: 'Trivia',
                  color: triviaColor,
                  hook: 'Cuatro opciones, una buena. La casa no da pistas.',
                ),
                QuizSection(
                  title: 'Categorías',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in TriviaCategory.values)
                        FilterChip(
                          avatar: ExcludeSemantics(
                            child: CategoryIcon(c.name, size: 20),
                          ),
                          label: Text(c.label),
                          selected: setup.categories.contains(c),
                          showCheckmark: false,
                          onSelected: (on) => controller.update((s) {
                            final next = {...s.categories};
                            on ? next.add(c) : next.remove(c);
                            return next.isEmpty
                                ? s
                                : s.copyWith(categories: next); // al menos una
                          }),
                        ),
                    ],
                  ),
                ),
                QuizSection(
                  title: 'Nivel',
                  child: SegmentedButton<TriviaLevel>(
                    showSelectedIcon: false,
                    segments: [
                      for (final l in TriviaLevel.values)
                        ButtonSegment(value: l, label: _SegLabel(l.label)),
                    ],
                    selected: {setup.level},
                    onSelectionChanged: (v) =>
                        controller.update((s) => s.copyWith(level: v.first)),
                  ),
                ),
                QuizSection(
                  title: 'Cuántas preguntas',
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 10, label: _SegLabel('10')),
                      ButtonSegment(value: 20, label: _SegLabel('20')),
                      ButtonSegment(value: 0, label: _SegLabel('Todas')),
                    ],
                    selected: {setup.count},
                    onSelectionChanged: (v) =>
                        controller.update((s) => s.copyWith(count: v.first)),
                  ),
                ),
                if (questions == 0 && !bank.hasError && bank.hasValue) ...[
                  const SizedBox(height: 20),
                  const Center(child: Jockey(size: 80)),
                  const SizedBox(height: 8),
                  const Text(
                    'Sin preguntas con estos filtros',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: triviaColor,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  onPressed: questions == 0
                      ? null
                      : () => context.push('/game/trivia/play'),
                  child: Text(
                    bank.hasError
                        ? 'No se pudo cargar el contenido'
                        : 'Jugar',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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

/// Etiqueta de segmento: no se parte a media palabra con letra grande.
class _SegLabel extends StatelessWidget {
  const _SegLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}
