import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/consequences/consequences.dart';
import '../core/settings/app_feedback.dart';
import '../core/settings/settings_controller.dart';
import 'app_icons.dart';
import 'app_info.dart';
import 'theme.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
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

  /// Sorbos exige confirmar la edad una sola vez; si se cancela, se mantiene el modo anterior.
  Future<void> _selectMode(
    BuildContext context,
    WidgetRef ref,
    ConsequenceMode mode,
  ) async {
    final controller = ref.read(settingsProvider.notifier);
    if (mode == ConsequenceMode.sorbos &&
        !ref.read(settingsProvider).adultConfirmed) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Solo para mayores de 18'),
          content: const Text(
            'El modo Sorbos es solo para mayores de edad. '
            'Nadie está obligado a beber: siempre se puede elegir agua o un reto.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tengo 18 o más'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      controller.confirmAdult();
    }
    controller.setConsequenceMode(mode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final info = ref.watch(_packageInfoProvider).asData?.value;
    final version = info == null ? '' : '${info.version} (${info.buildNumber})';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontFamily: AppFonts.display, fontSize: 22),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            SwitchListTile(
              secondary: (settings.sound ? AppIcon.volume : AppIcon.volumeOff)
                  .widget(),
              title: const Text('Sonido'),
              subtitle: const Text('Música y efectos'),
              value: settings.sound,
              onChanged: controller.setSound,
            ),
            SwitchListTile(
              secondary: AppIcon.deviceMobile.widget(
                size: 24,
                semanticLabel: 'Vibración',
              ),
              title: const Text('Vibración'),
              value: settings.vibration,
              onChanged: (v) {
                controller.setVibration(v);
                AppFeedback.selection();
              },
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consecuencias',
                    style: TextStyle(
                      fontFamily: AppFonts.display,
                      fontSize: 20,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cómo se pagan las fichas perdidas',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ConsequenceMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ConsequenceMode.puntos,
                          label: Text('Puntos'),
                        ),
                        ButtonSegment(
                          value: ConsequenceMode.retos,
                          label: Text('Retos'),
                        ),
                        ButtonSegment(
                          value: ConsequenceMode.sorbos,
                          label: Text('Sorbos'),
                        ),
                      ],
                      selected: {settings.consequenceMode},
                      onSelectionChanged: (s) =>
                          _selectMode(context, ref, s.first),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
            ListTile(
              leading: AppIcon.privacy.widget(),
              title: const Text('Política de privacidad'),
              trailing: AppIcon.external.widget(
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () => _open(context, kPrivacyUrl),
            ),
            ListTile(
              leading: AppIcon.help.widget(),
              title: const Text('Soporte'),
              trailing: AppIcon.external.widget(
                size: 18,
                color: AppColors.textMuted,
              ),
              onTap: () => _open(context, kSupportUrl),
            ),
            ListTile(
              leading: AppIcon.info.widget(),
              title: const Text('Créditos'),
              trailing: AppIcon.chevronRight.widget(color: AppColors.textMuted),
              onTap: () => context.push('/settings/credits'),
            ),
            const Divider(height: 32),
            ListTile(
              leading: AppIcon.tag.widget(),
              title: const Text('Versión'),
              subtitle: Text(version.isEmpty ? '…' : '$kAppName $version'),
            ),
          ],
        ),
      ),
    );
  }
}
