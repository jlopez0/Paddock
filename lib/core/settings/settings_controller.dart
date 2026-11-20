import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage.dart';
import 'app_feedback.dart';

class AppSettings {
  const AppSettings({this.sound = true, this.vibration = true});

  final bool sound;
  final bool vibration;

  // Fase 1: aquí irá el "modo de consecuencias" (fichas, retos, beber...). Aún no existe.

  AppSettings copyWith({bool? sound, bool? vibration}) =>
      AppSettings(sound: sound ?? this.sound, vibration: vibration ?? this.vibration);
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _soundKey = 'settings.sound.v1';
  static const _vibrationKey = 'settings.vibration.v1';

  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final s = AppSettings(
      sound: prefs.getBool(_soundKey) ?? true,
      vibration: prefs.getBool(_vibrationKey) ?? true,
    );
    _sync(s);
    return s;
  }

  void setSound(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_soundKey, value);
    state = state.copyWith(sound: value);
    _sync(state);
  }

  void setVibration(bool value) {
    ref.read(sharedPreferencesProvider).setBool(_vibrationKey, value);
    state = state.copyWith(vibration: value);
    _sync(state);
  }

  void _sync(AppSettings s) {
    AppFeedback.soundEnabled = s.sound;
    AppFeedback.vibrationEnabled = s.vibration;
  }
}
