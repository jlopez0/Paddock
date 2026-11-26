import 'package:material_ui/material_ui.dart';

import 'consequences.dart';

/// Retos de reserva por si `retos.json` no carga o queda vacío.
const List<String> kFallbackRetos = [
  'Cuenta un chiste en menos de 20 segundos.',
  'Haz un cumplido sincero a la persona de tu derecha.',
  'Imita a un animal hasta que alguien lo adivine.',
  'Di tres cosas que te gusten del grupo.',
  'Canta el estribillo de una canción conocida.',
  'Haz tu mejor cara de sorpresa durante 10 segundos.',
];

/// Muestra lo que paga cada jugador según el [mode] activo.
///
/// [losses] es `{jugador: fichas perdidas}`. Los jugadores con 0 fichas no se
/// muestran. En Sorbos la alternativa "o agua o reto" siempre está visible.
/// [retos] es la lista de la que salen los retos en modo Retos; si es null
/// o está vacía se usa [kFallbackRetos].
class ConsequenceBanner extends StatelessWidget {
  const ConsequenceBanner({
    super.key,
    required this.losses,
    required this.mode,
    this.retos,
    this.retoOnly = false,
    this.inCup = true,
  });

  /// En Retos, omite la cantidad (ya dicha en otro sitio) y deja nombre + reto.
  final bool retoOnly;

  /// `false` si esas fichas ya no están en la Copa (p. ej. tras "Nueva noche"): en Fichas
  /// se dice solo la cantidad, sin "en la Copa".
  final bool inCup;

  final Map<String, int> losses;
  final ConsequenceMode mode;
  final List<String>? retos;

  /// Texto de la cantidad para [loss] (p. ej. "−2 en la Copa", "2 retos").
  static String amountText(ConsequenceLoss loss, {bool inCup = true}) {
    final n = loss.amount;
    switch (loss.mode) {
      case ConsequenceMode.puntos:
        if (!inCup) return n == 1 ? '−1 ficha' : '−$n fichas';
        return '−$n en la Copa';
      case ConsequenceMode.retos:
        return n == 1 ? '1 reto' : '$n retos';
      case ConsequenceMode.sorbos:
        return '${n == 1 ? '1 sorbo' : '$n sorbos'} · o agua o reto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pool = (retos == null || retos!.isEmpty) ? kFallbackRetos : retos!;
    final rows = <Widget>[];
    var retoIndex = 0;
    for (final e in losses.entries) {
      final loss = resolveLoss(e.value, mode);
      if (loss.amount == 0) continue;
      final reto = mode == ConsequenceMode.retos
          ? pool[retoIndex++ % pool.length]
          : null;
      rows.add(
        _Row(
          name: e.key,
          text: retoOnly ? '' : amountText(loss, inCup: inCup),
          reto: reto,
        ),
      );
    }
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: rows,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.name, required this.text, this.reto});

  final String name;
  final String text;
  final String? reto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wrap: con letra grande o texto largo ("2 sorbos · o agua o reto") el
            // importe baja a la línea siguiente en vez de desbordar.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 2,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                if (text.isNotEmpty)
                  Text(text, style: theme.textTheme.titleMedium),
              ],
            ),
            if (reto != null) ...[
              const SizedBox(height: 4),
              Text(reto!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}
