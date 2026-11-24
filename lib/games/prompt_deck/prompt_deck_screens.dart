import 'dart:math';

import 'package:material_ui/material_ui.dart';
import '../../core/settings/app_feedback.dart';
import '../../core/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/consequences/consequence_banner.dart';
import '../../core/consequences/consequences.dart';
import '../../core/consequences/retos_filter.dart';
import '../../core/content/prompts.dart';
import '../../core/players/player.dart';
import '../../core/players/player_widgets.dart';
import '../../core/players/players_controller.dart';
import '../../core/session/session_controller.dart';
import 'prompt_deck_module.dart';

/// Mazo de retos que alimenta al [ConsequenceBanner] en los modos Retos y Sorbos.
const promptRetosAsset = 'assets/content/es/retos.json';

/// Prefijo del estilo [PromptCardStyle.question] (el cierre "?" lo pone la tarjeta).
const kQuestionPrefix = '¿Quién es más probable que';

/// Id de ronda de una carta en la Copa: carta + posición + partida, para que ver la misma
/// carta otra vez (deshacer, barajar, otra partida de la noche) no choque con `award`.
String promptRoundId(String cardId, int index, String run) =>
    '$cardId+$index@$run';

class PromptDeckSetupScreen extends ConsumerStatefulWidget {
  const PromptDeckSetupScreen({super.key, required this.game});

  final PromptDeckModule game;

  @override
  ConsumerState<PromptDeckSetupScreen> createState() =>
      _PromptDeckSetupScreenState();
}

class _PromptDeckSetupScreenState extends ConsumerState<PromptDeckSetupScreen> {
  // Atrevido arranca desactivado: exige confirmar +18 al activarlo.
  final Set<PromptLevel> _levels = {PromptLevel.suave, PromptLevel.picante};

