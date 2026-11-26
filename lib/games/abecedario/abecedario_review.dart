import 'abecedario_data.dart';

/// Resultado que el grupo anota para una letra. Solo es un registro para repasar:
/// no lleva fichas ni consecuencia.
enum AbecedarioMark { hit, miss }

/// Una fila del resumen: la entrada jugada y su resultado (`null` = sin marcar).
class AbecedarioReviewRow {
  const AbecedarioReviewRow(this.entry, this.mark);

  final AbecedarioEntry entry;
  final AbecedarioMark? mark;
}

/// Registro inmutable de aciertos y fallos de una vuelta del Abecedario.
/// Lógica pura (sin Flutter) para poder probarla.
class AbecedarioReview {
  const AbecedarioReview(this.entries, [this._marks = const {}]);

  final List<AbecedarioEntry> entries;
  final Map<int, AbecedarioMark> _marks;

  AbecedarioMark? markOf(int index) => _marks[index];

  /// Anota [mark] en la letra [index]. Repetir la misma marca la quita; la contraria la
  /// sustituye. Un índice fuera de rango se ignora.
  AbecedarioReview mark(int index, AbecedarioMark mark) {
    if (index < 0 || index >= entries.length) return this;
    final next = Map<int, AbecedarioMark>.of(_marks);
    if (next[index] == mark) {
      next.remove(index);
    } else {
      next[index] = mark;
    }
    return AbecedarioReview(entries, next);
  }

  int get hits => _count(AbecedarioMark.hit);
  int get misses => _count(AbecedarioMark.miss);
  int get unmarked => entries.length - hits - misses;

  int _count(AbecedarioMark m) => _marks.values.where((v) => v == m).length;

  List<AbecedarioReviewRow> get rows => [
    for (var i = 0; i < entries.length; i++)
      AbecedarioReviewRow(entries[i], _marks[i]),
  ];

  /// Las falladas, en el orden del abecedario, para repasar su respuesta.
  List<AbecedarioEntry> get missed => [
    for (var i = 0; i < entries.length; i++)
      if (_marks[i] == AbecedarioMark.miss) entries[i],
  ];
}
