import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_icons.dart';
import '../audio/app_sound.dart';
import '../settings/app_feedback.dart';
import 'player.dart';
import 'players_controller.dart';

/// Ficha que rebota al aparecer (alta de un jugador). Sin animación si el
/// sistema las desactiva.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      child: child,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
    );
  }
}

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
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Muestra el error y deja el texto seleccionado: lo siguiente que se
  /// escriba lo reemplaza en vez de pegarse al nombre rechazado.
  void _fail(String message) {
    setState(() => _error = message);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
    _focus.requestFocus();
  }

  void _submit() {
    final name = _controller.text.trim();
    final notifier = ref.read(playersProvider.notifier);
    if (name.isEmpty) {
      _fail('Escribe un nombre');
      return;
    }
    if (notifier.nameTaken(name)) {
      _fail('Ese nombre ya está en la cuadra');
      return;
    }
    final player = notifier.add(name);
    AppFeedback.light();
    playSound(AppSound.chipSoft);
    setState(() => _error = null);
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
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Nombre del jugador',
        errorText: _error,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: AppIcon.horse.widget(size: 24),
        ),
        suffixIcon: IconButton(
          tooltip: 'Añadir',
          icon: AppIcon.add.widget(),
          onPressed: _submit,
        ),
      ),
    );
  }
}
