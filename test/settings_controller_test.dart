import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paddock/core/settings/app_feedback.dart';
import 'package:paddock/core/settings/settings_controller.dart';
import 'package:paddock/core/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  test('por defecto sonido y vibración están activados', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    final s = c.read(settingsProvider);
    expect(s.sound, isTrue);
    expect(s.vibration, isTrue);
  });

  test('se guardan, se recuperan y se propagan a AppFeedback', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier)
      ..setSound(false)
      ..setVibration(false);
    expect(AppFeedback.soundEnabled, isFalse);
    expect(AppFeedback.vibrationEnabled, isFalse);

    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    final s = c2.read(settingsProvider);
    expect(s.sound, isFalse);
    expect(s.vibration, isFalse);

    c2.read(settingsProvider.notifier)
      ..setSound(true)
      ..setVibration(true);
  });
}
