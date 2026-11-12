import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
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
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('No hay ninguna partida')));
    }
    final mapId = r.setup.category.mapId;
    final map = mapId == null ? null : ref.watch(geoMapProvider(mapId)).value;
    final ratio = r.total == 0 ? 0.0 : r.correct / r.total;
    final message = switch (ratio) {
      1.0 => '¡Perfecto! 🌍',
      >= 0.8 => '¡Gran nivel!',
      >= 0.5 => 'Nada mal',
      _ => 'A seguir practicando',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => context.go('/')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(child: _ScoreRing(ratio: ratio, correct: r.correct, total: r.total)),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          if (r.newRecord)
            const Text('🏆 ¡Nuevo récord!',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800))
          else
            Text('Tu récord: ${r.best}/${r.total}',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
          if (r.mistakes.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text('FALLOS (${r.mistakes.length})',
                style: const TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12)),
            const SizedBox(height: 10),
            for (final m in r.mistakes) _MistakeTile(m, map: map),
          ],
        ],
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
                style: FilledButton.styleFrom(backgroundColor: geoColor, foregroundColor: const Color(0xFF042320)),
                onPressed: () => context.pushReplacement('/game/geografia/play'),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Otra vez'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.ratio, required this.correct, required this.total});

  final double ratio;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => SizedBox(
        width: 190,
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 190,
              height: 190,
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                color: geoColor,
                backgroundColor: AppColors.surfaceHigh,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$correct', style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, height: 1)),
                Text('de $total', style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
              ],
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
      QuestionKind.flag || QuestionKind.silhouette || QuestionKind.region => (q.answer, null),
      QuestionKind.capital => ('Capital de ${q.country!.name}', q.answer),
      QuestionKind.capitalOwner => (q.country!.capital, 'Es la capital de ${q.answer}'),
    };
    final given = mistake.given == null || mistake.given!.trim().isEmpty ? 'Sin respuesta' : 'Dijiste: ${mistake.given!.trim()}';
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
                  child: map == null ? null : RegionMapView(map: map!, highlightId: q.region!.id),
                )
              else
                FlagView(q.country!, width: 56, radius: 6),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    if (subtitle != null)
                      Text(subtitle, style: const TextStyle(color: geoColor, fontWeight: FontWeight.w700)),
                    Text(given, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
