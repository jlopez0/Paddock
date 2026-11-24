import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/settings/onboarding_controller.dart';
import 'app_info.dart';
import 'theme.dart';

/// Se muestra una sola vez, la primera vez que se abre la app.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _openPrivacy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(kPrivacyUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) messenger.showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '+18',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: AppColors.gold),
                  ),
                  const SizedBox(height: 16),
                  Text('Juega con responsabilidad', textAlign: TextAlign.center, style: text.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Nadie está obligado a beber',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 48),
                  TextButton(
                    key: const Key('welcome-privacy'),
                    onPressed: () => _openPrivacy(context),
                    child: const Text('Política de privacidad'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('welcome-continue'),
                    onPressed: () => ref.read(onboardingProvider.notifier).markWelcomeSeen(),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
