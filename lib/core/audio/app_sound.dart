import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../settings/app_feedback.dart';

/// Efectos de sonido de mesa (fichas, cartas, aciertos...). Sonidos CC0 de Kenney,
/// ver `assets/audio/LICENSE-Kenney-CC0.txt`.
///
/// Cómo engancharlo (sin `ref`, respeta Ajustes > Sonido por sí solo):
/// ```dart
/// playSound(AppSound.chip);          // al apostar
/// playSound(AppSound.card);          // al girar una carta
/// ```
/// Opcional: `unawaited(preloadSounds())` en el arranque para evitar el retardo del
/// primer sonido. Si el sonido está desactivado, o el audio falla, no pasa nada.
enum AppSound {
  chip('audio/chip.ogg'),
  chipSoft('audio/chip_soft.ogg'),
  card('audio/card.ogg'),
  correct('audio/correct.ogg'),
  wrong('audio/wrong.ogg'),
  tap('audio/tap.ogg'),
  podium('audio/podium.ogg');

  const AppSound(this.asset);

  /// Ruta relativa a `assets/` (formato de `AssetSource`).
  final String asset;
}

/// Reproduce un sonido. Seguro de llamar desde cualquier sitio.
void playSound(AppSound sound) => AppSoundService.instance.play(sound);

/// Precarga todos los sonidos (no hace nada si falla).
Future<void> preloadSounds() => AppSoundService.instance.preload();

/// Backend de audio, sustituible en tests.
abstract class SoundBackend {
  Future<void> preload(AppSound sound);
  Future<void> play(AppSound sound);
}

class AppSoundService {
  AppSoundService(this._backend);

  static AppSoundService instance = AppSoundService(AudioplayersBackend());

  /// Solo para tests.
  @visibleForTesting
  static void useBackend(SoundBackend backend) =>
      instance = AppSoundService(backend);

  final SoundBackend _backend;

  Future<void> preload() async {
    for (final s in AppSound.values) {
      try {
        await _backend.preload(s);
      } catch (_) {
        // Sin audio la app funciona igual.
      }
    }
  }

  void play(AppSound sound) {
    if (!AppFeedback.soundEnabled) return;
    unawaited(() async {
      try {
        await _backend.play(sound);
      } catch (_) {
        // Plataforma sin audio o fallo del reproductor: se ignora.
      }
    }());
  }
}

/// Un reproductor por tipo de sonido: un mismo sonido se reinicia en vez de apilarse.
class AudioplayersBackend implements SoundBackend {
  final Map<AppSound, AudioPlayer> _players = {};

  Future<AudioPlayer> _player(AppSound s) async {
    final existing = _players[s];
    if (existing != null) return existing;
    final p = AudioPlayer();
    _players[s] = p;
    await p.setPlayerMode(PlayerMode.lowLatency);
    await p.setReleaseMode(ReleaseMode.stop);
    return p;
  }

  @override
  Future<void> preload(AppSound sound) async {
    final p = await _player(sound);
    await p.setSource(AssetSource(sound.asset));
  }

  @override
  Future<void> play(AppSound sound) async {
    final p = await _player(sound);
    await p.stop();
    await p.play(AssetSource(sound.asset), volume: 0.7);
  }
}
