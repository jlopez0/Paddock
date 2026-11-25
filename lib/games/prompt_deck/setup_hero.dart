import 'package:material_ui/material_ui.dart';

import '../../app/app_icons.dart';
import '../../app/theme.dart';
import 'game_colors.dart';

/// Cabecera de las pantallas de preparación: medallón con el icono duotono del
/// juego, el título (aquí, y no en la barra, para que con letra grande pueda
/// ocupar las líneas que necesite), una frase de gancho y la regla.
class SetupHero extends StatelessWidget {
  const SetupHero({
    super.key,
    required this.gameId,
    required this.title,
    required this.color,
    required this.hook,
    this.detail,
  });

  final String gameId;
  final String title;
  final Color color;

  /// Frase de gancho con la voz de la casa.
  final String hook;

  /// Regla o explicación breve bajo el gancho.
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);
    return Column(
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
        const SizedBox(height: 16),
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
          style: TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            height: 1.3,
          ),
        ),
        if (detail != null) ...[
          const SizedBox(height: 8),
          Text(
            detail!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GameColors.mutedText,
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta de fieltro con filete de latón y una etiqueta en versalitas.
class BrassCard extends StatelessWidget {
  const BrassCard({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.brass.withValues(alpha: 0.75)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: GameColors.mutedText,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
