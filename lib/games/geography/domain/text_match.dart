const _fold = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
  'ñ': 'n', 'ç': 'c',
};

const _articles = {'el', 'la', 'los', 'las'};

final _alnum = RegExp(r'[a-z0-9]');

/// Minúsculas, sin tildes ni signos y sin artículo inicial:
/// "El Cairo" → "cairo", "Côte d'Ivoire" → "cote d ivoire".
String normalizeText(String input) {
  final sb = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final folded = _fold[ch] ?? ch;
    sb.write(_alnum.hasMatch(folded) ? folded : ' ');
  }
  final words = sb.toString().split(' ').where((w) => w.isNotEmpty).toList();
  if (words.length > 1 && _articles.contains(words.first)) words.removeAt(0);
  return words.join(' ');
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost].reduce((x, y) => x < y ? x : y);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Erratas que se perdonan según la longitud de la respuesta correcta.
int typoTolerance(String normalizedAnswer) {
  final n = normalizedAnswer.length;
  if (n <= 4) return 0;
  if (n <= 8) return 1;
  return 2;
}
