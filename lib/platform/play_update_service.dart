import 'dart:io';

import 'package:arrowtapout/data/progress_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UpdateService {
  Future<void> checkForUpdates(BuildContext context);
  Future<void> completeFlexibleUpdateIfReady();
}

class NoOpUpdateService implements UpdateService {
  @override
  Future<void> checkForUpdates(BuildContext context) async {}

  @override
  Future<void> completeFlexibleUpdateIfReady() async {}
}

class PlayUpdateService implements UpdateService {
  PlayUpdateService(this._prefs);

  final SharedPreferences? _prefs;
  static const String _keyLastCheck = 'unwind.play.lastUpdateCheck';
  static const String _keyLastDismiss = 'unwind.play.lastUpdateDismiss';

  bool _flexibleDownloaded = false;

  @override
  Future<void> checkForUpdates(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCheck = _prefs?.getInt(_keyLastCheck) ?? 0;
    final lastDismiss = _prefs?.getInt(_keyLastDismiss) ?? 0;

    // Rate limit 1: Check at most once per 12 hours
    if (now - lastCheck < 12 * 3600 * 1000) return;

    // Rate limit 2: If dismissed, wait at least 3 days
    if (now - lastDismiss < 3 * 24 * 3600 * 1000) return;

    try {
      await _prefs?.setInt(_keyLastCheck, now);
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability ==
          UpdateAvailability.developerTriggeredUpdateInProgress) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // High priority (>= 4) uses immediate update
        if (updateInfo.immediateUpdateAllowed &&
            (updateInfo.updatePriority >= 4)) {
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          final result = await InAppUpdate.startFlexibleUpdate();
          if (result == AppUpdateResult.success) {
            _flexibleDownloaded = true;
          } else {
            await _prefs?.setInt(
                _keyLastDismiss, DateTime.now().millisecondsSinceEpoch);
          }
        }
      }
    } catch (_) {
      // Offline, non-Play install, or API unavailable - fails silently
    }
  }

  @override
  Future<void> completeFlexibleUpdateIfReady() async {
    if (!Platform.isAndroid || !_flexibleDownloaded) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
      _flexibleDownloaded = false;
    } catch (_) {}
  }
}

final playUpdateServiceProvider = Provider<UpdateService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (Platform.isAndroid) {
    return PlayUpdateService(prefs);
  }
  return NoOpUpdateService();
});
