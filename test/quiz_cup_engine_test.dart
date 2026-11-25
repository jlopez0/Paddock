import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/session/session_score.dart';
import 'package:paddock/games/trivia/ui/quiz_fx.dart';

/// Regla de fichas de Trivia y Geografía (docs/decisions.md, 2026-11-25):
/// Pleno +3, Gran carrera (>= 80 %) +2, En el podio (>= 50 %) +1, resto 0.
/// Nunca resta: estos juegos no generan retos ni sorbos.
void main() {
  group('QuizTier.chips', () {
    test('cada escalón vale lo que dice la regla', () {
      expect(QuizTier.pleno.chips, 3);
      expect(QuizTier.granCarrera.chips, 2);
      expect(QuizTier.enElPodio.chips, 1);
      expect(QuizTier.hoyNo.chips, 0);
    });

    test('quizChips depende de la proporción, no del número de preguntas', () {
      expect(quizChips(10, 10), 3);
      expect(quizChips(200, 200), 3);
      expect(quizChips(8, 10), 2);
      expect(quizChips(160, 200), 2);
      expect(quizChips(5, 10), 1);
      expect(quizChips(4, 10), 0);
      expect(quizChips(0, 10), 0);
    });

    test('sin preguntas no suma nada y nunca es negativo', () {
      expect(quizChips(0, 0), 0);
      for (var c = 0; c <= 10; c++) {
        expect(quizChips(c, 10), greaterThanOrEqualTo(0));
      }
    });
  });

  group('Copa', () {
    final at = DateTime(2026, 11, 25, 22);

    test('una vuelta anotada suma al jugador y no se cuenta dos veces', () {
      var s = Session.empty(at);
      s = s.withRound(
        roundId: 'trivia-1',
        gameId: 'trivia',
        deltas: {'ana': quizChips(9, 10)},
        at: at,
      );
      final again = s.withRound(
        roundId: 'trivia-1',
        gameId: 'trivia',
        deltas: {'ana': 3},
        at: at,
      );
      expect(identical(again, s), isTrue);
      expect(s.standings.single.total, 2);
    });

    test('una vuelta de 0 fichas no registra nada', () {
      final s = Session.empty(at).withRound(
        roundId: 'geografia-1',
        gameId: 'geografia',
        deltas: {'ana': quizChips(2, 10)},
        at: at,
      );
      expect(s.isEmpty, isTrue);
    });
  });
}
