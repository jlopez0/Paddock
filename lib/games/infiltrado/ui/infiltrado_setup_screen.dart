import '../../../core/help/how_to_play.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme.dart';
import '../../../core/content/prompts.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../../../core/settings/app_feedback.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/infiltrado_engine.dart';
import '../infiltrado_store.dart';

class InfiltradoSetupScreen extends ConsumerStatefulWidget {
  const InfiltradoSetupScreen({super.key});

  @override
  ConsumerState<InfiltradoSetupScreen> createState() => _InfiltradoSetupScreenState();
}

class _InfiltradoSetupScreenState extends ConsumerState<InfiltradoSetupScreen> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(infiltradoSetupProvider).playerIds;
    _selected = saved != null
        ? {...saved}
        : {for (final p in ref.read(playersProvider)) p.id};
  }

  InfiltradoSetup get _setup => ref.read(infiltradoSetupProvider);

  void _update(InfiltradoSetup Function(InfiltradoSetup) f) {
    ref.read(infiltradoSetupProvider.notifier).set(f(_setup.copyWith(playerIds: {..._selected})));
  }

  void _toggle(Player p) {
    AppFeedback.selection();
    setState(() {
      if (!_selected.remove(p.id)) _selected.add(p.id);
    });
    _update((s) => s);
  }

  Future<void> _toggleLevel(PromptLevel level) async {
    AppFeedback.selection();
    final levels = {..._setup.levels};
    if (!levels.contains(level) &&
        level == PromptLevel.atrevido &&
        !ref.read(settingsProvider).adultConfirmed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Solo para mayores de 18'),
          content: const Text(
            'El nivel Atrevido incluye contenido para adultos. '
            'Actívalo solo si todos los presentes son mayores de edad.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Tengo 18 o más')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
      ref.read(settingsProvider.notifier).confirmAdult();
    }
    if (!levels.remove(level)) levels.add(level);
    if (levels.isEmpty) return; // siempre queda un nivel activo
    _update((s) => s.copyWith(levels: levels));
  }

  void _start(List<Player> chosen, List<InfiltradoWord> words) {
    _update((s) => s);
    final result = ref
        .read(infiltradoGameProvider.notifier)
        .start(players: chosen, setup: _setup, words: words);
    if (result == InfiltradoStart.ok) context.push('/game/infiltrado/reveal');
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);
    final setup = ref.watch(infiltradoSetupProvider);
    final used = ref.watch(infiltradoUsedProvider);
    final wordsAsync = ref.watch(infiltradoWordsProvider);
    final words = wordsAsync.asData?.value;

    final ids = {for (final p in players) p.id};
    _selected.retainAll(ids);
    final chosen = [for (final p in players) if (_selected.contains(p.id)) p];
    final enough = chosen.length >= InfiltradoEngine.minPlayers;
    final maxImpostors = InfiltradoEngine.maxImpostors(chosen.length);
    final impostors = setup.impostors.clamp(1, maxImpostors < 1 ? 1 : maxImpostors);

    final available = words == null ? null : availableWords(words, setup.levels, used);
    final exhausted = available != null && available.isEmpty;

    String buttonLabel;
    VoidCallback? onPressed;
    if (!enough) {
      buttonLabel = 'Elige al menos ${InfiltradoEngine.minPlayers} jugadores';
    } else if (words == null) {
      buttonLabel = wordsAsync.hasError ? 'No se pudieron cargar las palabras' : 'Cargando palabras…';
    } else if (exhausted) {
      buttonLabel = 'No quedan palabras';
    } else {
      buttonLabel = 'Repartir roles';
      onPressed = () => _start(chosen, words);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('El Infiltrado'), actions: const [HowToPlayButton('infiltrado')]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Todos reciben la misma palabra menos el infiltrado, que solo conoce la '
                  'categoría. Debatid y votad: si lo pilláis, pierde 2 fichas; si se escapa, '
                  'los demás pierden 1 cada uno.',
                ),
              ),
            ),
            const _SectionTitle('¿Quién juega?'),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Añade jugadores para empezar.', style: TextStyle(color: AppColors.textMuted)),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in players)
                  FilterChip(
                    avatar: PlayerAvatar(p, size: 24),
                    label: Text(p.name),
                    selected: _selected.contains(p.id),
                    showCheckmark: false,
                    onSelected: (_) => _toggle(p),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AddPlayerField(
              onAdded: (p) {
                setState(() => _selected.add(p.id));
                _update((s) => s);
              },
            ),
            if (!enough)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Hacen falta al menos ${InfiltradoEngine.minPlayers} jugadores '
                  '(ahora: ${chosen.length}).',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            const _SectionTitle('Infiltrados'),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: const Text('2'), enabled: maxImpostors >= 2),
              ],
              selected: {impostors},
              onSelectionChanged: (s) {
                AppFeedback.selection();
                _update((v) => v.copyWith(impostors: s.first));
              },
            ),
            if (maxImpostors < 2)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Con 2 infiltrados hacen falta 5 jugadores o más.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            const _SectionTitle('Nivel de las palabras'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in PromptLevel.values)
                  FilterChip(
                    label: Text('${level.emoji} ${level.label}'),
                    selected: setup.levels.contains(level),
                    showCheckmark: false,
                    onSelected: (_) => _toggleLevel(level),
                  ),
              ],
            ),
            if (available != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  exhausted
                      ? 'No quedan palabras con estos niveles.'
                      : '${available.length} palabras disponibles',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
            if (exhausted) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.read(infiltradoUsedProvider.notifier).reset(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Volver a empezar con todas'),
              ),
            ],
            const _SectionTitle('Debate'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in kDebateOptions)
                  ChoiceChip(
                    label: Text(s == 0 ? 'Sin temporizador' : '${s ~/ 60} min'),
                    selected: setup.debateSeconds == s,
                    onSelected: (_) {
                      AppFeedback.selection();
                      _update((v) => v.copyWith(debateSeconds: s));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(onPressed: onPressed, child: Text(buttonLabel, textAlign: TextAlign.center)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
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
