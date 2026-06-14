import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Manages all audio for Arrow Tap-Out
/// Pre-loads all sounds before gameplay begins
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  bool _initialized = false;
  bool _muted = false;

  // Cooldowns
  int _lastThudMs = 0;

  /// Pre-warm all sounds so they play without latency during gameplay
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'whoosh.ogg',
        'thud.ogg',
        'pop.ogg',
        'settle.ogg',
        'combo_tick.ogg',
        'combo_milestone.ogg',
        'level_complete.ogg',
      ]);
      _initialized = true;
    } catch (e) {
      // Audio files may not exist yet in early development — fail gracefully
      debugPrint('AudioService: Could not preload audio: $e');
    }
  }

  /// Start ambient background music loop
  Future<void> startAmbient() async {
    if (!_initialized || _muted) return;
    try {
      await FlameAudio.bgm.play('ambient_loop.ogg', volume: 0.3);
    } catch (e) {
      debugPrint('AudioService: Could not start ambient: $e');
    }
  }

  void playWhoosh() => _play('whoosh.ogg', volume: 0.7);
  void playPop() => _play('pop.ogg', volume: 0.8);
  void playSettle() => _play('settle.ogg', volume: 0.4);
  void playComboTick() => _play('combo_tick.ogg', volume: 0.6);
  void playComboMilestone() {
    _play('combo_milestone.ogg', volume: 0.9);
    // Duck ambient music during milestone
    _duckAmbient();
  }

  void playLevelComplete() => _play('level_complete.ogg', volume: 1.0);

  void playThud() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastThudMs < 100) return; // 100ms cooldown
    _lastThudMs = now;
    _play('thud.ogg', volume: 0.5);
  }

  void _play(String filename, {double volume = 1.0}) {
    if (!_initialized || _muted) return;
    try {
      FlameAudio.play(filename, volume: volume);
    } catch (e) {
      debugPrint('AudioService: Could not play $filename: $e');
    }
  }

  void _duckAmbient() {
    // Duck ambient to 30% of normal → recover after 1.5s
    try {
      FlameAudio.bgm.audioPlayer.setVolume(0.3 * 0.4);
      Future.delayed(const Duration(milliseconds: 1500), () {
        FlameAudio.bgm.audioPlayer.setVolume(0.3);
      });
    } catch (e) {
      // Ignore
    }
  }

  void setMuted(bool muted) {
    _muted = muted;
    if (muted) {
      try { FlameAudio.bgm.pause(); } catch (_) {}
    } else {
      try { FlameAudio.bgm.resume(); } catch (_) {}
    }
  }

  void dispose() {
    try { FlameAudio.bgm.stop(); } catch (_) {}
  }
}
