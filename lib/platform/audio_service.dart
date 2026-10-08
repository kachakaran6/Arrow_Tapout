import 'dart:math' as math;

import 'package:arrowtapout/data/settings_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  AudioService(this._ref) {
    _init();
  }

  final Ref _ref;
  final math.Random _rand = math.Random();

  // 4-player pool for pull sounds to allow smooth rapid overlap
  final List<AudioPlayer> _pullPlayers = [];
  int _pullIndex = 0;

  AudioPlayer? _blockPlayer;
  AudioPlayer? _completePlayer;
  AudioPlayer? _uiPlayer;

  bool _initialized = false;

  void _init() {
    try {
      AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.none,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {
              AVAudioSessionOptions.mixWithOthers,
            },
          ),
        ),
      );

      for (var i = 0; i < 4; i++) {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        _pullPlayers.add(p);
      }

      _blockPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _completePlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _uiPlayer = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
      _initialized = true;
    } catch (_) {
      // Audio fallback
    }
  }

  bool get _soundEnabled => _ref.read(settingsProvider).sound;

  void playPull() {
    if (!_soundEnabled || !_initialized || _pullPlayers.isEmpty) return;
    try {
      final player = _pullPlayers[_pullIndex];
      _pullIndex = (_pullIndex + 1) % _pullPlayers.length;

      // Subtle pitch variation +/- 6%
      final rate = 1.0 + (_rand.nextDouble() * 0.12 - 0.06);
      player.setPlaybackRate(rate);
      player.play(AssetSource('audio/pull.ogg'), volume: 0.85);
    } catch (_) {}
  }

  void playBlock() {
    if (!_soundEnabled || !_initialized || _blockPlayer == null) return;
    try {
      _blockPlayer!.play(AssetSource('audio/block.ogg'), volume: 0.9);
    } catch (_) {}
  }

  void playComplete() {
    if (!_soundEnabled || !_initialized || _completePlayer == null) return;
    try {
      _completePlayer!.play(AssetSource('audio/complete.ogg'), volume: 0.95);
    } catch (_) {}
  }

  void playUi() {
    if (!_soundEnabled || !_initialized || _uiPlayer == null) return;
    try {
      _uiPlayer!.play(AssetSource('audio/ui.ogg'), volume: 0.7);
    } catch (_) {}
  }

  void dispose() {
    for (final p in _pullPlayers) {
      p.dispose();
    }
    _blockPlayer?.dispose();
    _completePlayer?.dispose();
    _uiPlayer?.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService(ref);
  ref.onDispose(service.dispose);
  return service;
});
