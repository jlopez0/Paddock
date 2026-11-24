import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../consequences/consequences.dart';
import '../storage.dart';
import 'app_feedback.dart';

class AppSettings {
  const AppSettings({
    this.sound = true,
    this.vibration = true,
    this.consequenceMode = ConsequenceMode.puntos,
    this.adultConfirmed = false,
  });

  final bool sound;
  final bool vibration;
  final ConsequenceMode consequenceMode;
  final bool adultConfirmed;

  AppSettings copyWith({
    bool? sound,
    bool? vibration,
    ConsequenceMode? consequenceMode,
    bool? adultConfirmed,
  }) => AppSettings(
    sound: sound ?? this.sound,
    vibration: vibration ?? this.vibration,
    consequenceMode: consequenceMode ?? this.consequenceMode,
    adultConfirmed: adultConfirmed ?? this.adultConfirmed,
  );
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _soundKey = 'settings.sound.v1';
  static const _vibrationKey = 'settings.vibration.v1';
  static const _modeKey = 'settings.consequenceMode.v1';
  static const _adultKey = 'settings.adultConfirmed.v1';

  @override
  AppSettings build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final adult = _readBool(prefs.get(_adultKey), false);
    var mode = ConsequenceMode.puntos;
    final rawMode = prefs.get(_modeKey);
    final stored = rawMode is String ? rawMode : null;
    for (final m in ConsequenceMode.values) {
      if (m.name == stored) mode = m;
    }
    // Sorbos sin confirmación de edad nunca es válido, aunque el valor guardado lo diga.
    if (mode == ConsequenceMode.sorbos && !adult) mode = ConsequenceMode.puntos;
    final s = AppSettings(
      sound: _readBool(prefs.get(_soundKey), true),
      vibration: _readBool(prefs.get(_vibrationKey), true),
      consequenceMode: mode,
      adultConfirmed: adult,
    );
    _sync(s);
    return s;
  }

  // Tolerante: una clave con otro tipo (prefs corruptas) devuelve el valor por defecto.
  static bool _readBool(Object? v, bool fallback) => v is bool ? v : fallback;

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

  /// No hace nada si se pide `sorbos` sin haber confirmado la edad (`adultConfirmed`).
  void setConsequenceMode(ConsequenceMode mode) {
    if (mode == ConsequenceMode.sorbos && !state.adultConfirmed) return;
    ref.read(sharedPreferencesProvider).setString(_modeKey, mode.name);
    state = state.copyWith(consequenceMode: mode);
  }

  /// Registra que el usuario confirmó ser mayor de edad (diálogo +18). Persistente.
  void confirmAdult() {
    ref.read(sharedPreferencesProvider).setBool(_adultKey, true);
    state = state.copyWith(adultConfirmed: true);
  }

  void _sync(AppSettings s) {
    AppFeedback.soundEnabled = s.sound;
    AppFeedback.vibrationEnabled = s.vibration;
  }
}
