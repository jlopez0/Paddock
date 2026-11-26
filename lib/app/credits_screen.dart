import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/consequences/sorbos_flag.dart';
import 'licenses_screen.dart';
import 'theme.dart';

class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  static const _ccBySa4 = 'https://creativecommons.org/licenses/by-sa/4.0/';

  static const _ccBySa3 = 'https://creativecommons.org/licenses/by-sa/3.0/';

  static const _commonsBaraja =
      'https://commons.wikimedia.org/wiki/File:Baraja_espa%C3%B1ola.svg';

  static const _commonsBarajaCompleta =
      'https://commons.wikimedia.org/wiki/File:Baraja_espa%C3%B1ola_completa.png';

  static const _commonsBasquetteur =
      'https://commons.wikimedia.org/wiki/User:Basquetteur';

  static const _commonsGermarquezm =
      'https://commons.wikimedia.org/wiki/User:Germarquezm';

  static const _ofl =
      'https://openfontlicense.org/open-font-license-official-text/';

  static const _mit = 'https://opensource.org/license/mit';

  static const _cc0 = 'https://creativecommons.org/publicdomain/zero/1.0/';

  Future<void> _openLicense(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  void _showLicenses(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LicensesScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorbos = ref.watch(sorbosEnabledProvider);
    const muted = TextStyle(color: AppColors.textMuted, height: 1.5);
    return Scaffold(
      appBar: AppBar(title: const Text('Créditos')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Baraja española',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Ilustraciones de la baraja "Naipes Libres" de Wikimedia Commons, '
              'por Basquetteur, a partir del trabajo de Germarquezm '
              '("Baraja española.svg" y "Baraja española completa.png").\n'
              'Licencia: Creative Commons Atribución-CompartirIgual 3.0 '
              '(CC BY-SA 3.0).\n'
              'Cambios: recortadas en cartas individuales y reescaladas.',
              style: muted,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _ccBySa3),
                child: const Text('Ver licencia CC BY-SA 3.0'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _commonsBaraja),
                child: const Text('Ver archivo original en Wikimedia Commons'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _commonsBarajaCompleta),
                child: const Text('Ver "Baraja española completa.png"'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _commonsBasquetteur),
                child: const Text('Autoría: Basquetteur en Commons'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _commonsGermarquezm),
                child: const Text('Autoría: Germarquezm en Commons'),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Geografía',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Siluetas, mapas de regiones, nombres y capitales a partir de Natural Earth (dominio público), naturalearthdata.com.\n'
              'Banderas de flagcdn.com, con su proporción oficial.\n'
              'Siluetas simplificadas y datos revisados a mano para esta app.',
              style: muted,
            ),
            SizedBox(height: 24),
            Text(
              'Trivia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Algunas preguntas proceden de Open Trivia DB (opentdb.com), con licencia CC BY-SA 4.0, '
              'traducidas y adaptadas al español. '
              'El resto de preguntas son originales.',
              style: muted,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _ccBySa4),
                child: const Text('Ver licencia CC BY-SA 4.0'),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Música',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Obertura de Guillermo Tell (Rossini, 1829), final. Grabación de la Banda de la Marina de EE. UU. '
              '("Grand Scenes", 2000), obra del gobierno de EE. UU. en dominio público, vía Wikimedia Commons.',
              style: muted,
            ),
            const SizedBox(height: 8),
            Text(
              'Sonidos de mesa (fichas, cartas y podio): Kenney (kenney.nl), '
              'licencia CC0 1.0. Atribución voluntaria. Los sonidos de acierto y fallo '
              'son obra propia, generados por código.',
              style: muted,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _cc0),
                child: const Text('Ver licencia CC0 1.0'),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              child: const Text(
                'Diseño',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Iconos: Phosphor Icons (MIT), © 2020-2021 Phosphor Icons, phosphoricons.com.\n'
              'Tipografías: Alfa Slab One (© 2016 The Alfa Slab One Project Authors) y '
              'Figtree (© 2022 The Figtree Project Authors), con licencia SIL Open Font License 1.1.\n'
              'Confeti: paquete confetti (MIT), de Felix Angelov.\n'
              'Trofeo, mascota, fichas y medallas: dibujados para esta app.',
              style: muted,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _ofl),
                child: const Text('Ver licencia SIL OFL 1.1'),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _openLicense(context, _mit),
                child: const Text('Ver licencia MIT'),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Juega con responsabilidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              sorbos
                  ? 'Solo para mayores de edad. Nadie está obligado a beber: '
                        'cualquier trago se puede cambiar por un reto o un vaso de agua.'
                  : 'Solo para mayores de edad. Nadie está obligado a nada: '
                        'cualquier reto se puede cambiar o saltar.',
              style: muted,
            ),
            const SizedBox(height: 24),
            const Text(
              'Licencias de software',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _showLicenses(context),
                child: const Text('Licencias de paquetes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
