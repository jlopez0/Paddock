import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/mascot.dart';
import '../../../app/theme.dart';
import '../../../core/audio/app_sound.dart';

/// Piezas comunes de los juegos de preguntas (Trivia y Geografía): escala de
/// resultado, tarjeta de resultado tipo boleto, opción de respuesta con
/// sacudida / destello, estado vacío y animaciones baratas.
///
/// Todas las animaciones se apagan con `MediaQuery.disableAnimations`.

/// Tinta de los boletos (texto sobre papel).
const Color quizInk = AppColors.background;

/// Texto con Alfa Slab One (cifras y títulos de ceremonia).
TextStyle quizDisplay(double size, {Color color = quizInk}) => TextStyle(
  fontFamily: AppFonts.display,
  fontWeight: FontWeight.w400,
  fontSize: size,
  height: 1.1,
  color: color,
);

// ---------------------------------------------------------------------------
// Pantalla de preparación (Trivia y Geografía)
// ---------------------------------------------------------------------------

/// Filete de latón de las tarjetas de la casa.
ShapeBorder quizBrassShape([double radius = 20]) => RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(radius),
  side: BorderSide(color: AppColors.brass.withValues(alpha: 0.75)),
);

/// Cabecera de la pantalla de preparación: medallón con el icono duotono del
/// juego (mismo lenguaje que el menú), el título (aquí y no en la barra, para
/// que con letra grande pueda ocupar las líneas que necesite) y una frase de
/// gancho.
class QuizSetupHeader extends StatelessWidget {
  const QuizSetupHeader({
    super.key,
    required this.gameId,
    required this.title,
    required this.hook,
    required this.color,
  });

  final String gameId;
  final String title;
  final String hook;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(
                color: AppColors.brass.withValues(alpha: 0.85),
                width: 1.5,
              ),
            ),
            child: ExcludeSemantics(child: GameIcon(gameId, size: 58)),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              textScaler: scaler,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w400,
                fontSize: 26,
                height: 1.2,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hook,
            textAlign: TextAlign.center,
            textScaler: scaler,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de la pantalla de preparación: tarjeta de fieltro con filete de
