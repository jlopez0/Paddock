import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/app_sound.dart';
import '../core/consequences/consequence_mode_selector.dart';
import '../core/players/player.dart';
import '../core/players/player_widgets.dart';
import '../core/players/players_controller.dart';
import '../core/settings/app_feedback.dart';
import '../core/settings/settings_controller.dart';
import '../games/game_module.dart';
import '../games/registry.dart';
import 'app_icons.dart';
import 'app_info.dart';
import 'mascot.dart';
import 'theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    // Con Retos la Carrera no se ofrece (D21): el resto conserva su orden.
    final games = gamesFor(
      ref.watch(settingsProvider.select((s) => s.consequenceMode)),
    );
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Jockey(size: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // La marca nunca desborda: se reduce con letra grande.
                          Semantics(
                            header: true,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                kAppName,
                                style: TextStyle(
                                  fontFamily: AppFonts.display,
                                  fontSize: 34,
                                  height: 1.1,
                                  color: AppColors.gold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            'Se abre la noche',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Entrada discreta a la Copa: sin insignias ni marcador en la home.
                    IconButton(
                      tooltip: 'Copa de la noche',
                      icon: AppIcon.trophy.widget(),
                      onPressed: () => context.push('/copa'),
                    ),
                    IconButton(
                      tooltip: 'Ajustes',
                      icon: AppIcon.settings.widget(),
                      onPressed: () => context.push('/settings'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              sliver: SliverToBoxAdapter(
                child: _Entrance(
                  index: 0,
                  child: _StableCard(players: players),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverToBoxAdapter(
                // Sorbos solo sale aquí si ya se confirmó la edad (+18).
                child: ConsequenceModeSelector(
                  alwaysOfferSorbos: false,
                  compact: true,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    for (var i = 0; i < games.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _Entrance(
                        index: i + 1,
                        child: _GameTile(games[i], number: i + 1),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrada escalonada: las tarjetas posteriores tardan un poco más en
/// asentarse. Sin animación si el sistema las desactiva.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + 70 * index.clamp(0, 8)),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Tarjeta de fieltro con filete de latón.
ShapeBorder _brassShape([double radius = 20]) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(radius),
  side: BorderSide(color: AppColors.brass.withValues(alpha: 0.75)),
);

/// Aire entre el texto de la cuadra y sus avatares.
const double _avatarGap = 8;

/// La cuadra: el grupo de jugadores guardado.
class _StableCard extends StatelessWidget {
  const _StableCard({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final empty = players.isEmpty;
    return Material(
      color: AppColors.surface,
      shape: _brassShape(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppFeedback.selection();
          context.push('/players');
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const labelStyle = TextStyle(fontWeight: FontWeight.w700);
                // Avatares solo los que caben sin apretar el texto: con letra grande o
                // pantalla estrecha salen menos (o ninguno) y el texto no se parte.
                var avatars = 0;
                if (!empty) {
                  final label = TextPainter(
                    text: TextSpan(
                      text: playersLabel(players.length),
                      style: DefaultTextStyle.of(
                        context,
                      ).style.merge(labelStyle),
                    ),
                    textDirection: TextDirection.ltr,
                    textScaler: MediaQuery.textScalerOf(context),
                  )..layout();
                  const fixed = 30 + 12 + 24 + _avatarGap; // icono, aire, flecha y aire
                  final free = constraints.maxWidth - fixed - label.width;
                  avatars = (free / (28 + 4)).floor().clamp(0, 5);
                  label.dispose();
                }
                return Row(
                  children: [
                    if (empty)
                      const Jockey(size: 40)
                    else
                      AppIcon.horse.widget(size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: empty
                          ? const Text(
                              'Forma la cuadra',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            )
                          : Text(
                              playersLabel(players.length),
                              style: labelStyle,
                            ),
                    ),
                    if (avatars > 0) const SizedBox(width: _avatarGap),
                    for (final p in players.take(avatars))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: PlayerAvatar(p, size: 28),
                      ),
                    AppIcon.chevronRight.widget(color: AppColors.textMuted),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Cartel de un juego: fieltro, filete de latón, franja y medallón con el
/// color del juego, y el número de carrera a la derecha.
class _GameTile extends StatelessWidget {
  const _GameTile(this.game, {required this.number});

  final GameModule game;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: _brassShape(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          AppFeedback.selection();
          playSound(AppSound.tap);
          context.push(game.path);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: game.color, width: 6)),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: game.color.withValues(alpha: 0.16),
                  border: Border.all(
                    color: AppColors.brass.withValues(alpha: 0.8),
                  ),
                ),
                child: ExcludeSemantics(child: game.icon(34)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 20,
                        height: 1.15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ExcludeSemantics(
                child: Text(
                  '$number',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: AppFonts.display,
                    fontSize: 24,
                    color: AppColors.brassText,
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
