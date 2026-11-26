/// Modo de consecuencias: qué pasa "en la vida real" cuando un jugador pierde fichas.
/// Lógica pura (sin Flutter) para poder probarla.
enum ConsequenceMode { puntos, retos, sorbos }

/// Máximo de fichas en una apuesta normal.
const int kMaxChipsPerBet = 5;

/// Tope de retos o sorbos por ronda en los modos retos y sorbos.
const int kRoundCap = 3;

/// Lo que paga un jugador tras perder [chips] fichas.
class ConsequenceLoss {
  const ConsequenceLoss(this.mode, this.amount);

  final ConsequenceMode mode;

  /// Puntos (fichas), retos o sorbos, según [mode].
  final int amount;

  /// En sorbos, la alternativa "agua o reto" debe estar siempre a la vista.
  bool get hasAlternative => mode == ConsequenceMode.sorbos && amount > 0;

  @override
  bool operator ==(Object other) =>
      other is ConsequenceLoss && other.mode == mode && other.amount == amount;

  @override
  int get hashCode => Object.hash(mode, amount);

  @override
  String toString() => 'ConsequenceLoss($mode, $amount)';
}

/// Traduce las [chips] perdidas a lo que paga el jugador en [mode].
/// puntos = fichas; retos y sorbos = `min(fichas, kRoundCap)`. Negativos cuentan como 0.
ConsequenceLoss resolveLoss(int chips, ConsequenceMode mode) {
  final c = chips < 0 ? 0 : chips;
  switch (mode) {
    case ConsequenceMode.puntos:
      return ConsequenceLoss(mode, c);
    case ConsequenceMode.retos:
    case ConsequenceMode.sorbos:
      return ConsequenceLoss(mode, c > kRoundCap ? kRoundCap : c);
  }
}

/// Nota bajo el resultado de un juego que suma a la Copa. La Copa va en fichas (D19): solo
/// en Fichas se nombra la unidad; en Retos y Sorbos no se habla de fichas fuera de la Copa.
String cupNoteText(ConsequenceMode mode) => mode == ConsequenceMode.puntos
    ? 'Fichas anotadas en la Copa de la noche.'
    : 'Ya cuenta en la Copa de la noche.';
