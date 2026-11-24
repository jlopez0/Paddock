import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_icons.dart';
import '../../app/mascot.dart';
import '../../app/theme.dart';
import '../settings/app_feedback.dart';
import 'player.dart';
import 'player_widgets.dart';
import 'players_controller.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  Future<void> _rename(BuildContext context, WidgetRef ref, Player p) async {
    final controller = TextEditingController(text: p.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    final notifier = ref.read(playersProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    if (name.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Escribe un nombre')),
      );
    } else if (notifier.nameTaken(name, exceptId: p.id)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ese nombre ya está en la cuadra')),
      );
    } else {
      notifier.rename(p.id, name);
    }
  }

  void _remove(BuildContext context, WidgetRef ref, Player p) {
    final notifier = ref.read(playersProvider.notifier);
    final index = ref.read(playersProvider).indexWhere((x) => x.id == p.id);
    notifier.remove(p.id);
    AppFeedback.light();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${p.name} se retira'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () => notifier.restore(p, index),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'La cuadra',
          style: TextStyle(fontFamily: AppFonts.display, fontSize: 22),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const AddPlayerField(),
            const SizedBox(height: 16),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    Jockey(size: 104),
                    SizedBox(height: 16),
                    Text(
                      'Apunta a quien juega esta noche.\nLa cuadra se guarda para la próxima.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            for (final p in players)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: AppColors.brass.withValues(alpha: 0.6),
                    ),
                  ),
                  child: ListTile(
                    leading: PopIn(child: PlayerAvatar(p)),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => _rename(context, ref, p),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      icon: AppIcon.delete.widget(),
                      onPressed: () => _remove(context, ref, p),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
