import '../../../core/help/how_to_play.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/settings/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../domain/country.dart';
import '../domain/quiz.dart';
import '../geo_data.dart';
import '../geo_store.dart';
import '../../trivia/ui/quiz_fx.dart';
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

    final worldCats = GeoCategory.values.where((c) => !c.isMap).toList();
    final mapCats = GeoCategory.values.where((c) => c.isMap).toList();

    return Theme(
      data: tealTheme,
      child: Scaffold(
        appBar: AppBar(actions: const [HowToPlayButton('geografia')]),
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const QuizSetupHeader(
                  gameId: 'geografia',
                  title: 'Geografía',
                  color: geoColor,
                  hook: 'Banderas, capitales y mapas. La casa no regala atlas.',
                ),
                QuizSection(
                  title: 'Países del mundo',
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: _CategoryGrid(
                    categories: worldCats,
                    selected: setup.category,
                    onSelect: (c) =>
                        controller.update((s) => s.copyWith(category: c)),
                  ),
                ),
                QuizSection(
                  title: 'Mapas · la región marcada',
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: _CategoryGrid(
                    categories: mapCats,
                    selected: setup.category,
                    onSelect: (c) =>
                        controller.update((s) => s.copyWith(category: c)),
                  ),
                ),
                QuizSection(
                  title: 'Dificultad',
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: _DifficultyPicker(
                    selected: setup.mode,
                    onSelect: (m) =>
                        controller.update((s) => s.copyWith(mode: m)),
                  ),
                ),
                if (!setup.category.isMap)
                  QuizSection(
                    title: 'Región',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Todo el mundo'),
                          selected:
                              setup.regions.length == Continent.values.length,
                          showCheckmark: false,
                          onSelected: (_) => controller.update(
                            (s) => s.copyWith(regions: {...Continent.values}),
                          ),
                        ),
                        for (final r in Continent.values)
                          FilterChip(
                            label: Text(r.label),
                            selected:
                                setup.regions.length <
                                    Continent.values.length &&
                                setup.regions.contains(r),
                            showCheckmark: false,
                            onSelected: (_) {
                              AppFeedback.selection();
                              controller.update((s) {
                                // Desde "todo el mundo", tocar una región deja solo esa.
                                if (s.regions.length ==
                                    Continent.values.length) {
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
                if (questions == 0 && quiz.hasValue) ...[
                  const SizedBox(height: 24),
                  const Center(child: Jockey(size: 80)),
                ],
              ],
            ),
          ),
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
                    'Tu récord: $best',
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
                        ? (quiz.hasError
                              ? 'No se pudo cargar el contenido'
                              : 'Sin preguntas con estos filtros')
                        : 'Jugar',
                    textAlign: TextAlign.center,
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.selected,
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppFeedback.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 56),
          padding: padding,
          decoration: BoxDecoration(
            color: selected
                ? geoColor.withValues(alpha: 0.16)
                : AppColors.background.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? geoColor : AppColors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Los tres modos de respuesta. En horizontal si cabe (pantalla ancha y letra
/// normal); si no, apilados para que nada se parta.
class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.selected, required this.onSelect});

  final AnswerMode selected;
  final ValueChanged<AnswerMode> onSelect;

  static const _modes = [
    (AnswerMode.options, AppIcon.grid, 'Fácil', '4 opciones'),
    (AnswerMode.reveal, AppIcon.visibility, 'Mental', 'Piensa y mira'),
    (AnswerMode.typed, AppIcon.keyboard, 'Difícil', 'Escribe'),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, box) {
        final horizontal = box.maxWidth >= 290 && scale <= 1.2;
        Widget tile(
          (AnswerMode, AppIcon, String, String) m, {
          required bool wide,
        }) => _Tile(
          selected: selected == m.$1,
          onTap: () => onSelect(m.$1),
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 14 : 6,
            vertical: 12,
          ),
          child: wide
              ? Row(
                  children: [
                    m.$2.widget(color: geoColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.$3,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            m.$4,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : _Difficulty(icon: m.$2, title: m.$3, subtitle: m.$4),
        );
        if (horizontal) {
          return Row(
            children: [
              for (final (i, m) in _modes.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: tile(m, wide: false)),
              ],
            ],
          );
        }
        return Column(
          children: [
            for (final (i, m) in _modes.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              tile(m, wide: true),
            ],
          ],
        );
      },
    );
  }
}

class _Difficulty extends StatelessWidget {
  const _Difficulty({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final AppIcon icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        icon.widget(color: geoColor),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
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
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, box) {
        // En pantalla estrecha o con letra grande, una columna: el nombre no se parte.
        final single = box.maxWidth < 300 || scale > 1.3;
        final half = (box.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in categories)
              SizedBox(
                // Si el número es impar, la última ocupa todo el ancho.
                width:
                    single || (c == categories.last && categories.length.isOdd)
                    ? box.maxWidth
                    : half,
                child: _Tile(
                  selected: selected == c,
                  onTap: () => onSelect(c),
                  child: Row(
                    children: [
                      GeoCategoryIcon(c, size: 34),
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
                              maxLines: 2,
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
