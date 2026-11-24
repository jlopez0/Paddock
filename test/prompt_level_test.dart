import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/content/prompts.dart';

void main() {
  test('PromptLevel.tryParse migra "hot" y no lanza con valores desconocidos', () {
    expect(PromptLevel.tryParse('hot'), PromptLevel.atrevido);
    expect(PromptLevel.tryParse('atrevido'), PromptLevel.atrevido);
    expect(PromptLevel.tryParse('suave'), PromptLevel.suave);
    expect(PromptLevel.tryParse('xyz'), isNull);
    expect(PromptLevel.tryParse(null), isNull);
  });
}
