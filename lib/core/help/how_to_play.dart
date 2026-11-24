import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_icons.dart';

const howToPlayAsset = 'assets/content/es/ayuda.json';

class HowToPlay {
  const HowToPlay({
    required this.id,
    required this.titulo,
    required this.pasos,
    this.consejo,
  });
  final String id;
  final String titulo;
  final List<String> pasos;
  final String? consejo;
}

/// Parsea el JSON de ayuda; tolerante: entradas rotas se descartan, JSON roto -> {}.
Map<String, HowToPlay> parseHowToPlay(String raw) {
  try {
    final data = jsonDecode(raw);
    if (data is! List) return const {};
    final out = <String, HowToPlay>{};
    for (final e in data) {
      if (e is! Map) continue;
      final id = e['id'];
      final titulo = e['titulo'];
      if (id is! String || titulo is! String) continue;
      final pasos = [
        for (final p in (e['pasos'] is List ? e['pasos'] as List : const []))
          if (p is String) p,
      ];
      final consejo = e['consejo'];
      out[id] = HowToPlay(
        id: id,
        titulo: titulo,
        pasos: pasos,
        consejo: consejo is String ? consejo : null,
      );
    }
    return out;
  } catch (_) {
    return const {};
  }
}

final howToPlayProvider = FutureProvider<Map<String, HowToPlay>>((ref) async {
  try {
    return parseHowToPlay(await rootBundle.loadString(howToPlayAsset));
  } catch (_) {
    return const {};
  }
});

/// Botón "¿Cómo se juega?" para la AppBar de la pantalla de configuración.
/// No aparece si no hay ayuda para [gameId].
class HowToPlayButton extends ConsumerWidget {
  const HowToPlayButton(this.gameId, {super.key});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final help = ref.watch(howToPlayProvider).value?[gameId];
    if (help == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: '¿Cómo se juega?',
      excludeSemantics: true,
      child: IconButton(
        tooltip: '¿Cómo se juega?',
        icon: AppIcon.help.widget(),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (_) => _HowToPlaySheet(help),
        ),
      ),
    );
  }
}

class _HowToPlaySheet extends StatelessWidget {
  const _HowToPlaySheet(this.help);
  final HowToPlay help;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(help.titulo, style: t.titleLarge),
            const SizedBox(height: 12),
            for (final (i, p) in help.pasos.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}.', style: t.titleSmall),
                    ),
                    Expanded(child: Text(p, style: t.bodyMedium)),
                  ],
                ),
              ),
            if (help.consejo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Consejo: ${help.consejo}',
                style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
