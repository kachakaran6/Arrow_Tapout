/// Statistics tracked across player puzzle sessions.
class GameStats {
  const GameStats({
    this.levelsCleared = 0,
    this.totalStars = 0,
    this.threadsCleared = 0,
    this.perfectLevels = 0,
    this.longestPerfectStreak = 0,
    this.currentPerfectStreak = 0,
  });

  final int levelsCleared;
  final int totalStars;
  final int threadsCleared;
  final int perfectLevels;
  final int longestPerfectStreak;
  final int currentPerfectStreak;

  Map<String, dynamic> toJson() => {
        'levelsCleared': levelsCleared,
        'totalStars': totalStars,
        'threadsCleared': threadsCleared,
        'perfectLevels': perfectLevels,
        'longestPerfectStreak': longestPerfectStreak,
        'currentPerfectStreak': currentPerfectStreak,
      };

  factory GameStats.fromJson(Map<String, dynamic> json) => GameStats(
        levelsCleared: json['levelsCleared'] as int? ?? 0,
        totalStars: json['totalStars'] as int? ?? 0,
        threadsCleared: json['threadsCleared'] as int? ?? 0,
        perfectLevels: json['perfectLevels'] as int? ?? 0,
        longestPerfectStreak: json['longestPerfectStreak'] as int? ?? 0,
        currentPerfectStreak: json['currentPerfectStreak'] as int? ?? 0,
      );

  GameStats copyWith({
    int? levelsCleared,
    int? totalStars,
    int? threadsCleared,
    int? perfectLevels,
    int? longestPerfectStreak,
    int? currentPerfectStreak,
  }) =>
      GameStats(
        levelsCleared: levelsCleared ?? this.levelsCleared,
        totalStars: totalStars ?? this.totalStars,
        threadsCleared: threadsCleared ?? this.threadsCleared,
        perfectLevels: perfectLevels ?? this.perfectLevels,
        longestPerfectStreak: longestPerfectStreak ?? this.longestPerfectStreak,
        currentPerfectStreak: currentPerfectStreak ?? this.currentPerfectStreak,
      );
}

/// In-progress mid-level snapshot to survive app process death.
class LevelSnapshot {
  const LevelSnapshot({
    required this.levelId,
    required this.activeThreadIds,
    required this.mistakes,
    required this.hintsUsed,
    required this.savedAtMs,
  });

  final int levelId;
  final Set<int> activeThreadIds;
  final int mistakes;
  final int hintsUsed;
  final int savedAtMs;

  Map<String, dynamic> toJson() => {
        'levelId': levelId,
        'activeThreadIds': activeThreadIds.toList(),
        'mistakes': mistakes,
        'hintsUsed': hintsUsed,
        'savedAtMs': savedAtMs,
      };

  factory LevelSnapshot.fromJson(Map<String, dynamic> json) => LevelSnapshot(
        levelId: json['levelId'] as int,
        activeThreadIds: (json['activeThreadIds'] as List<dynamic>)
            .map((e) => e as int)
            .toSet(),
        mistakes: json['mistakes'] as int? ?? 0,
        hintsUsed: json['hintsUsed'] as int? ?? 0,
        savedAtMs: json['savedAtMs'] as int? ?? 0,
      );
}
