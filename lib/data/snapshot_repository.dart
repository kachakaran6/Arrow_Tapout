import 'dart:convert';

import 'package:arrowtapout/data/progress_repository.dart';
import 'package:arrowtapout/data/stats_and_snapshot_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnapshotRepository {
  SnapshotRepository(this._prefs);

  final SharedPreferences? _prefs;
  static const String _key = 'unwind.snapshot';

  LevelSnapshot? getSnapshot() {
    if (_prefs == null) return null;
    final str = _prefs.getString(_key);
    if (str == null) return null;
    try {
      final map = jsonDecode(str) as Map<String, dynamic>;
      return LevelSnapshot.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSnapshot({
    required int levelId,
    required Set<int> activeThreadIds,
    required int mistakes,
    required int hintsUsed,
  }) async {
    if (_prefs == null) return;
    final snapshot = LevelSnapshot(
      levelId: levelId,
      activeThreadIds: activeThreadIds,
      mistakes: mistakes,
      hintsUsed: hintsUsed,
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearSnapshot() async {
    if (_prefs == null) return;
    await _prefs.remove(_key);
  }
}

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SnapshotRepository(prefs);
});
