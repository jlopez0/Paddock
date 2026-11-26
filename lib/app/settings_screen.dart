import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/consequences/consequence_mode_selector.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final info = ref.watch(_packageInfoProvider).asData?.value;
    final version = info == null ? '' : '${info.version} (${info.buildNumber})';

    return Scaffold(
      appBar: AppBar(title: const AppTitle('Ajustes')),
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
              child: const ConsequenceModeSelector(),
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
