import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../rosco_data.dart';

class RoscoSetupScreen extends ConsumerWidget {
  const RoscoSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(roscoSetupProvider);
    final controller = ref.read(roscoSetupProvider.notifier);

    final theme = Theme.of(context);
    final tinted = theme.copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? roscoColor : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? roscoColor.withValues(alpha: 0.35) : AppColors.surfaceHigh),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? roscoColor.withValues(alpha: 0.22) : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? roscoColor : AppColors.text),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.outline)),
        ),
      ),
    );

    return Theme(
      data: tinted,
      child: Scaffold(
        appBar: AppBar(title: const Text('El rosco')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text(
              'Se lee la definición de cada letra. Cuando se acaba el tiempo, se desvela la palabra.',
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
            const _Title('Nivel'),
            SegmentedButton<RoscoLevel>(
              showSelectedIcon: false,
              segments: [for (final l in RoscoLevel.values) ButtonSegment(value: l, label: Text(l.label))],
              selected: {setup.level},
              onSelectionChanged: (v) => controller.update((s) => s.copyWith(level: v.first)),
            ),
            const _Title('Tiempo para pensar'),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10 s')),
                ButtonSegment(value: 20, label: Text('20 s')),
                ButtonSegment(value: 30, label: Text('30 s')),
                ButtonSegment(value: 45, label: Text('45 s')),
              ],
              selected: {setup.seconds},
              onSelectionChanged: (v) => controller.update((s) => s.copyWith(seconds: v.first)),
            ),
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pasar a la siguiente automáticamente', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Si no, se avanza con un botón', style: TextStyle(color: AppColors.textMuted)),
              value: setup.auto,
              onChanged: (on) => controller.update((s) => s.copyWith(auto: on)),
            ),
            if (setup.auto) ...[
              const _Title('Tiempo para leer la respuesta'),
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 3, label: Text('3 s')),
                  ButtonSegment(value: 5, label: Text('5 s')),
                  ButtonSegment(value: 8, label: Text('8 s')),
                ],
                selected: {setup.readSeconds},
                onSelectionChanged: (v) => controller.update((s) => s.copyWith(readSeconds: v.first)),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: roscoColor, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(56)),
              onPressed: () => context.push('/game/rosco/play'),
              child: const Text('Jugar · 27 letras', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
