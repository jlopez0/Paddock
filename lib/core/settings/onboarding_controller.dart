import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';

/// Indicador de "bienvenida +18 ya vista". Va aparte de `AppSettings`.
final onboardingProvider = NotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

class OnboardingController extends Notifier<bool> {
  static const welcomeKey = 'onboarding.welcome.v1';

  @override
  bool build() {
    final v = ref.read(sharedPreferencesProvider).get(welcomeKey);
    return v is bool ? v : false;
  }

  void markWelcomeSeen() {
    ref.read(sharedPreferencesProvider).setBool(welcomeKey, true);
    state = true;
  }
}
