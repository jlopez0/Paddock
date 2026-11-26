import 'package:material_ui/material_ui.dart';

import '../../../app/app_icons.dart';
import '../../../app/theme.dart';
import '../domain/bets.dart';

/// Tinta oscura para texto sobre boleto (papel claro).
const Color raceInk = Color(0xFF241A00);

/// Verde de las fichas normales; el All-in es burdeos con halo dorado.
const Color raceChipGreen = Color(0xFF2F6B4A);

const Color _stampGreen = Color(0xFF1F6B3C);

/// Ficha de apuesta: verde para fichas normales; el All-in es una ficha
/// especial de [kAllInChips] en burdeos con halo dorado.
class RaceChip extends StatelessWidget {
  const RaceChip(this.value, {super.key, this.allIn = false, this.size = 44});

  /// Fichas de la ficha dibujada (ignorado si [allIn]: vale [kAllInChips]).
  final int value;
  final bool allIn;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!allIn) {
      return ChipToken(value, size: size, color: raceChipGreen);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.55),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ChipToken(
          kAllInChips,
          size: size - 8,
          color: AppColors.burgundy,
        ),
      ),
    );
  }
}

/// Ficha que cae en su sitio cada vez que cambia lo apostado. Con
/// `disableAnimations` el cambio es instantáneo.
class ChipDrop extends StatelessWidget {
  const ChipDrop({
    super.key,
    required this.value,
    required this.allIn,
    this.size = 44,
  });

  final int value;
  final bool allIn;
  final double size;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 360),
        transitionBuilder: (child, a) => SlideTransition(
          position: Tween(
            begin: const Offset(0, -1.1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.bounceOut)),
          child: FadeTransition(opacity: a, child: child),
        ),
        child: RaceChip(
          value,
          allIn: allIn,
          size: size,
          key: ValueKey('$value-$allIn'),
        ),
      ),
    );
  }
}

/// Sello del boleto ("COBRA" / "PAGA"). Cae sobre el boleto con un pequeño
/// retardo; con `disableAnimations` aparece directamente.
class RaceStamp extends StatelessWidget {
  const RaceStamp.cobra({super.key, this.delayMs = 0})
    : text = 'COBRA',
      color = _stampGreen;

  /// En Retos y Sorbos quien acierta no cobra nada: el sello dice que acierta.
  const RaceStamp.acierta({super.key, this.delayMs = 0})
    : text = 'ACIERTA',
      color = _stampGreen;

  const RaceStamp.paga({super.key, this.delayMs = 0})
    : text = 'PAGA',
      color = AppColors.burgundy;

  /// En Retos y Sorbos "PAGA" suena a coste o a consumo: el sello dice a quién le toca.
  const RaceStamp.leToca({super.key, this.delayMs = 0})
    : text = 'LE TOCA',
      color = AppColors.burgundy;

  final String text;
  final Color color;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final stamp = Transform.rotate(
      angle: -0.16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(maxScaleFactor: 1.3),
          style: TextStyle(
            fontFamily: AppFonts.display,
            fontSize: 16,
            height: 1.1,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return stamp;
    final total = 380 + delayMs;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      curve: Interval(delayMs / total, 1, curve: Curves.easeOutCubic),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 1.8 - 0.8 * t, child: child),
      ),
      child: stamp,
    );
  }
}

/// Texto sobre papel: tinta oscura.
class InkText extends StatelessWidget {
  const InkText({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: const TextStyle(color: raceInk),
    child: child,
  );
}
