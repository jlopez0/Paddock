import 'package:flutter/services.dart';

/// Sonido y vibración respetando los Ajustes. Se sincroniza desde [SettingsController],
/// así que se puede llamar desde cualquier sitio sin `ref`.
class AppFeedback {
  AppFeedback._();

  static bool soundEnabled = true;
  static bool vibrationEnabled = true;

  static void selection() {
    if (vibrationEnabled) HapticFeedback.selectionClick();
  }

  static void light() {
    if (vibrationEnabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (vibrationEnabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (vibrationEnabled) HapticFeedback.heavyImpact();
  }
}
