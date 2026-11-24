import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../../../core/audio/app_sound.dart';
import '../../../core/settings/app_feedback.dart';
import '../../prompt_deck/game_colors.dart';
import '../../../core/players/player.dart';
import '../../../core/players/player_widgets.dart';

const infiltradoColor = Color(0xFF8E6BE0);

/// Tinta sobre papel (boletos, papeletas): contraste >= 6:1 sobre `AppColors.paper`.
const infiltradoInk = Color(0xFF1B2A21);
const infiltradoInkMuted = Color(0xFF4A5B50);

/// `true` si el usuario pide menos animaciones.
bool infiltradoReduceMotion(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// Texto de cartelería (Alfa Slab One). El factor de escala del sistema se
/// limita a 1,3 para que el titular no rompa palabras; con [fit] se reduce
/// hasta caber en una línea.
class SlabText extends StatelessWidget {
  const SlabText(
    this.text, {
    super.key,
    required this.size,
    this.color,
    this.fit = false,
    this.letterSpacing,
  });

  final String text;
  final double size;
  final Color? color;
  final bool fit;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      text,
      textAlign: TextAlign.center,
      textScaler: MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3),
      style: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w400,
        fontSize: size,
        height: 1.15,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
    return fit ? FittedBox(fit: BoxFit.scaleDown, child: t) : t;
  }
}

/// Sello burdeos de la ronda ("INFILTRADO" / "SALVADOS"): entra con un golpe
/// (escala y fundido) y vibra una vez. Con animaciones desactivadas aparece ya
/// puesto.
class InfiltradoStamp extends StatefulWidget {
  const InfiltradoStamp(this.text, {super.key});

  final String text;

  @override
  State<InfiltradoStamp> createState() => _InfiltradoStampState();
}

class _InfiltradoStampState extends State<InfiltradoStamp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppFeedback.heavy();
      playSound(AppSound.podium);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = infiltradoReduceMotion(context);
    return Semantics(
      label: 'Sello: ${widget.text}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: (v * 2.5).clamp(0.0, 1.0),
          child: Transform.scale(scale: 1 + (1 - v) * 1.2, child: child),
        ),
        child: Center(
          child: Transform.rotate(
            angle: -0.1,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.burgundy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.paper, width: 3),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.paper.withValues(alpha: 0.7),
                    width: 1.5,
                  ),
                ),
                child: SlabText(
                  widget.text,
                  size: 26,
                  color: AppColors.paper,
                  letterSpacing: 2,
                  fit: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pregunta antes de abandonar una partida en curso. Devuelve `true` si se sale.
Future<bool> confirmLeaveInfiltrado(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Salir de la partida?'),
      content: const Text('Se perderá la ronda en curso.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Seguir'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Salir'),
        ),
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
        icon: AppIcon.close.widget(),
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
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            padding: EdgeInsets.zero,
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
    footer: FilledButton(
      onPressed: onContinue,
      child: Text(buttonLabel, textAlign: TextAlign.center),
    ),
    children: [
      _SlidingPhone(key: ValueKey('phone-${player.id}')),
      const SizedBox(height: 16),
      Text(
        heading,
        textAlign: TextAlign.center,
        style: const TextStyle(color: GameColors.mutedText, fontSize: 16),
      ),
      const SizedBox(height: 16),
      Center(child: PlayerAvatar(player, size: 72)),
      const SizedBox(height: 12),
      SlabText(player.name, size: 34, color: player.color, fit: true),
      if (progress != null) ...[
        const SizedBox(height: 8),
        Text(
          progress!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: GameColors.mutedText),
        ),
      ],
    ],
  );
}

/// Móvil que entra deslizándose desde un lado: "pasa el móvil".
class _SlidingPhone extends StatelessWidget {
  const _SlidingPhone({super.key});

  @override
  Widget build(BuildContext context) {
    final reduce = infiltradoReduceMotion(context);
    return Semantics(
      label: 'Pasa el móvil',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 550),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset((1 - v) * 90, 0),
            child: Transform.rotate(angle: (1 - v) * 0.45, child: child),
          ),
        ),
        child: Center(child: AppIcon.deviceMobile.widget(size: 64)),
      ),
    );
  }
}

/// Estado vacío cuando no hay partida (p. ej. tras reabrir la app).
class InfiltradoNoGame extends StatelessWidget {
  const InfiltradoNoGame({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('El Infiltrado')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.detective.widget(size: 56, semanticLabel: 'Infiltrado'),
              const SizedBox(height: 12),
              const Text(
                'Nadie está disimulando ahora mismo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => context.go('/game/infiltrado'),
                child: const Text('Preparar partida'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
