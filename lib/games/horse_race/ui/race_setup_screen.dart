import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../race_store.dart';

class _Draft {
  _Draft({this.suit, this.sips = 2});
  Suit? suit;
  int sips;
}

class RaceSetupScreen extends ConsumerStatefulWidget {
  const RaceSetupScreen({super.key});

  @override
  ConsumerState<RaceSetupScreen> createState() => _RaceSetupScreenState();
}

class _RaceSetupScreenState extends ConsumerState<RaceSetupScreen> {
  /// Jugadores seleccionados → su apuesta en edición (orden de inserción).
  final Map<String, _Draft> _drafts = {};

  @override
  void initState() {
    super.initState();
    final players = ref.read(playersProvider);
    final ids = players.map((p) => p.id).toSet();
    for (final b in ref.read(raceSetupProvider).bets) {
      if (ids.contains(b.playerId)) _drafts[b.playerId] = _Draft(suit: b.suit, sips: b.sips);
    }
  }

  void _toggle(Player p) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_drafts.remove(p.id) == null) _drafts[p.id] = _Draft();
    });
  }

  List<Bet>? get _validBets {
    if (_drafts.isEmpty || _drafts.values.any((d) => d.suit == null)) return null;
    return [
      for (final e in _drafts.entries) Bet(playerId: e.key, suit: e.value.suit!, sips: e.value.sips),
    ];
  }

  void _start() {
    final bets = _validBets;
    if (bets == null) return;
    ref.read(raceSetupProvider.notifier).setBets(bets);
    context.push('/game/carrera/race');
  }

  @override
  Widget build(BuildContext context) {
    final players = ref.watch(playersProvider);
    final settings = ref.watch(raceSetupProvider).settings;
    final byId = {for (final p in players) p.id: p};
    _drafts.removeWhere((id, _) => !byId.containsKey(id));
    final missingSuit = _drafts.entries.where((e) => e.value.suit == null).map((e) => byId[e.key]!.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Apuestas'),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.leaderboard_rounded),
            onPressed: () => context.push('/game/carrera/stats'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          const _SectionTitle('¿Quién apuesta?'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in players)
                FilterChip(
                  avatar: PlayerAvatar(p, size: 24),
                  label: Text(p.name),
                  selected: _drafts.containsKey(p.id),
                  showCheckmark: false,
                  onSelected: (_) => _toggle(p),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AddPlayerField(onAdded: (p) => setState(() => _drafts.putIfAbsent(p.id, _Draft.new))),
          if (_drafts.isNotEmpty) ...[
            const _SectionTitle('Palo y tragos'),
            for (final e in _drafts.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BetCard(
                  player: byId[e.key]!,
                  draft: e.value,
                  onChanged: () => setState(() {}),
                ),
              ),
          ],
          const _SectionTitle('Reglas'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Casillas hasta la meta'),
                  subtitle: Slider(
                    value: settings.length.toDouble(),
                    min: 4,
                    max: 9,
                    divisions: 5,
                    label: '${settings.length}',
                    onChanged: (v) => ref
                        .read(raceSetupProvider.notifier)
                        .setSettings(settings.copyWith(length: v.round())),
                  ),
                  trailing: Text('${settings.length}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ),
                SwitchListTile(
                  title: const Text('Cartas obstáculo'),
                  subtitle: const Text('Al descubrirse, ese caballo retrocede'),
                  value: settings.obstacles,
                  onChanged: (v) =>
                      ref.read(raceSetupProvider.notifier).setSettings(settings.copyWith(obstacles: v)),
                ),
                SwitchListTile(
                  title: const Text('Acertar reparte el doble'),
                  value: settings.doubleForWinners,
                  onChanged: (v) => ref
                      .read(raceSetupProvider.notifier)
                      .setSettings(settings.copyWith(doubleForWinners: v)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: FilledButton.icon(
          onPressed: _validBets == null ? null : _start,
          icon: const Text('🏁', style: TextStyle(fontSize: 20)),
          label: Text(
            _drafts.isEmpty
                ? 'Elige quién apuesta'
                : missingSuit.isNotEmpty
                    ? 'Falta el palo de ${missingSuit.first}'
                    : '¡A correr!',
          ),
        ),
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
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 1.2, fontSize: 12)),
      );
}

class _BetCard extends StatelessWidget {
  const _BetCard({required this.player, required this.draft, required this.onChanged});

  final Player player;
  final _Draft draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                PlayerAvatar(player, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(player.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                _Stepper(
                  value: draft.sips,
                  onChanged: (v) {
                    draft.sips = v;
                    onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final s in Suit.values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _SuitButton(
                        suit: s,
                        selected: draft.suit == s,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          draft.suit = s;
                          onChanged();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuitButton extends StatelessWidget {
  const _SuitButton({required this.suit, required this.selected, required this.onTap});

  final Suit suit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? suit.color.withValues(alpha: 0.25) : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? suit.color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 0.92,
              duration: const Duration(milliseconds: 180),
              child: Image.asset(PlayingCard.horseAsset(suit), height: 54),
            ),
            const SizedBox(height: 4),
            Text(suit.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? suit.color : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
          ),
          SizedBox(
            width: 44,
            child: Text('$value 🍺',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 10 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
