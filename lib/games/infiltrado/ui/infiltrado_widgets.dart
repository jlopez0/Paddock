import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';

const infiltradoColor = Color(0xFF8E6BE0);

/// Pregunta antes de abandonar una partida en curso. Devuelve `true` si se sale.
Future<bool> confirmLeaveInfiltrado(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Salir de la partida?'),
      content: const Text('Se perderá la ronda en curso.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Seguir')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
      ],
    ),
  );
  return leave == true;
}

/// Envuelve una pantalla de partida: atrás (también el predictivo) pide
/// confirmación y, si se acepta, vuelve a la pantalla anterior.
class InfiltradoLeaveGuard extends StatelessWidget {
  const InfiltradoLeaveGuard({super.key, required this.child});

  final Widget child;

  Future<void> _exit(BuildContext context) async {
    if (await confirmLeaveInfiltrado(context) && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit(context);
    },
    child: child,
  );
}

/// Barra superior de las pantallas de partida, con el botón de salir.
class InfiltradoTopBar extends StatelessWidget {
  const InfiltradoTopBar({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: 'Salir de la partida',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      SizedBox(
        width: 48,
        child: trailing == null
            ? null
            : Text(
                trailing!,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
      ),
    ],
  );
}

/// Cuerpo desplazable y centrado que respeta escalas de texto grandes.
class InfiltradoBody extends StatelessWidget {
  const InfiltradoBody({super.key, required this.children, this.footer});

  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
      if (footer != null) ...[const SizedBox(height: 12), footer!],
    ],
  );
}

/// Pantalla "pasa el móvil a X": no enseña nada secreto.
class PassPhoneCover extends StatelessWidget {
  const PassPhoneCover({
    super.key,
    required this.player,
    required this.heading,
    required this.buttonLabel,
    required this.onContinue,
    this.progress,
  });

  final Player player;
  final String heading;
  final String buttonLabel;
  final VoidCallback onContinue;
  final String? progress;

  @override
  Widget build(BuildContext context) => InfiltradoBody(
    footer: FilledButton(onPressed: onContinue, child: Text(buttonLabel, textAlign: TextAlign.center)),
    children: [
      Semantics(
        label: 'Pasa el móvil',
        excludeSemantics: true,
        child: const Text('📱', textAlign: TextAlign.center, style: TextStyle(fontSize: 64)),
      ),
      const SizedBox(height: 16),
      Text(
        heading,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
      ),
      const SizedBox(height: 16),
      Center(child: PlayerAvatar(player, size: 72)),
      const SizedBox(height: 12),
      Text(
        player.name,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: player.color),
      ),
      if (progress != null) ...[
        const SizedBox(height: 8),
        Text(
          progress!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ],
    ],
  );
}

/// Estado vacío cuando no hay partida (p. ej. tras reabrir la app).
class InfiltradoNoGame extends StatelessWidget {
  const InfiltradoNoGame({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('El Infiltrado')),
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🕵️', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'No hay ninguna partida en curso.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/game/infiltrado'),
                child: const Text('Preparar una partida'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
