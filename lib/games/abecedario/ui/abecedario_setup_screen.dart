import '../../../core/help/how_to_play.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/settings/app_feedback.dart';
import '../../prompt_deck/game_colors.dart';
import '../../prompt_deck/setup_hero.dart';
import '../abecedario_data.dart';

class AbecedarioSetupScreen extends ConsumerWidget {
  const AbecedarioSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(abecedarioSetupProvider);
    final controller = ref.read(abecedarioSetupProvider.notifier);

    final theme = Theme.of(context);
    final tinted = theme.copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? abecedarioColor
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? abecedarioColor.withValues(alpha: 0.35)
              : AppColors.surfaceHigh,
        ),
      ),
    );

    return Theme(
      data: tinted,
      child: Scaffold(
        appBar: AppBar(actions: const [HowToPlayButton('abecedario')]),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const SetupHero(
                gameId: 'abecedario',
                title: 'Abecedario',
                color: abecedarioColor,
                hook: 'Veintisiete letras. Un reloj que no espera.',
                detail:
                    'Una definición por letra. Si el reloj llega a cero, '
                    'se desvela la palabra.',
              ),
              const SizedBox(height: 24),
              BrassCard(
                label: 'Nivel',
                child: _Options<AbecedarioLevel>(
                  values: AbecedarioLevel.values,
                  selected: setup.level,
                  labelOf: (l) => l.label,
                  onSelected: (v) =>
                      controller.update((s) => s.copyWith(level: v)),
                ),
              ),
              const SizedBox(height: 14),
              BrassCard(
                label: 'Tiempo para pensar',
                child: _Options<int>(
                  values: const [10, 20, 30, 45],
                  selected: setup.seconds,
                  labelOf: (v) => '$v s',
                  onSelected: (v) =>
                      controller.update((s) => s.copyWith(seconds: v)),
                ),
              ),
              const SizedBox(height: 14),
              BrassCard(
                label: 'Siguiente letra',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Avanzar sola',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: const Text(
                        'Apagado, pasáis vosotros con el botón',
                        style: TextStyle(color: GameColors.mutedText),
                      ),
                      value: setup.auto,
                      onChanged: (on) =>
                          controller.update((s) => s.copyWith(auto: on)),
                    ),
                    if (setup.auto) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Tiempo para leer la respuesta',
                        style: TextStyle(
                          color: GameColors.mutedText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Options<int>(
                        values: const [3, 5, 8],
                        selected: setup.readSeconds,
                        labelOf: (v) => '$v s',
                        onSelected: (v) => controller.update(
                          (s) => s.copyWith(readSeconds: v),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: abecedarioColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: () => context.push('/game/abecedario/play'),
                child: const Text(
                  'Jugar · 27 letras',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opciones de una sola elección como fichas que pasan de línea con letra grande
/// (un SegmentedButton de cuatro huecos no cabe a 320 px con escala 2.0).
class _Options<T> extends StatelessWidget {
  const _Options({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(labelOf(v)),
            selected: v == selected,
            showCheckmark: true,
            checkmarkColor: AppColors.text,
            selectedColor: abecedarioColor.withValues(alpha: 0.45),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
            side: BorderSide(
              color: v == selected ? abecedarioColor : AppColors.textMuted,
              width: v == selected ? 2 : 1,
            ),
            onSelected: (_) {
              AppFeedback.selection();
              onSelected(v);
            },
          ),
      ],
    );
  }
}
