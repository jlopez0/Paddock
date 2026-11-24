import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/settings/onboarding_controller.dart';
import 'app_info.dart';
import 'mascot.dart';
import 'theme.dart';

/// Entrada del hero: aparece con un pequeño rebote (sin animación si el
/// sistema las desactiva).
class _HeroIn extends StatelessWidget {
  const _HeroIn({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.7 + 0.3 * t, child: child),
      ),
    );
  }
}

/// Se muestra una sola vez, la primera vez que se abre la app.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  Future<void> _openPrivacy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(kPrivacyUrl),
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
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeroIn(child: Center(child: Jockey(size: 128))),
                  const SizedBox(height: 12),
                  // Sello +18: nunca desborda con letra grande.
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+18',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppFonts.display,
                        fontSize: 64,
                        height: 1.1,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: SizedBox(
                      width: 64,
                      height: 2,
                      child: ColoredBox(color: AppColors.brass),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Juega con responsabilidad',
                    textAlign: TextAlign.center,
                    style: text.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nadie está obligado a beber',
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
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
                    onPressed: () =>
                        ref.read(onboardingProvider.notifier).markWelcomeSeen(),
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
