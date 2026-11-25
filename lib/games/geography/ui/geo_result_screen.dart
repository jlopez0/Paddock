import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../trivia/ui/quiz_cup_section.dart';
import '../../trivia/ui/quiz_fx.dart';
import '../domain/geo_map.dart';
import '../domain/quiz.dart';
import '../geo_data.dart';
import '../geo_store.dart';
import 'geo_widgets.dart';

class GeoResultScreen extends ConsumerWidget {
  const GeoResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(lastQuizResultProvider);
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
    final mapId = r.setup.category.mapId;
    final map = mapId == null ? null : ref.watch(geoMapProvider(mapId)).value;

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
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            QuizResultCard(
              correct: r.correct,
              total: r.total,
              stub: r.newRecord
                  ? QuizStubBadge(
                      text: 'Nuevo récord',
                      icon: AppIcon.trophy.widget(size: 22),
                    )
                  : Text(
                      'Tu récord: ${r.best}/${r.total}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: quizInk.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            QuizCupSection(
              roundId: r.roundId,
              gameId: 'geografia',
              correct: r.correct,
              total: r.total,
              color: geoColor,
            ),
            if (r.mistakes.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                'FALLOS (${r.mistakes.length})',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              for (final m in r.mistakes) _MistakeTile(m, map: map),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go('/game/geografia'),
                child: const Text('Cambiar ajustes'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: geoColor,
                  foregroundColor: const Color(0xFF042320),
                ),
                onPressed: () =>
                    context.pushReplacement('/game/geografia/play'),
                icon: AppIcon.replay.widget(color: const Color(0xFF042320)),
                label: const Text('Otra vuelta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeTile extends StatelessWidget {
  const _MistakeTile(this.mistake, {this.map});

  final QuizMistake mistake;
  final GeoMap? map;

  @override
  Widget build(BuildContext context) {
    final q = mistake.question;
    final (title, subtitle) = switch (q.kind) {
      QuestionKind.flag ||
      QuestionKind.silhouette ||
      QuestionKind.region => (q.answer, null),
      QuestionKind.capital => ('Capital de ${q.country!.name}', q.answer),
      QuestionKind.capitalOwner => (
        q.country!.capital,
        'Es la capital de ${q.answer}',
      ),
    };
    final given = mistake.given == null || mistake.given!.trim().isEmpty
        ? 'Sin respuesta'
        : 'Dijiste: ${mistake.given!.trim()}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (q.region != null)
                SizedBox(
                  width: 56,
                  height: 42,
                  child: map == null
                      ? null
                      : RegionMapView(map: map!, highlightId: q.region!.id),
                )
              else
                FlagView(q.country!, width: 56, radius: 6),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: geoColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      given,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
