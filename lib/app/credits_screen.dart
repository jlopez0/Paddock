import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _ccBySa4 = 'https://creativecommons.org/licenses/by-sa/4.0/';

  Future<void> _openLicense(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(_ccBySa4),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  Future<void> _showLicenses(BuildContext context) async {
    var version = '';
    try {
      version = (await PackageInfo.fromPlatform()).version;
    } catch (_) {}
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: 'Paddock',
      applicationVersion: version,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              '(CC BY-SA 3.0) — creativecommons.org/licenses/by-sa/3.0\n'
              'Cambios: recortadas en cartas individuales y reescaladas.',
              style: muted,
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
                onPressed: () => _openLicense(context),
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
            SizedBox(height: 24),
            Text(
              'Juega con responsabilidad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8),
            Text(
              'Solo para mayores de edad. Nadie está obligado a beber: '
              'cualquier trago se puede cambiar por un reto o un vaso de agua.',
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
