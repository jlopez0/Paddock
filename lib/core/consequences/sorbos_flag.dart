import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compilación con o sin el modo Sorbos. Por defecto (Android) está activo.
/// Para iOS: `flutter build ipa --dart-define=SORBOS=false` (ver D15 y COMPLIANCE #3).
const bool kSorbosEnabled = bool.fromEnvironment('SORBOS', defaultValue: true);

/// Lo que lee la app para saber si el modo Sorbos existe. Un `const` de entorno no
/// se puede cambiar en un test, así que se inyecta aquí (valor por defecto: [kSorbosEnabled]).
final sorbosEnabledProvider = Provider<bool>((ref) => kSorbosEnabled);
