import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../domain/country.dart';
import '../domain/quiz.dart';
import '../geo_data.dart';
import '../geo_store.dart';
import 'geo_widgets.dart';

class GeoSetupScreen extends ConsumerWidget {
  const GeoSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(geoSetupProvider);
    final records = ref.watch(geoRecordsProvider);
    final quiz = ref.watch(geoQuizProvider(setup.category));
    final controller = ref.read(geoSetupProvider.notifier);

    final available =
        quiz.whenOrNull(data: (q) => q.poolSize(setup.config)) ?? 0;
    final questions = setup.count == 0
        ? available
        : available.clamp(0, setup.count);
    final best = records[setup.recordKey];

    // Los chips y el selector heredan el turquesa del módulo en vez del dorado global.
    final theme = Theme.of(context);
    final tealTheme = theme.copyWith(
      chipTheme: theme.chipTheme.copyWith(
        selectedColor: geoColor.withValues(alpha: 0.22),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? geoColor.withValues(alpha: 0.22)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? geoColor : AppColors.text,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.outline),
          ),
        ),
      ),
    );

    return Theme(
      data: tealTheme,
      child: Scaffold(
        appBar: AppBar(title: const Text('Geografía')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const _Title('Países del mundo'),
            _CategoryGrid(
              categories: GeoCategory.values.where((c) => !c.isMap).toList(),
              selected: setup.category,
              onSelect: (c) =>
                  controller.update((s) => s.copyWith(category: c)),
            ),
            const _Title('Mapas · adivina la región marcada'),
            _CategoryGrid(
              categories: GeoCategory.values.where((c) => c.isMap).toList(),
              selected: setup.category,
              onSelect: (c) =>
                  controller.update((s) => s.copyWith(category: c)),
            ),
            const _Title('Dificultad'),
            Row(
              children: [
                for (final (i, (mode, icon, title, subtitle)) in const [
                  (AnswerMode.options, Icons.grid_view_rounded, 'Fácil', '4 opciones'),
                  (AnswerMode.reveal, Icons.visibility_rounded, 'Mental', 'Piensa y mira'),
                  (AnswerMode.typed, Icons.keyboard_rounded, 'Difícil', 'Escribe'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _Tile(
                      selected: setup.mode == mode,
                      onTap: () => controller.update((s) => s.copyWith(mode: mode)),
                      child: _Difficulty(icon: icon, title: title, subtitle: subtitle),
                    ),
                  ),
                ],
              ],
            ),
            if (!setup.category.isMap) ...[
              const _Title('Región'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Todo el mundo'),
                    selected: setup.regions.length == Continent.values.length,
                    showCheckmark: false,
                    onSelected: (_) => controller.update(
                      (s) => s.copyWith(regions: {...Continent.values}),
                    ),
                  ),
                  for (final r in Continent.values)
                    FilterChip(
                      label: Text(r.label),
                      selected:
                          setup.regions.length < Continent.values.length &&
                          setup.regions.contains(r),
                      showCheckmark: false,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        controller.update((s) {
                          // Desde "todo el mundo", tocar una región deja solo esa.
                          if (s.regions.length == Continent.values.length) {
                            return s.copyWith(regions: {r});
                          }
                          final next = {...s.regions};
                          if (!next.remove(r)) next.add(r);
                          return s.copyWith(
                            regions: next.isEmpty
                                ? {...Continent.values}
                                : next,
                          );
                        });
                      },
                    ),
                ],
              ),
            ],
            const _Title('Preguntas'),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 20, label: Text('20')),
                ButtonSegment(value: 0, label: Text('Todas')),
              ],
              selected: {setup.count},
              onSelectionChanged: (v) =>
                  controller.update((s) => s.copyWith(count: v.first)),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (best != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Tu récord: $best/$questions',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: geoColor,
                    foregroundColor: const Color(0xFF042320),
                  ),
                  onPressed: questions == 0
                      ? null
                      : () => context.push('/game/geografia/play'),
                  child: Text(
                    questions == 0
                        ? 'Sin preguntas con estos filtros'
                        : 'Empezar · $questions preguntas',
                  ),
                ),
              ),
            ],
          ),
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
    padding: const EdgeInsets.only(top: 26, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        fontSize: 12,
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? geoColor.withValues(alpha: 0.16)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? geoColor : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _Difficulty extends StatelessWidget {
  const _Difficulty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: geoColor),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<GeoCategory> categories;
  final GeoCategory selected;
  final ValueChanged<GeoCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final half = (box.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in categories)
              SizedBox(
                // Si el número es impar, la última ocupa todo el ancho.
                width: c == categories.last && categories.length.isOdd
                    ? box.maxWidth
                    : half,
                child: _Tile(
                  selected: selected == c,
                  onTap: () => onSelect(c),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: c.flagIso != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: SvgPicture.asset(
                                  'assets/geo/flags/${c.flagIso}.svg',
                                  height: 24,
                                ),
                              )
                            : Text(
                                c.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              c.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
