import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../core/audio/app_sound.dart';
import '../core/players/player.dart';
import '../core/players/player_widgets.dart';
import '../core/players/players_controller.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_score.dart';
import '../core/settings/app_feedback.dart';
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

/// ÚNICO emoji permitido en `lib/`: va en el texto que SALE de la app hacia
/// WhatsApp y similares, donde no hay fuente ni iconos de Paddock. Nunca se
/// pinta dentro de la interfaz (allí se usa `AppIcon.trophy`).
const kShareTrophy = '🏆';

/// Saldo con signo: `+5`, `0`, `-2`.
String _signed(int n) => n > 0 ? '+$n' : '$n';

String _chips(int n) =>
    '${_signed(n)} ${n == 1 || n == -1 ? 'ficha' : 'fichas'}';

/// Rojo si es negativo, verde si es positivo, neutro si es cero.
Color _balanceColor(int n) => n < 0
    ? AppColors.danger
    : n > 0
    ? AppColors.success
    : AppColors.textMuted;

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

const _howItWorks =
    'Cada ronda suma las fichas ganadas y resta las perdidas. Manda quien más ha ganado o menos ha perdido.';

const _removedPlayer = 'Jugador retirado';

/// Mensaje de chat corto con la Copa (solo texto, sin datos personales).
/// `finished`: la noche ha terminado, así que el primero es "Ganador" y no "Va en cabeza".
String cupShareText(
  Session session, {
  required String Function(String playerId) nameOf,
  required String Function(String gameId) titleOf,
  bool finished = false,
}) {
  final b = StringBuffer(
    '$kShareTrophy Copa de la noche · $kAppName (${_date(session.startedAt)})\n',
  );
  final standings = session.standings;
  for (final s in standings) {
    b.writeln('${s.rank}. ${nameOf(s.playerId)}: ${_chips(s.total)}');
  }
  final leaders = standings
      .where((s) => s.rank == 1)
      .map((s) => nameOf(s.playerId))
      .join(', ');
  if (leaders.isNotEmpty) {
    b.writeln('\n${finished ? 'Ganador' : 'Va en cabeza'}: $leaders');
  }
  final losers = session.biggestLosers;
  if (losers.isNotEmpty) {
    b.writeln('El que más ha pagado: ${losers.map(nameOf).join(', ')}');
  }
  final games = session.statsByGame;
  if (games.isNotEmpty) {
    b.writeln('\nPor juego:');
    for (final g in games) {
      final lead = g.standings
          .where((s) => s.rank == 1)
          .map((s) => nameOf(s.playerId))
          .join(', ');
      b.writeln(
        '- ${titleOf(g.gameId)} (${g.rounds} ${g.rounds == 1 ? 'ronda' : 'rondas'}): $lead',
      );
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

/// Medalla para los tres primeros puestos y número en Alfa Slab para el resto.
class _Place extends StatelessWidget {
  const _Place(this.rank, {this.size = 28});

  final int rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) return MedalIcon(rank, size: size);
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          '$rank.',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: size * 0.55,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de la home con el top 3 y "Ver Copa". Se oculta si no hay puntuaciones.
class CupCard extends ConsumerWidget {
  const CupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.isEmpty) return const SizedBox.shrink();
    final players = ref.watch(playersProvider);
    final stale = ref.read(sessionProvider.notifier).isStale;
    final top = session.standings.take(3).toList();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/copa'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppIcon.trophy.widget(size: 26),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Copa de la noche',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/copa'),
                    child: const Text('Ver Copa'),
                  ),
                ],
              ),
              if (stale)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Lleva más de 12 horas abierta. Puedes empezar otra noche desde la Copa.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              for (final s in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 34, child: _Place(s.rank, size: 26)),
                      PlayerAvatar(_playerOf(players, s.playerId), size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _playerOf(players, s.playerId).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _chips(s.total),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _balanceColor(s.total),
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

class CupScreen extends ConsumerWidget {
  const CupScreen({super.key});

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    final session = ref.read(sessionProvider);
    final players = ref.read(playersProvider);
    final finished = ref.read(sessionProvider.notifier).isStale;
    final text = cupShareText(
      session,
      nameOf: _nameResolver(players),
      titleOf: _titleOf,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copa de la noche'),
        actions: [
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
            ? const _EmptyCup()
            : _CupBody(
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
  const _EmptyCup();

  @override
  Widget build(BuildContext context) => const Center(
    child: SingleChildScrollView(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Jockey(size: 112),
          SizedBox(height: 12),
          Text(
            'Aún no ha corrido nadie',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              color: AppColors.gold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Jugad unas rondas y aquí saldrá quién manda esta noche.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _CupBody extends StatefulWidget {
  const _CupBody({
    required this.session,
    required this.players,
    required this.finished,
    required this.onShare,
    required this.onNewNight,
  });

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
    duration: const Duration(milliseconds: 1200),
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
    _clear = Timer(const Duration(milliseconds: 2400), () {
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
    final nameOf = _nameResolver(players);
    final losers = session.biggestLosers;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _PodiumPanel(
              names: standings
                  .where((s) => s.rank == 1)
                  .map((s) => nameOf(s.playerId))
                  .toList(),
              finished: finished,
              standings: standings.take(3).toList(),
              players: players,
              onWinnerLanded: _celebrate,
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Clasificación'),
            const Padding(
              padding: EdgeInsets.only(left: 4, right: 4, bottom: 8),
              child: Text(
                _howItWorks,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final s in standings)
                    Semantics(
                      container: true,
                      label:
                          'Puesto ${s.rank}: ${nameOf(s.playerId)}, ${_chips(s.total)}'
                          '${s.rank == 1 ? ', ${finished ? 'ganador' : 'líder'}' : ''}',
                      child: ExcludeSemantics(
                        child: ListTile(
                          leading: SizedBox(
                            width: 68,
                            child: Row(
                              children: [
                                SizedBox(width: 34, child: _Place(s.rank)),
                                PlayerAvatar(
                                  _playerOf(players, s.playerId),
                                  size: 26,
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            nameOf(s.playerId),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: s.rank == 1
                              ? Text(
                                  finished ? 'Ganador' : 'Líder',
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                          trailing: Text(
                            _chips(s.total),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: _balanceColor(s.total),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (losers.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle('El que más ha pagado'),
              Card(
                child: ListTile(
                  leading: AppIcon.trendDown.widget(size: 28),
                  title: Text(losers.map(nameOf).join(', ')),
                ),
              ),
            ],
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
                        'Líder: ${g.standings.where((s) => s.rank == 1).map((s) => nameOf(s.playerId)).join(', ')}',
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
        ),
        // Confeti de dos esquinas hacia el centro; por encima de todo.
        if (_confettiOn && !MediaQuery.disableAnimationsOf(context))
          Positioned.fill(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    for (final left in [true, false])
                      Align(
                        alignment: left
                            ? Alignment.topLeft
                            : Alignment.topRight,
                        child: ConfettiWidget(
                          confettiController: _confetti,
                          blastDirection: left ? math.pi / 3 : 2 * math.pi / 3,
                          emissionFrequency: 0.06,
                          numberOfParticles: finished ? 18 : 8,
                          maxBlastForce: 22,
                          minBlastForce: 8,
                          gravity: 0.25,
                          colors: const [
                            AppColors.gold,
                            AppColors.medalSilver,
                            AppColors.burgundy,
                            AppColors.paper,
                            AppColors.success,
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
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

/// Panel burdeos con el trofeo, el Jockey, el líder y el podio.
class _PodiumPanel extends StatelessWidget {
  const _PodiumPanel({
    required this.names,
    required this.finished,
    required this.standings,
    required this.players,
    required this.onWinnerLanded,
  });

  final List<String> names;
  final bool finished;
  final List<Standing> standings;
  final List<Player> players;
  final VoidCallback onWinnerLanded;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.burgundy,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brass, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Jockey(pose: JockeyPose.celebra, size: 68),
                SizedBox(width: 6),
                TrophyIllustration(size: 112),
              ],
            ),
            const SizedBox(height: 8),
            _LeaderBanner(names: names, finished: finished),
            const SizedBox(height: 16),
            _Podium(
              standings: standings,
              players: players,
              onWinnerLanded: onWinnerLanded,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderBanner extends StatelessWidget {
  const _LeaderBanner({required this.names, required this.finished});

  final List<String> names;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    final text =
        '${finished ? 'Ganador' : 'Va en cabeza'}: ${names.join(', ')}';
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 20,
            color: AppColors.gold,
            height: 1.2,
          ),
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
    required this.players,
    required this.onWinnerLanded,
  });

  final List<Standing> standings;
  final List<Player> players;
  final VoidCallback onWinnerLanded;

  @override
  State<_Podium> createState() => _PodiumState();
}

class _PodiumState extends State<_Podium> with SingleTickerProviderStateMixin {
  // Línea de tiempo (fracción de la duración total).
  static const _barsEnd = 0.35;
  static const _medalStart = 0.3;
  static const _medalGap = 0.2;
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
    if (!_animated) return;
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
      if (_n > 0) playSound(AppSound.podium);
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
    final order = switch (standings.length) {
      1 => [0],
      2 => [1, 0],
      _ => [1, 0, 2],
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
                  players: widget.players,
                  grow: grow,
                  medalT: _localT(_order(i), t),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.standing,
    required this.players,
    required this.grow,
    required this.medalT,
  });

  final Standing standing;
  final List<Player> players;
  final double grow;

  /// Progreso (0 a 1) de la caída de la medalla.
  final double medalT;

  static const _fall = 120.0;

  @override
  Widget build(BuildContext context) {
    final player = _playerOf(players, standing.playerId);
    final base = switch (standing.rank) {
      1 => 110.0,
      2 => 80.0,
      _ => 56.0,
    };
    final color = _medalColor(standing.rank);
    final drop = (1 - Curves.bounceOut.transform(medalT)) * _fall;
    return Semantics(
      container: true,
      label:
          'Puesto ${standing.rank}: ${player.name}, ${_chips(standing.total)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(player, size: standing.rank == 1 ? 52 : 42),
              const SizedBox(height: 6),
              Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 2),
              // Fondo oscuro para que el rojo y el verde del saldo se lean sobre el burdeos.
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
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
              const SizedBox(height: 6),
              Container(
                height: (base * grow).clamp(0.0, 200.0),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Transform.translate(
                  offset: Offset(0, -drop),
                  child: Opacity(
                    opacity: (medalT * 8).clamp(0.0, 1.0),
                    child: MedalIcon(standing.rank, size: 34),
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
