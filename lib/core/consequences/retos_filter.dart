import '../content/prompts.dart';

/// Retos de reserva por si `retos.json` no carga o queda vacío.
const List<String> kFallbackRetos = [
  'Cuenta un chiste en menos de 20 segundos.',
  'Haz un cumplido sincero a la persona de tu derecha.',
  'Imita a un animal hasta que alguien lo adivine.',
  'Di tres cosas que te gusten del grupo.',
  'Canta el estribillo de una canción conocida.',
  'Haz tu mejor cara de sorpresa durante 10 segundos.',
];

/// Textos de reto permitidos: `suave` y `picante` siempre; `atrevido` solo si
/// el usuario ha confirmado ser mayor de edad ([adultConfirmed]).
List<String> filterRetos(
  Iterable<Prompt> prompts, {
  required bool adultConfirmed,
}) => [
  for (final p in prompts)
    if ((p.level != PromptLevel.atrevido || adultConfirmed) &&
        p['texto'].isNotEmpty)
      p['texto'],
];

/// Retos agrupados por nivel. En Retos nunca se piden "N retos": cada evento con
/// consecuencia saca UN reto cuyo nivel depende de la intensidad (D20).
///
/// Intensidad 1 -> suave, 2 -> picante, 3 o más -> atrevido si hay +18 y, si no, picante.
/// Si el pool de ese nivel queda vacío se usa cualquier reto permitido y, como último
/// recurso, [kFallbackRetos].
class RetoPools {
  const RetoPools._(this._byLevel, this._any);

  /// Agrupa [prompts] por nivel. `atrevido` solo cuenta con [adultConfirmed].
  /// Con `null` o sin retos válidos todo cae en [kFallbackRetos].
  factory RetoPools.fromPrompts(
    Iterable<Prompt>? prompts, {
    required bool adultConfirmed,
  }) {
    final by = <PromptLevel, List<String>>{
      for (final l in PromptLevel.values) l: <String>[],
    };
    final any = <String>[];
    for (final p in prompts ?? const <Prompt>[]) {
      if (p.level == PromptLevel.atrevido && !adultConfirmed) continue;
      final text = p['texto'];
      if (text.isEmpty) continue;
      by[p.level]!.add(text);
      any.add(text);
    }
    return RetoPools._(by, any);
  }

  /// Misma lista en todos los niveles (o [kFallbackRetos] si es `null` o vacía).
  factory RetoPools.flat(List<String>? texts) {
    final list = texts ?? const <String>[];
    return RetoPools._({for (final l in PromptLevel.values) l: list}, list);
  }

  final Map<PromptLevel, List<String>> _byLevel;
  final List<String> _any;

  /// Nivel de reto que toca a [intensity] antes de comprobar el +18.
  static PromptLevel levelFor(int intensity) => intensity <= 1
      ? PromptLevel.suave
      : intensity == 2
      ? PromptLevel.picante
      : PromptLevel.atrevido;

  /// Retos posibles para [intensity]. Nunca está vacía.
  List<String> forIntensity(int intensity) {
    final level = levelFor(intensity);
    var pool = _byLevel[level]!;
    // Sin +18 (o sin cartas atrevidas) el máximo baja a picante.
    if (pool.isEmpty && level == PromptLevel.atrevido) {
      pool = _byLevel[PromptLevel.picante]!;
    }
    if (pool.isNotEmpty) return pool;
    return _any.isNotEmpty ? _any : kFallbackRetos;
  }

  /// Un reto para [intensity]. [offset] rota el pool (p. ej. por carta o por fila).
  String pick(int intensity, [int offset = 0]) {
    final pool = forIntensity(intensity);
    return pool[offset.abs() % pool.length];
  }
}
