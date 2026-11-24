import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../core/players/player.dart';
import '../core/players/player_widgets.dart';
import '../core/players/players_controller.dart';
import '../core/session/session_controller.dart';
import '../core/session/session_score.dart';
import '../core/widgets/effects.dart';
import '../games/registry.dart';
import 'app_info.dart';
import 'theme.dart';

/// Comparte un texto con la hoja del sistema. Los tests lo sustituyen.
final shareTextProvider = Provider<Future<void> Function(String text)>(
  (ref) => (text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  },
);

String _chips(int n) => n == 1 ? '1 ficha' : '$n fichas';

String _medal(int rank) => switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '$rank.',
    };

/// Texto plano de la Copa para compartir (solo texto, sin datos personales).
String cupShareText(
  Session session, {
  required String Function(String playerId) nameOf,
  required String Function(String gameId) titleOf,
}) {
  final b = StringBuffer('🏆 Copa de la noche · $kAppName\n');
  for (final s in session.standings) {
    b.writeln('${_medal(s.rank)} ${nameOf(s.playerId)}: ${_chips(s.total)}');
  }
  final losers = session.biggestLosers;
  if (losers.isNotEmpty) {
    b.writeln('\nEl que más ha perdido: ${losers.map(nameOf).join(', ')}');
  }
  final games = session.statsByGame;
  if (games.isNotEmpty) {
    b.writeln('\nPor juego:');
    for (final g in games) {
      final leaders = g.standings.where((s) => s.rank == 1).map((s) => nameOf(s.playerId)).join(', ');
      b.writeln('- ${titleOf(g.gameId)} (${g.rounds} ${g.rounds == 1 ? 'ronda' : 'rondas'}): $leaders');
    }
  }
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
      return 'Jugador eliminado';
    };

Player _playerOf(List<Player> players, String id) => players.firstWhere(
      (p) => p.id == id,
      orElse: () => Player(id: id, name: 'Jugador eliminado', colorIndex: 0),
    );

const _gold = AppColors.gold;
const _silver = Color(0xFFC0C8D0);
const _bronze = Color(0xFFCD8A55);

Color _medalColor(int rank) => switch (rank) { 1 => _gold, 2 => _silver, _ => _bronze };

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
                  const Text('🏆', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Copa de la noche',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    'Es de hace más de 12 horas. Puedes empezar una noche nueva desde la Copa.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              for (final s in top)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(width: 32, child: Text(_medal(s.rank), style: const TextStyle(fontSize: 18))),
                      PlayerAvatar(_playerOf(players, s.playerId), size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _playerOf(players, s.playerId).name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(_chips(s.total), style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final text = cupShareText(session, nameOf: _nameResolver(players), titleOf: _titleOf);
    try {
      await ref.read(shareTextProvider)(text);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido abrir el menú de compartir.')),
      );
    }
  }

  Future<void> _newNight(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Empezar una noche nueva?'),
        content: const Text('Se borrará la clasificación y las estadísticas de esta noche. No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Nueva noche')),
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
              tooltip: 'Compartir resultado',
              icon: const Icon(Icons.ios_share_rounded),
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
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 56)),
              SizedBox(height: 12),
              Text('Todavía no hay puntuaciones',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Juega unas rondas y aquí aparecerá la clasificación de la noche.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
}

class _CupBody extends StatelessWidget {
  const _CupBody({
    required this.session,
    required this.players,
    required this.onShare,
    required this.onNewNight,
  });

  final Session session;
  final List<Player> players;
  final VoidCallback onShare;
  final VoidCallback onNewNight;

  @override
  Widget build(BuildContext context) {
    final standings = session.standings;
    final nameOf = _nameResolver(players);
    final losers = session.biggestLosers;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Podium(standings: standings.take(3).toList(), players: players),
            const SizedBox(height: 20),
            const _SectionTitle('Clasificación'),
            Card(
              child: Column(
                children: [
                  for (final s in standings)
                    Semantics(
                      container: true,
                      label: 'Puesto ${s.rank}: ${nameOf(s.playerId)}, ${_chips(s.total)}',
                      child: ExcludeSemantics(
                        child: ListTile(
                          leading: SizedBox(
                            width: 56,
                            child: Row(
                              children: [
                                SizedBox(width: 28, child: Text(_medal(s.rank))),
                                PlayerAvatar(_playerOf(players, s.playerId), size: 26),
                              ],
                            ),
                          ),
                          title: Text(nameOf(s.playerId), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(_chips(s.total),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (losers.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle('El que más ha perdido'),
              Card(
                child: ListTile(
                  leading: const Text('📉', style: TextStyle(fontSize: 24)),
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
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Compartir resultado'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onNewNight,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Nueva noche'),
            ),
          ],
        ),
        if (!MediaQuery.disableAnimationsOf(context)) const Positioned.fill(child: Confetti()),
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
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
      );
}

/// Podio con el orden clásico 2-1-3. Las barras crecen al entrar.
class _Podium extends StatelessWidget {
  const _Podium({required this.standings, required this.players});

  final List<Standing> standings;
  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    // Orden visual: el 2.º a la izquierda, el 1.º en el centro, el 3.º a la derecha.
    final order = switch (standings.length) {
      1 => [0],
      2 => [1, 0],
      _ => [1, 0, 2],
    };
    final instant = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: instant ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, t, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final i in order)
            Expanded(child: _PodiumColumn(standing: standings[i], players: players, grow: t)),
        ],
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({required this.standing, required this.players, required this.grow});

  final Standing standing;
  final List<Player> players;
  final double grow;

  @override
  Widget build(BuildContext context) {
    final player = _playerOf(players, standing.playerId);
    final base = switch (standing.rank) { 1 => 110.0, 2 => 80.0, _ => 56.0 };
    final color = _medalColor(standing.rank);
    return Semantics(
      container: true,
      label: 'Puesto ${standing.rank}: ${player.name}, ${_chips(standing.total)}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerAvatar(player, size: standing.rank == 1 ? 52 : 42),
              const SizedBox(height: 6),
              Text(player.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(_chips(standing.total), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                height: (base * grow).clamp(0.0, 200.0),
                alignment: Alignment.topCenter,
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: grow > 0.5
                    ? Text(_medal(standing.rank), style: const TextStyle(fontSize: 24))
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
