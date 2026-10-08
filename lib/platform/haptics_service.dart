import 'package:arrowtapout/data/settings_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HapticsService {
  HapticsService(this._ref);

  final Ref _ref;

  bool get _hapticsEnabled => _ref.read(settingsProvider).haptics;

  /// Light haptic pulse on successful thread pull/exit.
  void light() {
    if (!_hapticsEnabled) return;
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback on blocked tap impact.
  void medium() {
    if (!_hapticsEnabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Subtle click for UI buttons.
  void selection() {
    if (!_hapticsEnabled) return;
    HapticFeedback.selectionClick();
  }
}

final hapticsServiceProvider = Provider<HapticsService>((ref) {
  return HapticsService(ref);
});
