import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/consequences/consequences.dart';
import 'package:habinson/core/settings/app_feedback.dart';
import 'package:habinson/core/settings/settings_controller.dart';
import 'package:habinson/core/storage.dart';
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

  test('el modo de consecuencias es puntos por defecto y adultConfirmed false', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    final s = c.read(settingsProvider);
    expect(s.consequenceMode, ConsequenceMode.puntos);
    expect(s.adultConfirmed, isFalse);
  });

  test('sorbos no se activa sin adultConfirmed', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    final n = c.read(settingsProvider.notifier);
    n.setConsequenceMode(ConsequenceMode.sorbos);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
    n.setConsequenceMode(ConsequenceMode.retos);
    n.setConsequenceMode(ConsequenceMode.sorbos);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.retos);
  });

  test('modo y confirmación se persisten', () async {
    final c = await _container({});
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier)
      ..confirmAdult()
      ..setConsequenceMode(ConsequenceMode.sorbos);
    final prefs = c.read(sharedPreferencesProvider);
    final c2 = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    final s = c2.read(settingsProvider);
    expect(s.adultConfirmed, isTrue);
    expect(s.consequenceMode, ConsequenceMode.sorbos);
  });

  test('sorbos guardado sin confirmación de edad se ignora al leer', () async {
    final c = await _container({'settings.consequenceMode.v1': 'sorbos'});
    addTearDown(c.dispose);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
  });

  test('valor de modo desconocido cae a puntos', () async {
    final c = await _container({'settings.consequenceMode.v1': 'zzz'});
    addTearDown(c.dispose);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
  });

  test('prefs con tipo equivocado no rompen el arranque y dan valores por defecto', () async {
    final c = await _container({
      'settings.sound.v1': 'no',
      'settings.vibration.v1': 3,
      'settings.consequenceMode.v1': 5,
      'settings.adultConfirmed.v1': 'si',
    });
    addTearDown(c.dispose);
    final s = c.read(settingsProvider);
    expect(s.sound, isTrue);
    expect(s.vibration, isTrue);
    expect(s.consequenceMode, ConsequenceMode.puntos);
    expect(s.adultConfirmed, isFalse);
  });

  test('sorbos guardado con adultConfirmed de tipo equivocado cae a puntos', () async {
    final c = await _container({
      'settings.consequenceMode.v1': 'sorbos',
      'settings.adultConfirmed.v1': 1,
    });
    addTearDown(c.dispose);
    expect(c.read(settingsProvider).consequenceMode, ConsequenceMode.puntos);
  });
}
