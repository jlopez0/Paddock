import 'package:material_ui/material_ui.dart';

/// Tonos locales de los mazos y del Infiltrado para texto pequeño sobre fondos oscuros.
/// No tocan la paleta global ([AppColors]): solo suben el contraste de ciertos usos.
///
/// Contrastes (WCAG) calculados contra `AppColors.background`, `surface`, `surfaceHigh`
/// y `outline` (chip seleccionado): todos >= 4,5:1.
abstract final class GameColors {
  /// Texto secundario: etiquetas, ayudas y contadores (>= 5,8:1 en cualquier superficie).
  static const mutedText = Color(0xFFB4C8BB);

  /// Violeta claro para texto del Infiltrado (p. ej. "La palabra"): >= 5,2:1.
  /// El violeta de marca (`0xFF8E6BE0`) queda para bordes y rellenos.
  static const infiltradoText = Color(0xFFC4AEF7);
}
