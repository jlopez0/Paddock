import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/consequences/consequences.dart';

void main() {
  test('constantes', () {
    expect(kMaxChipsPerBet, 5);
    expect(kRoundCap, 3);
  });

  group('resolveLoss', () {
    const chips = [0, 1, 3, 5, 10];

    test('puntos: sin tope', () {
      for (final c in chips) {
        final l = resolveLoss(c, ConsequenceMode.puntos);
        expect(l.amount, c);
        expect(l.hasAlternative, isFalse);
      }
    });

    test('retos: tope de 3', () {
      expect(chips.map((c) => resolveLoss(c, ConsequenceMode.retos).amount), [0, 1, 3, 3, 3]);
      expect(resolveLoss(5, ConsequenceMode.retos).hasAlternative, isFalse);
    });

    test('sorbos: tope de 3 y alternativa agua o reto', () {
      expect(chips.map((c) => resolveLoss(c, ConsequenceMode.sorbos).amount), [0, 1, 3, 3, 3]);
      expect(resolveLoss(10, ConsequenceMode.sorbos).hasAlternative, isTrue);
      expect(resolveLoss(0, ConsequenceMode.sorbos).hasAlternative, isFalse);
    });

    test('negativos cuentan como 0', () {
      expect(resolveLoss(-4, ConsequenceMode.puntos).amount, 0);
    });
  });
}
