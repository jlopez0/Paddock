import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../core/audio/app_sound.dart';
import '../core/consequences/consequences.dart';
import '../core/help/how_to_play.dart';
import '../core/players/player.dart';
import '../core/players/player_widgets.dart';
import '../core/players/players_controller.dart';
import '../core/session/cup_presentation.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_score.dart';
import '../core/settings/app_feedback.dart';
import '../core/settings/settings_controller.dart';
import '../games/registry.dart';
import 'app_icons.dart';
import 'app_info.dart';
import 'mascot.dart';
import 'theme.dart';

/// Comparte un texto con la hoja del sistema. Los tests lo sustituyen.
final shareTextProvider = Provider<Future<void> Function(String text)>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

/// Enlace de la app para el texto de compartir. Vacío hasta que haya URL de tienda.
const kShareLink = '';

/// Saldo con signo: `+5`, `0`, `-2`.
String _signed(int n) => n > 0 ? '+$n' : '$n';

String _chips(int n) =>
    '${_signed(n)} ${n == 1 || n == -1 ? 'ficha' : 'fichas'}';

/// Verde si es positivo; neutro en cero y en negativo (la Copa no marca pérdidas en rojo).
Color _balanceColor(int n) => n > 0 ? AppColors.success : AppColors.textMuted;

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Solo se celebra (trofeo, medallas, confeti, "Va en cabeza") si quien manda tiene
/// fichas a favor. A cero o en negativo, la Copa constata y no corona a nadie.
bool _celebrates(RankGroup leaders) => leaders.total > 0;

String _noPositiveTitle(bool finished) =>
    finished ? 'Nadie ha acabado en positivo' : 'Nadie va en positivo';

/// Juegos que apuntan a la Copa y se ofrecen con [mode] (sin Carrera en Retos, D21). Sale
/// del registro: nada fijo en el texto. Lo ya anotado de una noche no se borra al cambiar de modo.
List<String> _countingTitles(ConsequenceMode mode) => [
  for (final g in gamesFor(mode))
    if (g.scoresCup) g.title,
];

/// "Aquí cuentan las apuestas y los votos" si hay Carrera; solo "los votos" sin ella.
String _howItWorks(ConsequenceMode mode) {
  final bets = gamesFor(mode).any((g) => g.id == 'carrera');
  return 'Aquí cuentan ${bets ? 'las apuestas y los votos' : 'los votos'}. '
      'Manda quien acaba con más fichas.';
}

String _countingLine(ConsequenceMode mode) =>
    'Cuentan: ${joinNames(_countingTitles(mode))}';

const _removedPlayer = 'Jugador retirado';

/// Mensaje de chat corto con la Copa (solo texto, sin datos personales).
/// `finished`: la noche ha terminado, así que el primero es "Ganador" y no "Va en cabeza".
String cupShareText(
  Session session, {
  required String Function(String playerId) nameOf,
  bool finished = false,
}) {
  final b = StringBuffer(
    'Copa de la noche · $kAppName (${_date(session.startedAt)})\n',
  );
  final groups = groupStandings(session.standings);
  // Solo el podio (hasta 3 puestos), sin cifras: no salen saldos negativos ni la cola.
  for (final g in groups.where((g) => g.rank <= 3)) {
    final names = joinNames(g.playerIds.map(nameOf).toList());
    b.writeln('${ordinal(g.rank)} $names${g.isTie ? ' (empate)' : ''}');
  }
  if (groups.isNotEmpty) {
    if (_celebrates(groups.first)) {
      final leaders = joinNames(groups.first.playerIds.map(nameOf).toList());
      b.writeln('\n${finished ? 'Ganador' : 'Va en cabeza'}: $leaders');
    } else {
      b.writeln('\n${_noPositiveTitle(finished)}');
    }
  }
  if (kShareLink.isNotEmpty) b.writeln('\n$kShareLink');
  return b.toString().trimRight();
}

String _titleOf(String gameId) {
  for (final g in gameModules) {
    if (g.id == gameId) return g.title;
  }
  return gameId;
}

String Function(String) _nameResolver(List<Player> players) => (id) {
  for (final p in players) {
    if (p.id == id) return p.name;
  }
  return _removedPlayer;
};

Player _playerOf(List<Player> players, String id) => players.firstWhere(
  (p) => p.id == id,
  orElse: () => Player(id: id, name: _removedPlayer, colorIndex: 0),
);

Color _medalColor(int rank) => switch (rank) {
  1 => AppColors.medalGold,
  2 => AppColors.medalSilver,
  _ => AppColors.medalBronze,
};

