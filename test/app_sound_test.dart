import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:habinson/core/audio/app_sound.dart';
import 'package:habinson/core/settings/app_feedback.dart';

class _FakeBackend implements SoundBackend {
  final played = <AppSound>[];
  final preloaded = <AppSound>[];
  bool failing = false;

  @override
  Future<void> play(AppSound sound) async {
    if (failing) throw Exception('sin audio');
    played.add(sound);
  }

  @override
  Future<void> preload(AppSound sound) async {
    if (failing) throw Exception('sin audio');
    preloaded.add(sound);
  }
}

void main() {
  late _FakeBackend fake;

  setUp(() {
    fake = _FakeBackend();
    AppSoundService.useBackend(fake);
    AppFeedback.soundEnabled = true;
  });

  tearDown(() => AppFeedback.soundEnabled = true);

  test('reproduce con el sonido activado', () async {
    playSound(AppSound.chip);
    await Future<void>.delayed(Duration.zero);
    expect(fake.played, [AppSound.chip]);
  });

  test('no suena nada con el sonido desactivado', () async {
    AppFeedback.soundEnabled = false;
    for (final s in AppSound.values) {
      playSound(s);
    }
    await Future<void>.delayed(Duration.zero);
    expect(fake.played, isEmpty);
  });

  test('no lanza si el audio falla', () async {
    fake.failing = true;
    expect(() => playSound(AppSound.wrong), returnsNormally);
    await Future<void>.delayed(Duration.zero);
    await preloadSounds();
    expect(fake.played, isEmpty);
  });

  test('preloadSounds precarga todos', () async {
    await preloadSounds();
    expect(fake.preloaded, AppSound.values);
  });

  test('cada sonido tiene su archivo y pesa poco', () {
    var total = 0;
    for (final s in AppSound.values) {
      final f = File('assets/${s.asset}');
      expect(f.existsSync(), isTrue, reason: s.asset);
      total += f.lengthSync();
    }
    expect(total, lessThan(400 * 1024));
  });
}
