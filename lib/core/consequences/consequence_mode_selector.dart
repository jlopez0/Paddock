import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../settings/settings_controller.dart';
import 'consequences.dart';
import 'sorbos_flag.dart';

/// Etiqueta visible del modo. El enum `puntos` se guarda tal cual; solo se llama "Fichas".
String consequenceModeLabel(ConsequenceMode mode) => switch (mode) {
  ConsequenceMode.puntos => 'Fichas',
  ConsequenceMode.retos => 'Retos',
  ConsequenceMode.sorbos => 'Sorbos',
};

/// Descripción corta (una línea) que cambia según el modo.
String consequenceModeDescription(ConsequenceMode mode) => switch (mode) {
  ConsequenceMode.puntos =>
    'Se juega por honor. Nadie cumple nada fuera de la app.',
  ConsequenceMode.retos =>
    'Lo que pierdes se cumple con retos. Hasta 3 por ronda.',
  ConsequenceMode.sorbos =>
    'Opcional y solo +18. Hasta 3 por ronda · o agua o reto.',
};

/// Elige el modo. Sorbos exige confirmar la edad una sola vez; si se cancela,
/// se mantiene el modo anterior. Lo comparten Ajustes y la home.
Future<void> selectConsequenceMode(
  BuildContext context,
  WidgetRef ref,
  ConsequenceMode mode,
) async {
  final controller = ref.read(settingsProvider.notifier);
  // Compilación sin Sorbos: ni diálogo +18 ni cambio de modo.
  if (mode == ConsequenceMode.sorbos && !ref.read(sorbosEnabledProvider)) {
    return;
  }
  if (mode == ConsequenceMode.sorbos &&
      !ref.read(settingsProvider).adultConfirmed) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Solo para mayores de 18'),
        content: const Text(
          'El modo Sorbos es solo para mayores de edad. '
          'Nadie está obligado a beber: siempre se puede elegir agua o un reto.',
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
    if (ok != true) return;
    controller.confirmAdult();
  }
  controller.setConsequenceMode(mode);
}

/// Selector Fichas / Retos / Sorbos con su descripción.
///
/// [alwaysOfferSorbos] true (Ajustes): Sorbos siempre sale y pide el +18 al elegirlo.
/// false (home): Sorbos solo sale si ya se confirmó la edad (`adultConfirmed`).
/// [compact] quita el título y reduce el aire (home).
class ConsequenceModeSelector extends ConsumerWidget {
  const ConsequenceModeSelector({
    super.key,
    this.alwaysOfferSorbos = true,
    this.compact = false,
  });

  final bool alwaysOfferSorbos;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final showSorbos =
        ref.watch(sorbosEnabledProvider) &&
        (alwaysOfferSorbos || settings.adultConfirmed);
    var selected = settings.consequenceMode;
    if (selected == ConsequenceMode.sorbos && !showSorbos) {
      selected = ConsequenceMode.puntos;
    }
    final modes = [
      ConsequenceMode.puntos,
      ConsequenceMode.retos,
      if (showSorbos) ConsequenceMode.sorbos,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          const Text(
            'Qué hay en juego',
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ConsequenceMode>(
            showSelectedIcon: false,
            segments: [
              for (final m in modes)
                ButtonSegment(
                  value: m,
                  label: Text(
                    consequenceModeLabel(m),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            selected: {selected},
            onSelectionChanged: (s) =>
                selectConsequenceMode(context, ref, s.first),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          consequenceModeDescription(selected),
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: compact ? 13 : 14,
          ),
        ),
      ],
    );
  }
}
