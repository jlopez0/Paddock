import '../../../core/help/how_to_play.dart';
import 'package:material_ui/material_ui.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';
import '../../../core/players/players_controller.dart';
import '../domain/bets.dart';
import '../domain/cards.dart';
import '../race_store.dart';
import 'race_widgets.dart';

class _Draft {
  _Draft({this.suit, this.chips = 2, this.allIn = false});
  Suit? suit;
  int chips;
  bool allIn;

  int get betChips => allIn ? Bet.allIn : chips;
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
      if (ids.contains(b.playerId)) {
        _drafts[b.playerId] = _Draft(
          suit: b.suit,
          chips: b.isAllIn ? 2 : b.chips,
          allIn: b.isAllIn,
        );
      }
    }
  }

  void _toggle(Player p) {
    AppFeedback.selection();
    setState(() {
      if (_drafts.remove(p.id) == null) _drafts[p.id] = _Draft();
    });
  }

  List<Bet>? get _validBets {
    if (_drafts.isEmpty || _drafts.values.any((d) => d.suit == null)) {
      return null;
    }
    return [
      for (final e in _drafts.entries)
        Bet(playerId: e.key, suit: e.value.suit!, chips: e.value.betChips),
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
    final missingSuit = _drafts.entries
        .where((e) => e.value.suit == null)
        .map((e) => byId[e.key]!.name);

    return Scaffold(
      appBar: AppBar(
        title: const AppTitle('Carrera de caballos'),
        actions: [
          const HowToPlayButton('carrera'),
          IconButton(
            tooltip: 'Estadísticas',
            icon: AppIcon.trophy.widget(size: 24),
            onPressed: () => context.push('/game/carrera/stats'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          const _SectionTitle('¿Quién apuesta?'),
          if (players.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sin jugadores no hay apuestas.\nEscribe un nombre abajo y toca «Añadir».',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
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
          AddPlayerField(
            onAdded: (p) =>
                setState(() => _drafts.putIfAbsent(p.id, _Draft.new)),
          ),
          if (_drafts.isNotEmpty) ...[
            const _SectionTitle('Boletos'),
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
                  title: Text('Casillas hasta la meta: ${settings.length}'),
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
                ),
                SwitchListTile(
                  title: const Text('Cartas obstáculo'),
                  subtitle: const Text('Al descubrirse, ese caballo retrocede'),
                  value: settings.obstacles,
                  onChanged: (v) => ref
                      .read(raceSetupProvider.notifier)
                      .setSettings(settings.copyWith(obstacles: v)),
                ),
                SwitchListTile(
                  title: const Text('Acertar gana el doble'),
                  value: settings.doubleForWinners,
                  onChanged: (v) => ref
                      .read(raceSetupProvider.notifier)
                      .setSettings(settings.copyWith(doubleForWinners: v)),
                ),
                SwitchListTile(
                  title: const Text('Música de carrera'),
                  subtitle: const Text('Obertura de Guillermo Tell al empezar'),
                  value: settings.music,
                  onChanged: (v) => ref
                      .read(raceSetupProvider.notifier)
                      .setSettings(settings.copyWith(music: v)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Gira el móvil: la carrera se juega en horizontal.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _validBets == null ? null : _start,
                icon: AppIcon.flagCheckered.widget(size: 24, color: raceInk),
                label: Text(
                  players.isEmpty
                      ? 'Añade jugadores para apostar'
                      : _drafts.isEmpty
                      ? 'Haced vuestras apuestas'
                      : missingSuit.isNotEmpty
                      ? 'Falta el palo de ${missingSuit.first}'
                      : '¡A correr!',
                ),
              ),
            ),
          ],
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

class _BetCard extends StatelessWidget {
  const _BetCard({
    required this.player,
    required this.draft,
    required this.onChanged,
  });

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
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Stepper(
                  value: draft.chips,
                  enabled: !draft.allIn,
                  allIn: draft.allIn,
                  onChanged: (v) {
                    AppFeedback.selection();
                    playSound(AppSound.chip);
                    draft.chips = v;
                    onChanged();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AllInButton(
              selected: draft.allIn,
              onTap: () {
                AppFeedback.selection();
                if (!draft.allIn) playSound(AppSound.chip);
                draft.allIn = !draft.allIn;
                onChanged();
              },
            ),
            const SizedBox(height: 10),
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
                          AppFeedback.selection();
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
  const _SuitButton({
    required this.suit,
    required this.selected,
    required this.onTap,
  });

  final Suit suit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dur = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: 'Palo ${suit.label}',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: dur,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? suit.color.withValues(alpha: 0.25)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? suit.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 0.92,
                duration: dur,
                child: Image.asset(PlayingCard.horseAsset(suit), height: 54),
              ),
              const SizedBox(height: 4),
              Text(
                suit.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? suit.color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.allIn = false,
  });

  final int value;
  final bool enabled;
  final bool allIn;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = allIn
        ? 'All-in, $kAllInChips fichas'
        : (value == 1 ? '1 ficha' : '$value fichas');
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Una ficha menos',
            onPressed: enabled && value > Bet.minChips
                ? () => onChanged(value - 1)
                : null,
            icon: AppIcon.remove.widget(),
          ),
          SizedBox(
            width: 56,
            child: Semantics(
              label: label,
              excludeSemantics: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChipDrop(value: value, allIn: allIn, size: 40),
                  const SizedBox(height: 2),
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'fichas',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Una ficha más',
            onPressed: enabled && value < Bet.maxChips
                ? () => onChanged(value + 1)
                : null,
            icon: AppIcon.add.widget(),
          ),
        ],
      ),
    );
  }
}

class _AllInButton extends StatelessWidget {
  const _AllInButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      excludeSemantics: true,
      label: 'All-in, $kAllInChips fichas',
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.18)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.gold : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RaceChip(0, allIn: true, size: 34),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'All-in  ·  $kAllInChips fichas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? AppColors.gold : AppColors.textMuted,
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
