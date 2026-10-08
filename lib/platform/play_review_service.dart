import 'dart:io';

import 'package:arrowtapout/data/progress_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ReviewService {
  Future<void> scheduleReviewIfEligible(BuildContext context);
}

class NoOpReviewService implements ReviewService {
  @override
  Future<void> scheduleReviewIfEligible(BuildContext context) async {}
}

class PlayReviewService implements ReviewService {
  PlayReviewService(this._prefs, this._ref);

  final SharedPreferences? _prefs;
  final Ref _ref;

  static const List<int> milestones = [8, 30, 70, 130];
  static const String _keyLastRequest = 'unwind.play.lastReviewRequest';
  static const String _keyMilestonesTried = 'unwind.play.reviewMilestonesTried';

  @override
  Future<void> scheduleReviewIfEligible(BuildContext context) async {
    if (!Platform.isAndroid) return;

    final progress = _ref.read(progressProvider);
    final completedCount = progress.stars.length;

    // Find if we hit an untried milestone
    final triedStr = _prefs?.getString(_keyMilestonesTried) ?? '';
    final triedSet =
        triedStr.isEmpty ? <int>{} : triedStr.split(',').map(int.parse).toSet();

    int? activeMilestone;
    for (final m in milestones) {
      if (completedCount >= m && !triedSet.contains(m)) {
        activeMilestone = m;
        break;
      }
    }

    if (activeMilestone == null) return;

    // 45-day cooldown check
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastReq = _prefs?.getInt(_keyLastRequest) ?? 0;
    const cooldown45DaysMs = 45 * 24 * 3600 * 1000;
    if (now - lastReq < cooldown45DaysMs) return;

    // Schedule call with 600ms delay after landing on Level select
    await Future.delayed(const Duration(milliseconds: 600));
    if (!context.mounted) return;

    try {
      final inAppReview = InAppReview.instance;
      final available = await inAppReview.isAvailable();
      if (available) {
        // Record attempt regardless of whether Play shows bottom sheet
        triedSet.add(activeMilestone);
        await _prefs?.setString(_keyMilestonesTried, triedSet.join(','));
        await _prefs?.setInt(
            _keyLastRequest, DateTime.now().millisecondsSinceEpoch);

        await inAppReview.requestReview();
      }
    } catch (_) {
      // Swallowed silently
    }
  }
}

final playReviewServiceProvider = Provider<ReviewService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  if (Platform.isAndroid) {
    return PlayReviewService(prefs, ref);
  }
  return NoOpReviewService();
});
