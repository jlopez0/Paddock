import 'package:material_ui/material_ui.dart';

/// Paleta "hipódromo nocturno": verdes muy oscuros con acentos dorados.
abstract final class AppColors {
  static const background = Color(0xFF0B1611);
  static const surface = Color(0xFF13241B);
  static const surfaceHigh = Color(0xFF1C3326);
  static const outline = Color(0xFF2B4636);
  static const gold = Color(0xFFE8B84A);
  static const text = Color(0xFFF3EFE0);
  static const textMuted = Color(0xFF9BB2A4);
  static const danger = Color(0xFFE5575C);
  static const success = Color(0xFF5BC27A);

  // Tokens "casa de apuestas de hipódromo" (docs/DISENO_ALMA.md).
  static const brass = Color(0xFFB8862B);

  /// Latón claro para TEXTO sobre fondos verdes oscuros (>= 4.5:1 sobre
  /// background, surface y surfaceHigh). `brass` queda para bordes y
  /// rellenos: como texto no llega al contraste. Mismo tono, mas luminoso.
  static const brassText = Color(0xFFD9A441);

  static const paper = Color(0xFFF3EFE0);
  static const burgundy = Color(0xFF7A2430);
  static const medalGold = Color(0xFFE8B84A);
  static const medalSilver = Color(0xFFC9D1CC);
  static const medalBronze = Color(0xFFC98B5A);
}

/// Familias tipográficas empaquetadas en `assets/fonts/`.
/// Tamano minimo recomendado de Alfa Slab One. Por debajo de ~20 px se
/// empasta y pierde legibilidad: las letras A-D de las opciones de Trivia y
/// Geografia (~16 px) NO deben usarla; van en Figtree w800 (las ajusta otro
/// agente en esas pantallas).
const double kDisplayMinSize = 20;

/// Titulos de AppBar: Alfa Slab One 22 px. El factor de escala del texto del
/// sistema se limita a [kTitleMaxScale] con [clampedTitleScaler].
const double kAppBarTitleSize = 22;
const double kTitleMaxScale = 1.3;

TextScaler clampedTitleScaler(TextScaler s) =>
    s.clamp(maxScaleFactor: kTitleMaxScale);

/// Titulo de AppBar: hereda el estilo del tema y limita la escala del texto
/// del sistema a [kTitleMaxScale]. Usar en TODOS los `AppBar.title`.
class AppTitle extends StatelessWidget {
  const AppTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textScaler: clampedTitleScaler(MediaQuery.textScalerOf(context)),
  );
}

abstract final class AppFonts {
  /// Slab pesada de cartelería; peso único. Solo para títulos y cifras de
  /// ceremonia a partir de ~20 px.
  static const display = 'AlfaSlabOne';

  /// Texto e interfaz (variable 300-900).
  static const body = 'Figtree';
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.gold,
        onPrimary: const Color(0xFF241A00),
        secondary: AppColors.success,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        surfaceContainerHighest: AppColors.surfaceHigh,
        outline: AppColors.outline,
        error: AppColors.danger,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.body,
  );
  final bodyTheme = base.textTheme.apply(
    fontFamily: AppFonts.body,
    bodyColor: AppColors.text,
    displayColor: AppColors.text,
  );
  TextStyle? slab(TextStyle? s) =>
      s?.copyWith(fontFamily: AppFonts.display, fontWeight: FontWeight.w400);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: AppFonts.display,
        fontWeight: FontWeight.w400,
        fontSize: kAppBarTitleSize,
        color: AppColors.text,
      ),
    ),
    textTheme: bodyTheme.copyWith(
      displayLarge: slab(bodyTheme.displayLarge),
      displayMedium: slab(bodyTheme.displayMedium),
      displaySmall: slab(bodyTheme.displaySmall),
      headlineLarge: slab(bodyTheme.headlineLarge),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gold.withValues(alpha: 0.22),
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.outline),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