class CupScreen extends ConsumerWidget {
  const CupScreen({super.key});

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    final players = ref.read(playersProvider);
    final finished = ref.read(sessionProvider.notifier).isStale;
    final text = cupShareText(
      session,
      nameOf: _nameResolver(players),
      finished: finished,
    );
    try {
      await ref.read(shareTextProvider)(text);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se ha podido abrir el menú de compartir.'),
        ),
      );
    }
  }

  Future<void> _newNight(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Empezar una noche nueva?'),
        content: const Text(
          'Se borran la clasificación y las estadísticas de esta noche. No hay vuelta atrás.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Nueva noche'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(sessionProvider.notifier).newNight();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final players = ref.watch(playersProvider);
    final mode = ref.watch(settingsProvider.select((s) => s.consequenceMode));
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle('Copa de la noche'),
        actions: [
          const HowToPlayButton('copa'),
          if (!session.isEmpty)
            IconButton(
              tooltip: 'Compartir la Copa',
              icon: AppIcon.shareNetwork.widget(size: 26),
              onPressed: () => _share(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: session.isEmpty
            ? _EmptyCup(mode: mode)
            : _CupBody(
                mode: mode,
                session: session,
                players: players,
                finished: ref.read(sessionProvider.notifier).isStale,
                onShare: () => _share(context, ref),
                onNewNight: () => _newNight(context, ref),
              ),
      ),
    );
  }
}

class _EmptyCup extends StatelessWidget {
  const _EmptyCup({required this.mode});

  final ConsequenceMode mode;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Jockey(size: 112),
          const SizedBox(height: 12),
          const Text(
            'Aún no hay rondas que cuenten',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 8),
          // Los juegos que suman salen del registro: nada fijo en el texto.
          Text(
            'Jugad a ${joinNames(_countingTitles(mode))} y aquí saldrá quién manda.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _CupBody extends StatefulWidget {
  const _CupBody({
    required this.mode,
    required this.session,
    required this.players,
    required this.finished,
    required this.onShare,
    required this.onNewNight,
  });

  final ConsequenceMode mode;
  final Session session;
  final List<Player> players;
  final bool finished;
  final VoidCallback onShare;
  final VoidCallback onNewNight;

  @override
  State<_CupBody> createState() => _CupBodyState();
}

class _CupBodyState extends State<_CupBody> {
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 600),
  );
  Timer? _clear;
  bool _confettiOn = true;

  /// Dispara el confeti y lo retira del árbol pasado un rato: el paquete solo
  /// deja de animar cuando las partículas salen de pantalla, y así el efecto
  /// acaba siempre (también en los tests, donde las partículas no avanzan).
  void _celebrate() {
    playSound(AppSound.podium);
    _confetti.play();
    _clear?.cancel();
    _clear = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _confettiOn = false);
    });
  }

  @override
  void dispose() {
    _clear?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final players = widget.players;
    final finished = widget.finished;
    final standings = session.standings;
    final groups = groupStandings(standings);
    final tiedRanks = {
      for (final g in groups)
        if (g.isTie) g.rank,
    };
    final nameOf = _nameResolver(players);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        const _SectionTitle('Podio'),
        _PodiumPanel(
          leaders: groups.first,
          nameOf: nameOf,
          finished: finished,
          // Los tres primeros puestos, con todos los que empatan en ellos: un empate
          // en el 3.º no deja a nadie fuera sin decirlo. La cola sigue sin salir.
          standings: standings.where((s) => s.rank <= 3).toList(),
          tiedRanks: tiedRanks,
          players: players,
          onWinnerLanded: _celebrate,
          confetti: _confetti,
          confettiOn: _confettiOn && !MediaQuery.disableAnimationsOf(context),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _howItWorks(widget.mode),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _countingLine(widget.mode),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Por juego'),
        Card(
          child: Column(
            children: [
              for (final g in session.statsByGame)
                ListTile(
                  title: Text(_titleOf(g.gameId)),
                  subtitle: Text(
                    '${g.rounds} ${g.rounds == 1 ? 'ronda' : 'rondas'} · '
                    '${_gameLeaderText(g, nameOf)}',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: widget.onShare,
          icon: AppIcon.shareNetwork.widget(
            size: 22,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          label: const Text('Compartir la Copa'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: widget.onNewNight,
          icon: AppIcon.restart.widget(),
          label: const Text('Nueva noche'),
        ),
      ],
    );
  }
}

/// "Líder: Ana" si quien manda en ese juego tiene fichas a favor; si no, no se corona a nadie.
String _gameLeaderText(GameStats g, String Function(String) nameOf) {
  final top = g.standings.where((s) => s.rank == 1).toList();
  if (top.isEmpty || top.first.total <= 0) return 'Nadie en positivo';
  return 'Líder: ${joinNames([for (final s in top) nameOf(s.playerId)])}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    ),
  );
}

/// Panel burdeos con el trofeo, el Jockey, el líder y el podio. El confeti
/// vive aquí dentro: recortado al panel y por detrás del texto.
class _PodiumPanel extends StatelessWidget {
  const _PodiumPanel({
    required this.leaders,
    required this.nameOf,
    required this.finished,
    required this.standings,
    required this.tiedRanks,
    required this.players,
    required this.onWinnerLanded,
    required this.confetti,
    required this.confettiOn,
  });

  final RankGroup leaders;
  final String Function(String) nameOf;
  final bool finished;
  final List<Standing> standings;
  final Set<int> tiedRanks;
  final List<Player> players;
  final VoidCallback onWinnerLanded;
  final ConfettiController confetti;
  final bool confettiOn;

  @override
  Widget build(BuildContext context) {
    final celebrate = _celebrates(leaders);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.burgundy,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.brass, width: 2),
        ),
        child: Stack(
          children: [
            if (confettiOn && celebrate)
              Positioned.fill(
                child: ExcludeSemantics(
                  child: IgnorePointer(
                    child: _PodiumConfetti(
                      controller: confetti,
                      particles: finished ? 14 : 6,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              child: Column(
                children: [
                  if (celebrate)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Jockey(pose: JockeyPose.celebra, size: 68),
                        SizedBox(width: 6),
                        TrophyIllustration(size: 112),
                      ],
                    )
                  else
                    const Jockey(size: 80),
                  const SizedBox(height: 8),
                  _LeaderBanner(
                    names: leaders.playerIds.map(nameOf).toList(),
                    total: leaders.total,
                    finished: finished,
                  ),
                  const SizedBox(height: 16),
                  _Podium(
                    standings: standings,
                    tiedRanks: tiedRanks,
                    players: players,
                    celebrate: celebrate,
                    onWinnerLanded: onWinnerLanded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dos cañones de confeti en las esquinas de arriba hacia el centro.
class _PodiumConfetti extends StatelessWidget {
  const _PodiumConfetti({required this.controller, required this.particles});

  final ConfettiController controller;
  final int particles;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      for (final left in [true, false])
        Align(
          alignment: left ? Alignment.topLeft : Alignment.topRight,
          child: ConfettiWidget(
            confettiController: controller,
            blastDirection: left ? math.pi / 3 : 2 * math.pi / 3,
            emissionFrequency: 0.05,
            numberOfParticles: particles,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
            colors: const [
              AppColors.gold,
              AppColors.medalSilver,
              AppColors.paper,
              AppColors.success,
            ],
          ),
        ),
    ],
  );
}

/// Quién manda. Con empate en positivo: "Empate a +3 fichas" y los nombres debajo.
/// Sin nadie en positivo no se celebra: "Nadie va en positivo" y quién ha perdido menos.
class _LeaderBanner extends StatelessWidget {
  const _LeaderBanner({
    required this.names,
    required this.total,
    required this.finished,
  });

  final List<String> names;
  final int total;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final tie = names.length > 1;
    final positive = total > 0;
    final title = !positive
        ? _noPositiveTitle(finished)
        : tie
        ? 'Empate a ${_chips(total)}'
        : '${finished ? 'Ganador' : 'Va en cabeza'}: ${names.first}';
    final detail = !positive
        ? (total == 0
              ? 'Sin perder nada: ${joinNames(names)}'
              : names.length == 1
              ? 'Quien menos ha perdido: ${names.first}'
              : 'Quienes menos han perdido: ${joinNames(names)}')
        : tie
        ? joinNames(names)
        : null;
    return Semantics(
      container: true,
      label: [title, ?detail].join('. '),
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontSize: 20,
                color: AppColors.gold,
                height: 1.2,
              ),
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  detail,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Podio con el orden clásico 2-1-3. Las barras crecen y las medallas caen
/// una a una (la última plaza primero) con rebote, con un toque háptico en
/// cada aterrizaje. Sin animaciones del sistema, aparece ya montado y sin
/// vibración ni confeti.
class _Podium extends StatefulWidget {
  const _Podium({
    required this.standings,
    required this.tiedRanks,
    required this.players,
    required this.celebrate,
    required this.onWinnerLanded,
  });

  final List<Standing> standings;
  final Set<int> tiedRanks;
  final List<Player> players;

  /// `false` si nadie tiene fichas a favor: sin medallas que caen, sin háptico ni sonido.
  final bool celebrate;
  final VoidCallback onWinnerLanded;

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  // Línea de tiempo (fracción de la duración total).
  static const _barsEnd = 0.35;
  static const _medalStart = 0.3;
  // Separación entre medallas: 0,2 con tres puestos; menos si hay empates y salen más.
  double get _medalGap => _n > 3 ? 0.4 / (_n - 1) : 0.2;
  static const _medalDur = 0.3;
  // La primera vez que toca el suelo una curva `bounceOut`.
  static const _impact = 0.364;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addListener(_tick);
  bool _started = false;
  bool _animated = false;
  int _landed = 0;

  int get _n => widget.standings.length;

  /// Orden de caída: la última plaza (índice mayor) cae primero.
  int _order(int index) => _n - 1 - index;

  double _localT(int order, double t) =>
      ((t - (_medalStart + order * _medalGap)) / _medalDur).clamp(0.0, 1.0);

  void _tick() {
    if (!_animated || !widget.celebrate) return;
    final t = _c.value;
    while (_landed < _n && _localT(_landed, t) >= _impact) {
      final isWinner = _landed == _n - 1;
      if (isWinner) {
        AppFeedback.heavy();
        widget.onWinnerLanded();
      } else {
        AppFeedback.light();
      }
      _landed++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      // El sonido no es una animación: sigue el ajuste de Sonido.
      if (_n > 0 && widget.celebrate) playSound(AppSound.podium);
    } else {
      _animated = true;
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final standings = widget.standings;
    // Orden visual: el 2.º a la izquierda, el 1.º en el centro, el 3.º a la derecha.
    // Con empates puede haber más de tres: entonces, en orden de puesto.
    final order = switch (standings.length) {
      1 => [0],
      2 => [1, 0],
      3 => [1, 0, 2],
      _ => [for (var i = 0; i < standings.length; i++) i],
    };
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final grow = Curves.easeOutBack.transform(
          (t / _barsEnd).clamp(0.0, 1.0),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final i in order)
              Expanded(
                child: _PodiumColumn(
                  standing: standings[i],
                  tied: widget.tiedRanks.contains(standings[i].rank),
                  players: widget.players,
                  grow: grow,
                  celebrate: widget.celebrate,
                  medalT: _localT(_order(i), t),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Un pedestal: avatar encima y, dentro del bloque, medalla, nombre, saldo y
/// (si hay empate) la etiqueta "Empate". La altura depende del puesto, así que
/// los empatados comparten altura.
class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.standing,
    required this.tied,
    required this.players,
    required this.grow,
    required this.celebrate,
    required this.medalT,
  });

  final Standing standing;
  final bool tied;
  final List<Player> players;
  final double grow;

  /// Con `false` no hay medalla: el puesto se dice con texto ("1.º").
  final bool celebrate;

  /// Progreso (0 a 1) de la caída de la medalla.
  final double medalT;

  static const _fall = 120.0;

  @override
  Widget build(BuildContext context) {
    final player = _playerOf(players, standing.playerId);
    final base = switch (standing.rank) {
      1 => 176.0,
      2 => 148.0,
      _ => 124.0,
    };
    // Con letra grande el contenido crece: la altura también, sin perder la
    // diferencia entre puestos.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final height = base * (1 + (scale - 1) * 0.6) * grow;
    final color = _medalColor(standing.rank);
    final drop = (1 - Curves.bounceOut.transform(medalT)) * _fall;
    final first = standing.rank == 1;
    return Semantics(
      container: true,
      label:
          'Puesto ${standing.rank}: ${player.name}, ${_chips(standing.total)}'
          '${tied ? ', empate' : ''}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: PlayerAvatar(player, size: first ? 52 : 42)),
              const SizedBox(height: 6),
              Container(
                key: ValueKey('podium-block-${standing.playerId}'),
                constraints: BoxConstraints(
                  minHeight: height.clamp(0.0, 600.0),
                ),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (celebrate)
                      Transform.translate(
                        offset: Offset(0, -drop),
                        child: Opacity(
                          opacity: (medalT * 8).clamp(0.0, 1.0),
                          child: MedalIcon(standing.rank, size: 34),
                        ),
                      )
                    else
                      SizedBox(
                        height: 34,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            ordinal(standing.rank),
                            style: TextStyle(
                              fontFamily: AppFonts.display,
                              fontSize: 22,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Opacity(
                      opacity: grow.clamp(0.0, 1.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              player.name,
                              maxLines: 1,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: first ? 16 : 14,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Fondo oscuro para que el rojo y el verde del saldo se lean.
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(
                                alpha: 0.7,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _chips(standing.total),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _balanceColor(standing.total),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (tied) ...[
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Empate',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
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