  Future<void> _toggle(PromptLevel level) async {
    AppFeedback.selection();
    if (!_levels.contains(level) &&
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
      if (ok != true || !mounted) return;
      ref.read(settingsProvider.notifier).confirmAdult();
    }
    setState(() {
      if (!_levels.remove(level)) _levels.add(level);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final prompts = ref.watch(promptsProvider(game.contentAsset));
    final count =
        prompts.whenOrNull(
          data: (p) => p.where((x) => _levels.contains(x.level)).length,
        ) ??
        0;

    return Scaffold(
      appBar: AppBar(title: Text(game.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(child: Text(game.emoji, style: const TextStyle(fontSize: 72))),
          const SizedBox(height: 12),
          Text(
            game.rule,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 32),
          const Text(
            'NIVEL',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          for (final level in PromptLevel.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LevelTile(
                level: level,
                color: game.color,
                selected: _levels.contains(level),
                onTap: () => _toggle(level),
              ),
            ),
          if (prompts.hasError)
            Text(
              'No se pudo cargar el contenido: ${prompts.error}',
              style: const TextStyle(color: AppColors.danger),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton(
          onPressed: count == 0
              ? null
              : () => context.push(
                  '${game.path}/play?levels=${_levels.map((l) => l.name).join(',')}',
                ),
          child: Text(
            count == 0 ? 'Elige al menos un nivel' : 'Empezar · $count cartas',
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final PromptLevel level;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(level.emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                level.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? color : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class PromptDeckPlayScreen extends ConsumerStatefulWidget {
  const PromptDeckPlayScreen({
    super.key,
    required this.game,
    required this.levels,
  });

  final PromptDeckModule game;
  final Set<PromptLevel> levels;

  @override
  ConsumerState<PromptDeckPlayScreen> createState() =>
      _PromptDeckPlayScreenState();
}

class _PromptDeckPlayScreenState extends ConsumerState<PromptDeckPlayScreen> {
  List<Prompt>? _deck;
  int _index = 0;
  bool _forward = true;

  /// Identifica esta partida (y cada barajada) dentro de la noche.
  final String _run = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  int _pass = 0;

  /// Jugadores marcados por posición de carta.
  final Map<int, Set<String>> _marks = {};

  /// Posiciones cuyas fichas ya están en la Copa (sus chips quedan bloqueados).
  final Set<int> _awarded = {};

  void _shuffle(List<Prompt> all) {
    _deck = all.where((p) => widget.levels.contains(p.level)).toList()
      ..shuffle(Random());
    _index = 0;
    _pass++;
    _marks.clear();
    _awarded.clear();
  }

  String get _runId => '$_run.$_pass';

  /// Registra en la Copa las fichas de la carta [index] (una sola vez por carta).
  void _commit(int index) {
    final deck = _deck;
    if (deck == null || index < 0 || index >= deck.length) return;
    if (widget.game.payMode == PromptPayMode.none || _awarded.contains(index)) {
      return;
    }
    final marked = _marks[index];
    if (marked == null || marked.isEmpty) return;
    final known = ref.read(playersProvider).map((p) => p.id).toSet();
    final deltas = {
      for (final id in marked)
        if (known.contains(id)) id: -kPromptPayChips,
    };
    if (deltas.isEmpty) return;
    ref
        .read(sessionProvider.notifier)
        .award(
          promptRoundId(deck[index].id, index, _runId),
          widget.game.id,
          deltas,
        );
    _awarded.add(index);
  }

  void _toggleMark(String playerId) {
    if (_awarded.contains(_index)) return;
    AppFeedback.selection();
    setState(() {
      final set = _marks.putIfAbsent(_index, () => <String>{});
      if (!set.remove(playerId)) set.add(playerId);
    });
  }

  void _go(int delta) {
    final deck = _deck!;
    final next = _index + delta;
    if (next < 0 || next > deck.length) return;
    AppFeedback.selection();
    _commit(_index);
    setState(() {
      _forward = delta > 0;
      _index = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final async = ref.watch(promptsProvider(game.contentAsset));
    final all = async.value;
    if (all == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_deck == null) _shuffle(all);
    final deck = _deck!;
    final finished = _index >= deck.length;
    final players = game.payMode == PromptPayMode.none
        ? const <Player>[]
        : ref.watch(playersProvider);
    final showPay = players.isNotEmpty && !finished;

    return PopScope(
      // Salir con las fichas de la carta actual marcadas no las pierde: se registran al cerrar.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _commit(_index);
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                game.color.withValues(alpha: 0.35),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Salir',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Text(
                          game.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          finished ? '' : '${_index + 1}/${deck.length}',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: deck.isEmpty ? 0 : min(1, _index / deck.length),
                      minHeight: 4,
                      color: game.color,
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(1),
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v < -200) _go(1);
                      if (v > 200) _go(-1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, a) {
                          final incoming = child.key == ValueKey(_index);
                          final dx = (_forward == incoming) ? 1.0 : -1.0;
                          return SlideTransition(
                            position: Tween(
                              begin: Offset(dx * 0.6, 0),
                              end: Offset.zero,
                            ).animate(a),
                            child: FadeTransition(opacity: a, child: child),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(_index),
                          child: finished
                              ? _EndCard(
                                  color: game.color,
                                  onRestart: () =>
                                      setState(() => _shuffle(all)),
                                )
                              : _PromptCard(game: game, prompt: deck[_index]),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showPay)
                  _PaySection(
                    game: game,
                    players: players,
                    marked: _marks[_index] ?? const {},
                    locked: _awarded.contains(_index),
                    cardIndex: _index,
                    onToggle: _toggleMark,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Anterior',
                        onPressed: _index > 0 ? () => _go(-1) : null,
                        icon: const Icon(Icons.undo_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          finished ? '' : 'Toca o desliza para la siguiente',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila "¿Quién paga?": chips de jugadores y, en Retos/Sorbos, lo que le toca a cada marcado.
class _PaySection extends ConsumerWidget {
  const _PaySection({
    required this.game,
    required this.players,
    required this.marked,
    required this.locked,
    required this.cardIndex,
    required this.onToggle,
  });

  final PromptDeckModule game;
  final List<Player> players;
  final Set<String> marked;
  final bool locked;
  final int cardIndex;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    final names = [
      for (final p in players)
        if (marked.contains(p.id)) p.name,
    ];
    final adult = ref.watch(settingsProvider.select((s) => s.adultConfirmed));
    final retosPrompts = mode == ConsequenceMode.retos
        ? ref.watch(promptsProvider(promptRetosAsset)).asData?.value
        : null;
    final retosAll =
        retosPrompts == null ? null : filterRetos(retosPrompts, adultConfirmed: adult);
    // Se rota el mazo según la carta para no repetir siempre el primer reto.
    final retos = (retosAll == null || retosAll.isEmpty)
        ? retosAll
        : [
            ...retosAll.skip((cardIndex * 3) % retosAll.length),
            ...retosAll.take((cardIndex * 3) % retosAll.length),
          ];
    final maxHeight = MediaQuery.sizeOf(context).height * 0.3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Quién paga? · $kPromptPayChips ficha',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(
                locked ? 'Ya registrado en la Copa' : game.payHint,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in players)
                    FilterChip(
                      key: ValueKey('pay-${p.id}'),
                      selected: marked.contains(p.id),
                      showCheckmark: false,
                      avatar: PlayerAvatar(p, size: 24),
                      label: Text(p.name),
                      selectedColor: game.color.withValues(alpha: 0.3),
                      side: BorderSide(
                        color: marked.contains(p.id)
                            ? game.color
                            : AppColors.outline,
                      ),
                      onSelected: locked ? null : (_) => onToggle(p.id),
                    ),
                ],
              ),
              if (names.isNotEmpty) ...[
                const SizedBox(height: 8),
                if (mode == ConsequenceMode.puntos)
                  Text(
                    '−$kPromptPayChips en la Copa: ${names.join(', ')}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  )
                else
                  ConsequenceBanner(
                    losses: {for (final n in names) n: kPromptPayChips},
                    mode: mode,
                    retos: retos,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.game, required this.prompt});

  final PromptDeckModule game;
  final Prompt prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: game.color.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: game.color.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${prompt.level.emoji} ${prompt.level.label}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: switch (game.style) {
                PromptCardStyle.statement => _Statement(
                  prefix: prompt['prefijo'].isEmpty
                      ? game.prefix
                      : prompt['prefijo'],
                  text: prompt['texto'],
                  color: game.color,
                ),
                PromptCardStyle.choice => _Choice(
                  a: prompt['a'],
                  b: prompt['b'],
                  color: game.color,
                ),
                PromptCardStyle.question => _Statement(
                  prefix: kQuestionPrefix,
                  text: prompt['texto'],
                  color: game.color,
                  closing: '?',
                ),
              },
            ),
          ),
          Text(
            game.rule,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Statement extends StatelessWidget {
  const _Statement({
    required this.prefix,
    required this.text,
    required this.color,
    this.closing = '.',
  });

  final String? prefix;
  final String text;
  final Color color;
  final String closing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Text.rich(
        TextSpan(
          children: [
            if (prefix != null)
              TextSpan(
                text: '$prefix ',
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            TextSpan(text: '$text$closing'),
          ],
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.a, required this.b, required this.color});

  final String a;
  final String b;
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget option(String text, Color c) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '¿Qué preferirías?',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          option(a, color),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '— o —',
              style: TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          option(b, const Color(0xFF4FA3F7)),
        ],
      ),
    );
  }
}

class _EndCard extends StatelessWidget {
  const _EndCard({required this.color, required this.onRestart});

  final Color color;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎉', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 12),
        const Text(
          '¡Se acabaron las cartas!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRestart,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Barajar otra vez'),
        ),
      ],
    );
  }
}
