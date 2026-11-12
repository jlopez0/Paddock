import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'player.dart';
import 'players_controller.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar(this.player, {super.key, this.size = 36});

  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: player.color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: player.color, width: 2),
      ),
      child: Text(
        player.initial,
        style: TextStyle(
          color: player.color,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.45,
        ),
      ),
    );
  }
}

/// Campo para dar de alta un jugador nuevo. Llama a [onAdded] con el jugador creado.
class AddPlayerField extends ConsumerStatefulWidget {
  const AddPlayerField({super.key, this.onAdded});

  final ValueChanged<Player>? onAdded;

  @override
  ConsumerState<AddPlayerField> createState() => _AddPlayerFieldState();
}

class _AddPlayerFieldState extends ConsumerState<AddPlayerField> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    final player = ref.read(playersProvider.notifier).add(name);
    _controller.clear();
    widget.onAdded?.call(player);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: 16,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Nombre del jugador',
        counterText: '',
        prefixIcon: const Icon(Icons.person_add_alt_1_rounded),
        suffixIcon: IconButton(
          tooltip: 'Añadir',
          icon: const Icon(Icons.add_circle_rounded),
          onPressed: _submit,
        ),
      ),
    );
  }
}
