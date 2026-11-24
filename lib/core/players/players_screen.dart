import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
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
      messenger.showSnackBar(const SnackBar(content: Text('El nombre no puede estar vacío')));
    } else if (notifier.nameTaken(name, exceptId: p.id)) {
      messenger.showSnackBar(const SnackBar(content: Text('Ya hay un jugador con ese nombre')));
    } else {
      notifier.rename(p.id, name);
    }
  }

  void _remove(BuildContext context, WidgetRef ref, Player p) {
    final notifier = ref.read(playersProvider.notifier);
    final index = ref.read(playersProvider).indexWhere((x) => x.id == p.id);
    notifier.remove(p.id);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text('${p.name} eliminado'),
        action: SnackBarAction(label: 'Deshacer', onPressed: () => notifier.restore(p, index)),
      ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(playersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Jugadores')),
      body: SafeArea(top: false, child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const AddPlayerField(),
          const SizedBox(height: 16),
          if (players.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Text(
                'Añade a la gente con la que juegas.\nSe guardan para las próximas partidas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          for (final p in players)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  leading: PlayerAvatar(p),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => _rename(context, ref, p),
                  trailing: IconButton(
                    tooltip: 'Eliminar',
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _remove(context, ref, p),
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}
