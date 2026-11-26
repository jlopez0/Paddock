import 'dart:math';

import '../../core/consequences/consequences.dart';
import '../../core/content/prompts.dart';

/// Cartas por partida si el juego no indica otra cosa. La partida dura siempre lo mismo
/// y el jugador nunca ve cuántas cartas hay guardadas en total.
const int kPromptDefaultRounds = 15;

/// Resultado de repartir una partida: las cartas y el historial de cartas ya jugadas.
typedef DeckDraw = ({List<Prompt> cards, Set<String> played});

/// Reparte una partida de hasta [rounds] cartas de los [levels] elegidos.
///
/// Evita las cartas de [played] (partidas anteriores de esta sesión). Si quedan menos sin
/// jugar de las que hacen falta, se vuelve a barajar todo y el historial empieza de cero.
/// Con menos cartas que [rounds] se juegan todas las que haya.
DeckDraw drawDeck({
  required List<Prompt> all,
  required Set<PromptLevel> levels,
  required Set<String> played,
  required int rounds,
  required Random random,
}) {
  final eligible = all.where((p) => levels.contains(p.level)).toList();
  final fresh = eligible.where((p) => !played.contains(p.id)).toList();
  final reset = fresh.length < rounds;
  final pool = reset ? eligible : fresh;
  final cards = (pool..shuffle(random)).take(rounds).toList();
  return (
    cards: cards,
    played: {if (!reset) ...played, for (final c in cards) c.id},
  );
}

/// Una apuesta de 1 a [kRoundCap] fichas por cada carta de la partida.
List<int> rollStakes(int count, Random random) => [
  for (var i = 0; i < count; i++) 1 + random.nextInt(kRoundCap),
];

/// Titular de la apuesta de una carta según el modo, con el tope de [kRoundCap] ya aplicado.
/// Fichas: nada (null), no se ve ninguna apuesta. Retos: "¡Por 2 retos!". Sorbos: sin
/// exclamación y con la alternativa siempre visible: "Por 2 sorbos · o agua o reto".
String? stakeHeadline(int stake, ConsequenceMode mode) {
  final n = resolveLoss(stake, mode).amount;
  if (n == 0) return null;
  switch (mode) {
    case ConsequenceMode.puntos:
      return null;
    case ConsequenceMode.retos:
      return '¡Por $n ${n == 1 ? 'reto' : 'retos'}!';
    case ConsequenceMode.sorbos:
      return 'Por $n ${n == 1 ? 'sorbo' : 'sorbos'} · o agua o reto';
  }
}
