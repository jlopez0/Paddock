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
import 'game_colors.dart';
import 'level_chips.dart';
import 'bounce_in.dart';
import 'prompt_deck_logic.dart';
import 'prompt_deck_module.dart';
import 'setup_hero.dart';

/// Mazo de retos que alimenta al [ConsequenceBanner] en los modos Retos y Sorbos.
const promptRetosAsset = 'assets/content/es/retos.json';

/// Prefijo del estilo [PromptCardStyle.question] (el cierre "?" lo pone la tarjeta).
const kQuestionPrefix = '¿Quién es más probable que';

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
            count == 0 ? 'Sin nivel no hay mazo' : 'Jugar',
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

  /// Apuesta anunciada por cada carta (solo en [PromptPayMode.stake]).
  List<int> _stakes = const [];

  /// Cartas ya vistas en esta sesión de pantalla: la partida siguiente no las repite.
  Set<String> _played = {};

  void _shuffle(List<Prompt> all) {
    final random = Random();
    final draw = drawDeck(
      all: all,
      levels: widget.levels,
      played: _played,
      rounds: widget.game.rounds,
      random: random,
    );
    _deck = draw.cards;
    _played = draw.played;
    _stakes = widget.game.payMode == PromptPayMode.stake
        ? rollStakes(draw.cards.length, random)
        : const [];
    _index = 0;
  }

  /// Apuesta de la carta [index], o `null` si el juego no anuncia apuestas.
  int? _stakeAt(int index) =>
      index >= 0 && index < _stakes.length ? _stakes[index] : null;

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('Pierdes el sitio en la partida.'),
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
    context.go('/');
  }

  void _go(int delta) {
    final deck = _deck!;
    final next = _index + delta;
    if (next < 0 || next > deck.length) return;
    AppFeedback.selection();
    playSound(AppSound.card);
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));

    return PopScope(
      // Con el mazo a medias, salir (X, atrás o atrás predictivo) pide confirmación.
      canPop: finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
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
                                    // Solo el número de carta: nunca el total del mazo.
                                    'Carta ${_index + 1}',
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
                // Aire bajo la cabecera.
                const SizedBox(height: 10),
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
                              : _PromptCard(
                                  game: game,
                                  prompt: deck[_index],
                                  stake: _stakeAt(_index),
                                  mode: mode,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!finished && _stakeAt(_index) != null)
                  _ConsequenceSection(
                    bannerKey: const ValueKey('stake-banner'),
                    who: _ConsequenceSection.stakeWho,
                    chips: _stakeAt(_index)!,
                    cardIndex: _index,
                    retoOnly: true,
                  ),
                if (!finished && game.payMode == PromptPayMode.fixed)
                  _ConsequenceSection(
                    bannerKey: const ValueKey('fixed-banner'),
                    who: _ConsequenceSection.fixedWho,
                    chips: kPromptFixedChips,
                    cardIndex: _index,
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

/// Lo que le toca a [who] en Retos y Sorbos, con el tope de 3 y, en Sorbos, la alternativa
/// de agua o reto siempre visible (todo lo resuelve [ConsequenceBanner]). Sirve al "más
/// señalado" de una apuesta y a "Quien lo haya hecho" de Yo nunca. En modo Fichas no
/// muestra nada: no se anota nada en la Copa y la mesa lo resuelve sola.
class _ConsequenceSection extends ConsumerWidget {
  const _ConsequenceSection({
    required this.bannerKey,
    required this.who,
    required this.chips,
    required this.cardIndex,
    this.retoOnly = false,
  });

  /// La cantidad ya la dice el titular de la carta: aquí solo el reto concreto.
  final bool retoOnly;

  final Key bannerKey;
  final String who;
  final int chips;
  final int cardIndex;

  /// Quién paga una apuesta: nadie en concreto, lo decide la mesa al señalar.
  static const stakeWho = 'El más señalado';

  /// Quién cumple en Yo nunca: nadie marcado, lo dice cada uno.
  static const fixedWho = 'Quien lo haya hecho';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    if (mode == ConsequenceMode.puntos) return const SizedBox.shrink();
    // En Sorbos el titular de la carta ya lo dice todo: nada que añadir.
    if (retoOnly && mode == ConsequenceMode.sorbos) {
      return const SizedBox.shrink();
    }
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
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          // Hueco reservado: pasar de carta no mueve el resto de la pantalla.
          minHeight: MediaQuery.textScalerOf(
            context,
          ).scale(mode == ConsequenceMode.retos ? 78 : 60).clamp(0, maxHeight),
        ),
        child: SingleChildScrollView(
          child: ConsequenceBanner(
            key: bannerKey,
            losses: {who: chips},
            mode: mode,
            retos: retos,
            retoOnly: retoOnly,
          ),
        ),
      ),
    );
  }
}

/// La carta es un boleto de papel: cuerpo con el nivel y el enunciado, y la
/// regla en la matriz, bajo la línea de puntos.
class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.game,
    required this.prompt,
    required this.mode,
    this.stake,
  });

  final PromptDeckModule game;
  final Prompt prompt;

  /// Apuesta de la carta, si el juego las usa. Solo se ve en Retos y Sorbos.
  final int? stake;

  final ConsequenceMode mode;

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
                    if (stake != null &&
                        stakeHeadline(stake!, mode) != null) ...[
                      _StakeHeadline(stake: stake!, mode: mode, accent: accent),
                      const SizedBox(height: 12),
                    ],
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

/// "¡Por 2 retos!" o "Por 2 sorbos · o agua o reto" sobre la pregunta. Es la única
/// fuente de la cantidad (sin icono de ficha: el texto ya habla de retos o sorbos).
/// Nunca se pinta en modo Fichas.
class _StakeHeadline extends StatelessWidget {
  const _StakeHeadline({
    required this.stake,
    required this.mode,
    required this.accent,
  });

  final int stake;
  final ConsequenceMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            stakeHeadline(stake, mode) ?? '',
            textAlign: TextAlign.center,
            textScaler: MediaQuery.textScalerOf(
              context,
            ).clamp(maxScaleFactor: 1.5),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w400,
              fontSize: 24,
              height: 1.2,
              color: accent,
            ),
          ),
        ),
      ],
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
                  'Fin de la partida',
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
                  label: const Text('Otra partida'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
