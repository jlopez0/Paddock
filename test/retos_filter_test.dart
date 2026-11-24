import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/consequences/retos_filter.dart';
import 'package:paddock/core/content/prompts.dart';

void main() {
  const json = '''
{"version":1,"items":[
  {"id":"a","nivel":"suave","texto":"S"},
  {"id":"b","nivel":"picante","texto":"P"},
  {"id":"c","nivel":"atrevido","texto":"A"},
  {"id":"d","nivel":"raro","texto":"X"}
]}''';

  test('atrevido solo con adultConfirmed', () {
    final prompts = parsePrompts(json);
    expect(filterRetos(prompts, adultConfirmed: false), ['S', 'P']);
    expect(filterRetos(prompts, adultConfirmed: true), ['S', 'P', 'A']);
  });

  test('nivel desconocido se descarta sin lanzar', () {
    expect(parsePrompts(json).map((p) => p.id), ['a', 'b', 'c']);
  });
}