/// latón y su título en versalitas arriba.
class QuizSection extends StatelessWidget {
  const QuizSection({
    super.key,
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 14),
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: AppColors.surface,
        shape: quizBrassShape(),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
                  child: Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Escala de resultado
// ---------------------------------------------------------------------------

/// Pleno (todo) / Gran carrera (80 %) / Colocado (50 %) / Hoy no era tu carrera.
enum QuizTier {
  pleno('Pleno'),
  granCarrera('Gran carrera'),
  colocado('Colocado'),
  hoyNo('Hoy no era tu carrera');

  const QuizTier(this.label);

  final String label;

  static QuizTier of(int correct, int total) {
    if (total <= 0) return hoyNo;
    if (correct >= total) return pleno;
    final ratio = correct / total;
    if (ratio >= 0.8) return granCarrera;
    if (ratio >= 0.5) return colocado;
    return hoyNo;
  }
}

// ---------------------------------------------------------------------------
// Animaciones de un solo disparo
// ---------------------------------------------------------------------------

/// Reproduce una animación de [duration] cada vez que [active] pasa de false a
/// true. `builder` recibe `t` en 0..1; en reposo (0 o 1) debe pintar el estado
/// neutro. Con `disableAnimations` no hace nada.
class OneShot extends StatefulWidget {
  const OneShot({
    super.key,
    required this.active,
    required this.duration,
    required this.builder,
    this.child,
  });

  final bool active;
  final Duration duration;
  final Widget Function(BuildContext context, double t, Widget? child) builder;
  final Widget? child;

  @override
  State<OneShot> createState() => _OneShotState();
}

class _OneShotState extends State<OneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  bool _first = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si nace ya activo (p. ej. la tarjeta de "has fallado"), también suena.
    if (_first && widget.active && !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
    _first = false;
  }

  @override
  void didUpdateWidget(OneShot old) {
    super.didUpdateWidget(old);
    if (widget.active &&
        !old.active &&
        !MediaQuery.disableAnimationsOf(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (ctx, child) => widget.builder(ctx, _c.value, child),
  );
}

/// Sacudida horizontal al fallar.
class Shake extends StatelessWidget {
  const Shake({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => OneShot(
    active: active,
    duration: const Duration(milliseconds: 420),
    child: child,
    builder: (_, t, child) => Transform.translate(
      offset: Offset(math.sin(t * math.pi * 6) * 9 * (1 - t), 0),
      child: child,
    ),
  );
}

/// Pequeño latido al acertar.
class Pulse extends StatelessWidget {
  const Pulse({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => OneShot(
    active: active,
    duration: const Duration(milliseconds: 380),
    child: child,
    builder: (_, t, child) =>
        Transform.scale(scale: 1 + 0.04 * math.sin(t * math.pi), child: child),
  );
}

/// Aparece con un fundido y un pequeño zoom (solo al montarse).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      child: child,
      builder: (_, v, child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.92 + 0.08 * v, child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Opción de respuesta
// ---------------------------------------------------------------------------

enum QuizOptionState { idle, correct, wrong, dimmed }

/// Opción de respuesta con su letra (A-D). Mide lo mismo en todos los estados:
/// al responder no se desplaza nada. Acierto: destello verde y latido. Fallo:
/// sacudida.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.letter,
    required this.state,
    required this.onTap,
    this.minHeight = 56,
    this.maxLines,
  });

  final String label;
  final String letter;
  final QuizOptionState state;
  final VoidCallback? onTap;
  final double minHeight;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final fast = MediaQuery.disableAnimationsOf(context);
    final d = fast ? Duration.zero : const Duration(milliseconds: 250);
    final (Color border, Color fill, AppIcon? icon) = switch (state) {
      QuizOptionState.correct => (
        AppColors.success,
        AppColors.success.withValues(alpha: 0.2),
        AppIcon.checkCircle,
      ),
      QuizOptionState.wrong => (
        AppColors.danger,
        AppColors.danger.withValues(alpha: 0.2),
        AppIcon.cancel,
      ),
      _ => (AppColors.outline, AppColors.surface, null),
    };
    final badge = switch (state) {
      QuizOptionState.correct => AppColors.success,
      QuizOptionState.wrong => AppColors.danger,
      _ => AppColors.brass,
    };
    final suffix = switch (state) {
      QuizOptionState.correct => ', correcta',
      QuizOptionState.wrong => ', incorrecta',
      _ => '',
    };
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$letter. $label$suffix',
      onTap: onTap,
      excludeSemantics: true,
      child: Shake(
        active: state == QuizOptionState.wrong,
        child: Pulse(
          active: state == QuizOptionState.correct,
          child: AnimatedOpacity(
            opacity: state == QuizOptionState.dimmed ? 0.35 : 1,
            duration: d,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: d,
                  curve: Curves.easeOut,
                  constraints: BoxConstraints(minHeight: minHeight),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: border,
                      width: state == QuizOptionState.idle ? 1.5 : 2,
                    ),
                    boxShadow: [
                      if (state == QuizOptionState.correct)
                        BoxShadow(
                          color: AppColors.success.withValues(alpha: 0.45),
                          blurRadius: 16,
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: d,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background,
                          border: Border.all(color: badge, width: 2),
                        ),
                        child: Text(
                          letter,
                          textScaler: TextScaler.noScaling,
                          style: quizDisplay(
                            20,
                            color: state == QuizOptionState.idle
                                ? AppColors.gold
                                : badge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: maxLines,
                          overflow: maxLines == null
                              ? null
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 32,
                        height: 24,
                        child: AnimatedSwitcher(
                          duration: d,
                          transitionBuilder: (c, anim) =>
                              ScaleTransition(scale: anim, child: c),
                          child: icon == null
                              ? const SizedBox.shrink(key: ValueKey('none'))
                              : Align(
                                  key: ValueKey(icon),
                                  alignment: Alignment.centerRight,
                                  child: icon.widget(color: border),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Resultado
// ---------------------------------------------------------------------------

/// Boleto de resultado: medallón (trofeo, medalla o bandera de meta), escala
/// de la casa, puntuación en Alfa Slab One y una matriz [stub] (récord, fallos).
/// En un pleno, el Jockey celebra encima.
class QuizResultCard extends StatelessWidget {
  const QuizResultCard({
    super.key,
    required this.correct,
    required this.total,
    required this.stub,
  });

  final int correct;
  final int total;

  /// Contenido de la matriz del boleto.
  final Widget stub;

  @override
  Widget build(BuildContext context) {
    final tier = QuizTier.of(correct, total);
    final ratio = total == 0 ? 0.0 : correct / total;
    return _SoundOnce(
      sound: tier == QuizTier.pleno || tier == QuizTier.granCarrera
          ? AppSound.podium
          : null,
      child: PopIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tier == QuizTier.pleno) ...[
              const Jockey(pose: JockeyPose.celebra, size: 96),
              const SizedBox(height: 8),
            ],
            TicketCard(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              stub: Center(child: stub),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Medallion(tier),
                  const SizedBox(height: 14),
                  Text(
                    tier.label,
                    textAlign: TextAlign.center,
                    style: quizDisplay(26),
                  ),
                  const SizedBox(height: 16),
                  _ScoreRing(ratio: ratio, correct: correct, total: total),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reproduce [sound] una sola vez al aparecer (no hace nada si es null).
class _SoundOnce extends StatefulWidget {
  const _SoundOnce({required this.sound, required this.child});

  final AppSound? sound;
  final Widget child;

  @override
  State<_SoundOnce> createState() => _SoundOnceState();
}

class _SoundOnceState extends State<_SoundOnce> {
  @override
  void initState() {
    super.initState();
    final s = widget.sound;
    if (s != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => playSound(s));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Medallion extends StatelessWidget {
  const _Medallion(this.tier);

  final QuizTier tier;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (tier) {
      QuizTier.pleno => AppIcon.trophy.widget(size: 48),
      QuizTier.granCarrera => const MedalIcon(1, size: 48),
      QuizTier.colocado => const MedalIcon(2, size: 48),
      QuizTier.hoyNo => AppIcon.flagCheckered.widget(size: 48),
    };
    return ExcludeSemantics(
      child: Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(color: AppColors.brass, width: 3),
        ),
        child: icon,
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.ratio,
    required this.correct,
    required this.total,
  });

  final double ratio;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fast = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: '$correct de $total',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: fast ? ratio : 0, end: ratio),
        duration: fast ? Duration.zero : const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          width: 168,
          height: 168,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: v,
                  strokeWidth: 12,
                  strokeCap: StrokeCap.round,
                  color: AppColors.brass,
                  backgroundColor: AppColors.brass.withValues(alpha: 0.22),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(26),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$correct', style: quizDisplay(56)),
                      Text(
                        'de $total',
                        style: TextStyle(
                          color: quizInk.withValues(alpha: 0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

/// Matriz del boleto con un trofeo dorado sobre fondo oscuro (récord).
class QuizStubBadge extends StatelessWidget {
  const QuizStubBadge({super.key, required this.text, this.icon});

  final String text;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ExcludeSemantics(child: icon),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.gold,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Estados vacíos
// ---------------------------------------------------------------------------

/// Vacío con el Jockey neutral: sin partida, sin preguntas.
class QuizEmptyState extends StatelessWidget {
  const QuizEmptyState({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Jockey(size: 96),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: quizDisplay(22, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}
