import 'package:material_ui/material_ui.dart';

import 'consequences.dart';
import 'retos_filter.dart';

export 'retos_filter.dart' show kFallbackRetos;

/// Muestra lo que paga cada jugador según el [mode] activo.
///
/// [losses] es `{jugador: fichas perdidas}`. Los jugadores con 0 fichas no se
/// muestran. En Sorbos la alternativa "o agua o reto" siempre está visible.
/// En Retos cada jugador ve UN reto (nunca "N retos") del nivel que marca su
/// intensidad: [retoPools] reparte los retos por nivel (D20) y [retoOffset] rota la
/// elección (p. ej. por carta). [retos] es una lista plana que solo se usa si no hay
/// [retoPools]; sin ninguna de las dos se usa [kFallbackRetos].
class ConsequenceBanner extends StatelessWidget {
  const ConsequenceBanner({
    super.key,
    required this.losses,
    required this.mode,
    this.retos,
    this.retoPools,
    this.retoOffset = 0,
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

  /// Retos por nivel; manda sobre [retos].
  final RetoPools? retoPools;

  /// Desplazamiento de la rotación de retos (se suma al orden de la fila).
  final int retoOffset;

  /// Texto de la cantidad para [loss] (p. ej. "−2 en la Copa", "Un reto").
  static String amountText(ConsequenceLoss loss, {bool inCup = true}) {
    final n = loss.amount;
    switch (loss.mode) {
      case ConsequenceMode.puntos:
        if (!inCup) return n == 1 ? '−1 ficha' : '−$n fichas';
        return '−$n en la Copa';
      case ConsequenceMode.retos:
        return kUnReto;
      case ConsequenceMode.sorbos:
        return '${n == 1 ? '1 sorbo' : '$n sorbos'} · o agua o reto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pools = retoPools ?? RetoPools.flat(retos);
    final rows = <Widget>[];
    var retoIndex = 0;
    for (final e in losses.entries) {
      final loss = resolveLoss(e.value, mode);
      if (loss.amount == 0) continue;
      final reto = mode == ConsequenceMode.retos
          ? pools.pick(loss.amount, retoOffset + retoIndex++)
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
