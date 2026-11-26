import '../../core/consequences/consequences.dart';
import 'domain/bets.dart';

/// Textos puros de la Carrera (sin Flutter) para poder probarlos.
///
/// Criterio de dos capas (D19): la consecuencia va en la unidad del modo (reto o sorbo);
/// la Copa sigue en fichas. Fuera de la Copa, "ficha" solo se dice en modo Fichas, y
/// "Paga/Pagan/Cobran" también: en Retos y Sorbos se dice "Les toca" y "Aciertan".

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
      return 'Reparte $targets All-in · hasta $kRoundCap retos cada uno';
    case ConsequenceMode.sorbos:
      return 'Reparte $targets All-in · hasta $kRoundCap sorbos cada uno · o agua o reto';
  }
}

/// Aclaración fija de lo que vale un All-in en la Copa. Solo en Fichas: en Retos y Sorbos
/// la cifra (10) no es lo que se juega y chocaría con el tope de [kRoundCap].
String? allInCupNote(ConsequenceMode mode) => mode == ConsequenceMode.puntos
    ? 'En la Copa, cada All-in vale $kAllInChips fichas'
    : null;

/// Línea "Ganan: Marta (+5)" o "Pagan: Ana (−2), Luis (−3)". Vacía si no hay nadie.
/// Son dos listas independientes: no hay transferencia de unos a otros.
String chipsLine(String label, Map<String, int> byName, {required bool gain}) {
  if (byName.isEmpty) return '';
  final sign = gain ? '+' : '−';
  return '$label: ${[for (final e in byName.entries) '${e.key} ($sign${e.value})'].join(', ')}';
}

/// Cabecera de quien acierta. "Cobran" es de Fichas; en Retos y Sorbos no se cobra nada.
String winnersTitle(ConsequenceMode mode) =>
    mode == ConsequenceMode.puntos ? 'Cobran' : 'Aciertan';

/// Título del boleto ganador sin All-in: "Ana cobra 3 fichas" (Fichas) o "Ana acierta".
String winnerTicketTitle(ConsequenceMode mode, String name, int chips) =>
    mode == ConsequenceMode.puntos
    ? '$name cobra ${chipsText(chips)}'
    : '$name acierta';

/// Motivo bajo el nombre: "Apostó 3 fichas a Oros" (Fichas) o "Apostó a Oros" (Retos y Sorbos,
/// donde la cantidad ya va junto al nombre). Con All-in: "Apostó All-in a Oros".
String betReasonText(ConsequenceMode mode, Bet b, {bool failed = false}) {
  final what = b.isAllIn
      ? 'All-in '
      : mode == ConsequenceMode.puntos
      ? '${chipsText(b.chips)} '
      : '';
  return 'Apostó ${what}a ${b.suit.label}${failed ? ' y falló' : ''}';
}

/// "Pagar" y "Cobrar" quedan solo en Fichas. En Retos y Sorbos se dice a quién le toca,
/// y en Sorbos siempre con la alternativa.
String losersTitle(ConsequenceMode mode) =>
    mode == ConsequenceMode.puntos ? 'Pagan' : 'Les toca';

/// Línea de quiénes pierden: "Pagan: Ana (−2)" en Fichas, "Les toca: Ana (2 retos)" en Retos
/// y "Les toca: Ana (2 sorbos · o agua o reto)" en Sorbos (con el tope de [kRoundCap] aplicado).
String losersLine(ConsequenceMode mode, Map<String, int> byName) {
  if (mode == ConsequenceMode.puntos) {
    return chipsLine('Pagan', byName, gain: false);
  }
  final parts = [
    for (final e in byName.entries)
      if (resolveLoss(e.value, mode).amount > 0)
        '${e.key} (${_amountText(mode, resolveLoss(e.value, mode).amount)})',
  ];
  return parts.isEmpty ? '' : 'Les toca: ${parts.join(', ')}';
}

String _amountText(ConsequenceMode mode, int n) =>
    mode == ConsequenceMode.retos ? retosText(n) : sorbosText(n);

/// "2 retos".
String retosText(int n) => n == 1 ? '1 reto' : '$n retos';

/// "2 sorbos · o agua o reto".
String sorbosText(int n) =>
    '${n == 1 ? '1 sorbo' : '$n sorbos'} · o agua o reto';

/// Frase cuando nadie acierta.
String nobodyWonText(ConsequenceMode mode) {
  switch (mode) {
    case ConsequenceMode.puntos:
      return 'Nadie acertó. Pagan todos.';
    case ConsequenceMode.retos:
      return 'Nadie acertó. Les toca a todos.';
    case ConsequenceMode.sorbos:
      return 'Nadie acertó. Les toca a todos · o agua o reto.';
  }
}

/// Botón que lleva al resultado tras la carrera.
String whoPaysLabel(ConsequenceMode mode) =>
    mode == ConsequenceMode.puntos ? '¿Quién paga?' : '¿A quién le toca?';

/// Nota bajo la cabecera `Boletos` en Retos y Sorbos. El número del selector va sin unidad
/// (el rango sigue siendo 1 a 5): lo que se juega lo fija este tope, no la cifra.
String? stakeCapNote(ConsequenceMode mode) {
  switch (mode) {
    case ConsequenceMode.puntos:
      return null;
    case ConsequenceMode.retos:
      return 'Hasta $kRoundCap por ronda';
    case ConsequenceMode.sorbos:
      return 'Hasta $kRoundCap por ronda · o agua o reto';
  }
}

/// Etiqueta accesible del selector de apuesta normal.
String stakeA11yText(ConsequenceMode mode, int value) =>
    mode == ConsequenceMode.puntos
    ? chipsText(value)
    : 'Apuesta de $value';

/// Rótulo bajo la ficha del selector. Sin unidad en Retos y Sorbos.
String stakeCaption(ConsequenceMode mode) =>
    mode == ConsequenceMode.puntos ? 'fichas' : 'apuesta';

/// Etiqueta accesible del All-in en el selector de apuesta.
String allInA11yText(ConsequenceMode mode) {
  switch (mode) {
    case ConsequenceMode.puntos:
      return 'All-in, $kAllInChips fichas';
    case ConsequenceMode.retos:
      return 'All-in, $kRoundCap retos';
    case ConsequenceMode.sorbos:
      return 'All-in, $kRoundCap sorbos, o agua o reto';
  }
}

/// Texto visible del botón All-in.
String allInButtonText(ConsequenceMode mode) {
  switch (mode) {
    case ConsequenceMode.puntos:
      return 'All-in  ·  $kAllInChips fichas';
    case ConsequenceMode.retos:
      return 'All-in  ·  $kRoundCap retos';
    case ConsequenceMode.sorbos:
      return 'All-in  ·  $kRoundCap sorbos';
  }
}
