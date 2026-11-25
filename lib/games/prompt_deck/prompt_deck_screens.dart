import '../../core/help/how_to_play.dart';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import '../../core/audio/app_sound.dart';
import '../../core/settings/app_feedback.dart';
import '../../core/settings/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_icons.dart';
import '../../app/mascot.dart';
import '../../app/theme.dart';
import '../../core/consequences/consequence_banner.dart';
import '../../core/consequences/consequences.dart';
import '../../core/consequences/retos_filter.dart';
import '../../core/content/prompts.dart';
import '../../core/players/player.dart';
import '../../core/players/player_widgets.dart';
import '../../core/players/players_controller.dart';
import '../../core/session/session_controller.dart';
import 'game_colors.dart';
import 'level_chips.dart';
import 'bounce_in.dart';
import 'prompt_deck_module.dart';
import 'setup_hero.dart';

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
    if (!_levels.contains(level)) {
      final ok = await ensureLevelAllowed(context, ref, level);
      if (!ok || !mounted) return;
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
      appBar: AppBar(actions: [HowToPlayButton(game.id)]),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            SetupHero(
              gameId: game.id,
              title: game.title,
              color: game.color,
              hook: game.subtitle,
              detail: game.rule,
            ),
            const SizedBox(height: 24),
            BrassCard(
              label: 'Nivel',
              child: LevelChips(
                levels: _levels,
                color: game.color,
                onToggle: _toggle,
              ),
            ),
            if (prompts.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'No se pudo cargar el contenido. Vuelve atrás e inténtalo de nuevo.',
                  style: TextStyle(color: AppColors.danger),
                ),
              ),
          ],
        ),
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
            count == 0 ? 'Sin nivel no hay mazo' : 'Jugar · $count cartas',
          ),
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
    AppFeedback.light();
    setState(() {
      final set = _marks.putIfAbsent(_index, () => <String>{});
      if (!set.remove(playerId)) {
        set.add(playerId);
        playSound(AppSound.chipSoft);
      }
    });
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text(
          'Pierdes el sitio en el mazo. '
          'Las fichas ya marcadas se quedan en la Copa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _commit(_index);
    context.pop();
  }

  void _go(int delta) {
    final deck = _deck!;
    final next = _index + delta;
    if (next < 0 || next > deck.length) return;
    AppFeedback.selection();
    playSound(AppSound.card);
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
      if (async.hasError) {
        return Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se pudo cargar el contenido. Vuelve atrás e inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_deck == null) _shuffle(all);
    final deck = _deck!;
    final finished = _index >= deck.length;
    final players = game.payMode == PromptPayMode.none
        ? const <Player>[]
        : ref.watch(playersProvider);
    final showPay = players.isNotEmpty && !finished;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return PopScope(
      // Con el mazo a medias, salir (X, atrás o atrás predictivo) pide confirmación.
      // Las fichas de la carta actual marcadas no se pierden: se registran al salir.
      canPop: finished,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _commit(_index);
          return;
        }
        _confirmExit();
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
                      SizedBox(
                        width: 72,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Salir',
                            icon: AppIcon.close.widget(),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: DefaultTextStyle(
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppFonts.display,
                            fontWeight: FontWeight.w400,
                            fontSize: kDisplayMinSize,
                            color: AppColors.text,
                          ),
                          child: AppTitle(game.title),
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        child: finished
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${_index + 1} / ${deck.length}',
                                    style: const TextStyle(
                                      color: GameColors.mutedText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                // Aire bajo la cabecera: con el título a dos líneas no toca la barra.
                const SizedBox(height: 10),
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
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        // La carta entra deslizándose y con un giro leve, como
                        // una carta que se reparte sobre el fieltro.
                        transitionBuilder: (child, a) {
                          final incoming = child.key == ValueKey(_index);
                          final dx = (_forward == incoming) ? 1.0 : -1.0;
                          return SlideTransition(
                            position: Tween(
                              begin: Offset(dx * 0.6, 0),
                              end: Offset.zero,
                            ).animate(a),
                            child: RotationTransition(
                              turns: Tween(
                                begin: dx * 0.015,
                                end: 0.0,
                              ).animate(a),
                              child: FadeTransition(opacity: a, child: child),
                            ),
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
                        icon: AppIcon.undo.widget(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          finished ? '' : 'Toca o desliza: siguiente carta',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textScaler: MediaQuery.textScalerOf(
                            context,
                          ).clamp(maxScaleFactor: 1.3),
                          style: const TextStyle(
                            color: GameColors.mutedText,
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
    final retosAll = retosPrompts == null
        ? null
        : filterRetos(retosPrompts, adultConfirmed: adult);
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
              Row(
                children: [
                  Flexible(
                    child: Text(
                      '¿Quién paga? · $kPromptPayChips ficha',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ChipToken(kPromptPayChips, size: 22),
                ],
              ),
              Text(
                locked ? 'Ya anotado en la Copa' : game.payHint,
                style: const TextStyle(
                  color: GameColors.mutedText,
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
                      avatar: _MarkAvatar(
                        player: p,
                        marked: marked.contains(p.id),
                      ),
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
              const SizedBox(height: 8),
              // Hueco reservado: marcar o desmarcar no mueve el resto de la pantalla.
              // Si hay más marcados de los que caben en el hueco, crece con animación.
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.textScalerOf(context).scale(
                      switch (mode) {
                        ConsequenceMode.puntos => 22,
                        ConsequenceMode.retos => 78,
                        ConsequenceMode.sorbos => 60,
                      },
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: names.isEmpty
                        ? const SizedBox.shrink()
                        : mode == ConsequenceMode.puntos
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ChipToken(kPromptPayChips, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '−$kPromptPayChips en la Copa: ${names.join(', ')}',
                                  style: const TextStyle(
                                    color: GameColors.mutedText,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ConsequenceBanner(
                            losses: {for (final n in names) n: kPromptPayChips},
                            mode: mode,
                            retos: retos,
                          ),
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

/// Avatar del chip de jugador: la inicial y, al marcarlo, una ficha que entra
/// con rebote (la ficha que va a pagar).
class _MarkAvatar extends StatelessWidget {
  const _MarkAvatar({required this.player, required this.marked});

  final Player player;
  final bool marked;

  static const _size = 26.0;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: _size,
      height: _size,
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
        switchInCurve: Curves.elasticOut,
        switchOutCurve: Curves.easeIn,
        // Solo escala: el rebote de elasticOut supera 1 y no vale para opacidad.
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: marked
            ? const ChipToken(
                kPromptPayChips,
                key: ValueKey('ficha'),
                size: _size,
              )
            : PlayerAvatar(player, key: const ValueKey('inicial'), size: _size),
      ),
    );
  }
}

/// La carta es un boleto de papel: cuerpo con el nivel y el enunciado, y la
/// regla en la matriz, bajo la línea de puntos.
class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.game, required this.prompt});

  final PromptDeckModule game;
  final Prompt prompt;

  @override
  Widget build(BuildContext context) {
    final accent = GameColors.onPaper(game.color);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              child: TicketCard(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                stub: Text(
                  game.rule,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GameColors.inkMuted,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _LevelPill(level: prompt.level),
                    ),
                    const SizedBox(height: 18),
                    switch (game.style) {
                      PromptCardStyle.statement => _Statement(
                        prefix: prompt['prefijo'].isEmpty
                            ? game.prefix
                            : prompt['prefijo'],
                        text: prompt['texto'],
                        accent: accent,
                      ),
                      PromptCardStyle.choice => _Choice(
                        a: prompt['a'],
                        b: prompt['b'],
                        accent: accent,
                        accentB: GameColors.onPaper(const Color(0xFF4FA3F7)),
                      ),
                      PromptCardStyle.question => _Statement(
                        prefix: kQuestionPrefix,
                        text: prompt['texto'],
                        accent: accent,
                        closing: '?',
                      ),
                    },
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nivel de la carta: icono dibujado + texto, en una pastilla oscura sobre el papel.
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final PromptLevel level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LevelLabel(
        level,
        iconSize: 18,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    );
  }
}

/// Enunciado de la carta. Corto: Alfa Slab One (tipografía de cartelería, con la
/// escala del sistema limitada para que no rompa palabras). Largo: Figtree 700,
/// que se lee mejor en varias líneas.
class _Statement extends StatelessWidget {
  const _Statement({
    required this.prefix,
    required this.text,
    required this.accent,
    this.closing = '.',
  });

  final String? prefix;
  final String text;
  final Color accent;
  final String closing;

  /// Hasta este largo (prefijo incluido) se usa la tipografía de ceremonia.
  static const shortLimit = 70;

  @override
  Widget build(BuildContext context) {
    final total =
        (prefix == null ? 0 : prefix!.length + 1) +
        text.length +
        closing.length;
    final short = total <= shortLimit;
    final style = short
        ? const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w400,
            fontSize: 26,
            height: 1.25,
            color: GameColors.ink,
          )
        : const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w700,
            fontSize: 26,
            height: 1.3,
            color: GameColors.ink,
          );
    return Text.rich(
      TextSpan(
        children: [
          if (prefix != null)
            TextSpan(
              text: '$prefix ',
              style: TextStyle(
                color: accent,
                fontWeight: short ? FontWeight.w400 : FontWeight.w900,
              ),
            ),
          TextSpan(text: '$text$closing'),
        ],
      ),
      textAlign: TextAlign.center,
      style: style,
      textScaler: short
          ? MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5)
          : null,
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.a,
    required this.b,
    required this.accent,
    required this.accentB,
  });

  final String a;
  final String b;
  final Color accent;
  final Color accentB;

  @override
  Widget build(BuildContext context) {
    Widget option(String text, Color c) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: GameColors.ink,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¿Qué preferirías?',
          textAlign: TextAlign.center,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.5),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w400,
            color: accent,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 14),
        option(a, accent),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '— o —',
            style: TextStyle(
              color: GameColors.inkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        option(b, accentB),
      ],
    );
  }
}

class _EndCard extends StatefulWidget {
  const _EndCard({required this.color, required this.onRestart});

  final Color color;
  final VoidCallback onRestart;

  @override
  State<_EndCard> createState() => _EndCardState();
}

class _EndCardState extends State<_EndCard> {
  @override
  void initState() {
    super.initState();
    AppFeedback.light();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BounceIn(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.confetti.widget(size: 44),
                      const SizedBox(width: 8),
                      const Jockey(pose: JockeyPose.celebra, size: 96),
                      const SizedBox(width: 8),
                      AppIcon.confetti.widget(size: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Se acabó el mazo',
                  textAlign: TextAlign.center,
                  textScaler: MediaQuery.textScalerOf(
                    context,
                  ).clamp(maxScaleFactor: 1.5),
                  style: const TextStyle(
                    fontFamily: AppFonts.display,
                    fontWeight: FontWeight.w400,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: widget.onRestart,
                  icon: AppIcon.shuffle.widget(color: Colors.black),
                  label: const Text('Barajar de nuevo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
