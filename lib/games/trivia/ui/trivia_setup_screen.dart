import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../trivia_data.dart';

class TriviaSetupScreen extends ConsumerWidget {
  const TriviaSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(triviaSetupProvider);
    final bank = ref.watch(triviaBankProvider);
    final controller = ref.read(triviaSetupProvider.notifier);
    final available = bank.whenOrNull(data: (b) => b.where((q) => setup.categories.contains(q.category) && setup.level.accepts(q)).length) ?? 0;
    final questions = setup.count == 0 ? available : available.clamp(0, setup.count);

    final theme = Theme.of(context);
    final tinted = theme.copyWith(
      chipTheme: theme.chipTheme.copyWith(selectedColor: triviaColor.withValues(alpha: 0.22)),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? triviaColor.withValues(alpha: 0.22) : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? triviaColor : AppColors.text),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.outline)),
        ),
      ),
    );

    return Theme(
      data: tinted,
      child: Scaffold(
        appBar: AppBar(title: const Text('Trivia')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const _Title('Categorías'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in TriviaCategory.values)
                  FilterChip(
                    label: Text('${c.emoji} ${c.label}'),
                    selected: setup.categories.contains(c),
                    showCheckmark: false,
                    onSelected: (on) => controller.update((s) {
                      final next = {...s.categories};
                      on ? next.add(c) : next.remove(c);
                      return next.isEmpty ? s : s.copyWith(categories: next); // al menos una
                    }),
                  ),
              ],
            ),
            const _Title('Nivel'),
            SegmentedButton<TriviaLevel>(
              showSelectedIcon: false,
              segments: [for (final l in TriviaLevel.values) ButtonSegment(value: l, label: Text(l.label))],
              selected: {setup.level},
              onSelectionChanged: (v) => controller.update((s) => s.copyWith(level: v.first)),
            ),
            const _Title('Preguntas'),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 0, label: Text('Todas')),
              ],
              selected: {setup.count},
              onSelectionChanged: (v) => controller.update((s) => s.copyWith(count: v.first)),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: triviaColor, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(56)),
              onPressed: questions == 0 ? null : () => context.push('/game/trivia/play'),
              child: Text('Jugar · $questions preguntas',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12)),
      );
}
