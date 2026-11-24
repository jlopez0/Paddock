import '../../core/consequences/consequences.dart';
import 'domain/bets.dart';

/// Textos puros de la Carrera (sin Flutter) para poder probarlos.

String chipsText(int n) => n == 1 ? '1 ficha' : '$n fichas';

/// Lo apostado: `3 fichas` o `All-in`.
String betText(Bet b) => b.isAllIn ? 'All-in' : chipsText(b.chips);

/// Cuántos All-in reparte un ganador: `All-in` o `2 All-in` (sin el críptico "×2").
String allInCountText(int n) => '$n All-in';

/// Qué reparte quien acierta con All-in, según el modo de consecuencias.
/// [targets] es a cuántas personas distintas puede repartir.
String allInShareText(ConsequenceMode mode, int targets) {
  final who = targets == 1 ? '1 persona' : '$targets personas distintas';
  switch (mode) {
    case ConsequenceMode.puntos:
      return 'Reparte $targets All-in a $who';
    case ConsequenceMode.retos:
      return 'Reparte un reto a $who';
    case ConsequenceMode.sorbos:
      return 'Reparte hasta $kRoundCap sorbos a $who';
  }
}

/// Aclaración fija de lo que vale un All-in en la Copa.
String get allInCupNote => 'En la Copa, cada All-in vale $kAllInChips fichas';

/// Línea "Ganan: Marta (+5)" o "Pagan: Ana (−2), Luis (−3)". Vacía si no hay nadie.
/// Son dos listas independientes: no hay transferencia de unos a otros.
String chipsLine(String label, Map<String, int> byName, {required bool gain}) {
  if (byName.isEmpty) return '';
  final sign = gain ? '+' : '−';
  return '$label: ${[for (final e in byName.entries) '${e.key} ($sign${e.value})'].join(', ')}';
}

/// Línea extra "−10 en la Copa" para los modos retos y sorbos (en puntos ya lo dice el importe).
String? cupLineFor(ConsequenceMode mode, int chips) =>
    mode == ConsequenceMode.puntos || chips <= 0 ? null : '−$chips en la Copa';
