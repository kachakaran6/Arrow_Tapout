import 'package:arrowtapout/data/progress_repository.dart';
import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/platform/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final stats = ref.watch(progressProvider).stats;
    final haptics = ref.read(hapticsServiceProvider);

    final statItems = [
      _StatData(label: 'Levels cleared', value: '${stats.levelsCleared}'),
      _StatData(label: 'Total stars', value: '${stats.totalStars}'),
      _StatData(label: 'Threads cleared', value: '${stats.threadsCleared}'),
      _StatData(label: 'Perfect levels', value: '${stats.perfectLevels}'),
      _StatData(
          label: 'Longest streak', value: '${stats.longestPerfectStreak}'),
    ];

    return Scaffold(
      backgroundColor: tokens.bg,
      appBar: AppBar(
        title: Text('Statistics', style: tokens.typography.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: tokens.ink),
          tooltip: 'Back',
          onPressed: () {
            haptics.selection();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Primitives.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 2-column grid of stat cards
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: Primitives.space16,
                    mainAxisSpacing: Primitives.space16,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: statItems.length,
                  itemBuilder: (context, idx) {
                    final item = statItems[idx];
                    return Card(
                      color: tokens.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Primitives.radiusCard),
                        side: BorderSide(color: tokens.threadFaint, width: 1.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(Primitives.space16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.value,
                              style: TextStyle(
                                fontFamily: Primitives.fontDisplay,
                                fontSize: 32.0,
                                fontWeight: FontWeight.w500,
                                color: tokens.ink,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            const SizedBox(height: Primitives.space4),
                            Text(
                              item.label,
                              style: tokens.typography.caption.copyWith(
                                color: tokens.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  const _StatData({required this.label, required this.value});
  final String label;
  final String value;
}
