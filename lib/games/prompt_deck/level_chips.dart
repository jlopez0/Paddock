import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_icons.dart';
import '../../app/theme.dart';
import '../../core/content/prompts.dart';
import '../../core/settings/app_feedback.dart';
import '../../core/settings/settings_controller.dart';
import 'game_colors.dart';

/// Pide confirmar +18 antes de activar [PromptLevel.atrevido] (una sola vez, queda en ajustes).
/// Devuelve `true` si el nivel se puede activar.
Future<bool> ensureLevelAllowed(
  BuildContext context,
  WidgetRef ref,
  PromptLevel level,
) async {
  if (level != PromptLevel.atrevido ||
      ref.read(settingsProvider).adultConfirmed) {
    return true;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Solo para mayores de 18'),
      content: const Text(
        'El nivel Atrevido incluye contenido para adultos. '
        'Actívalo solo si todos los presentes son mayores de edad.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Tengo 18 o más'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  ref.read(settingsProvider.notifier).confirmAdult();
  return true;
}

/// Icono dibujado del nivel + su nombre. Es la etiqueta de los chips de nivel y
/// del distintivo de la carta. El icono es decorativo: el texto da el sentido.
class LevelLabel extends StatelessWidget {
  const LevelLabel(this.level, {super.key, this.iconSize = 20, this.style});

  final PromptLevel level;
  final double iconSize;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: LevelIcon(level.id, size: iconSize)),
        const SizedBox(width: 6),
        Flexible(child: Text(level.label, style: style)),
      ],
    );
  }
}

/// Selector de niveles común a los mazos y al Infiltrado: chips con check, selección múltiple.
/// Los niveles se combinan; quien lo usa decide qué hacer si no queda ninguno.
class LevelChips extends StatelessWidget {
  const LevelChips({
    super.key,
    required this.levels,
    required this.color,
    required this.onToggle,
  });

  final Set<PromptLevel> levels;
  final Color color;
  final ValueChanged<PromptLevel> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final level in PromptLevel.values)
              FilterChip(
                key: ValueKey('level-${level.name}'),
                label: LevelLabel(level),
                selected: levels.contains(level),
                showCheckmark: true,
                checkmarkColor: AppColors.text,
                selectedColor: color.withValues(alpha: 0.3),
                side: BorderSide(
                  color: levels.contains(level) ? color : AppColors.outline,
                ),
                onSelected: (_) {
                  AppFeedback.selection();
                  onToggle(level);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Se pueden mezclar niveles.',
          style: TextStyle(color: GameColors.mutedText, fontSize: 13),
        ),
      ],
    );
  }
}
