import 'package:arrowtapout/design/app_tokens.dart';
import 'package:arrowtapout/design/primitives.dart';
import 'package:arrowtapout/platform/haptics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modal bottom sheet displaying the 3-step rules without losing puzzle state.
class HowToPlaySheet extends ConsumerWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final haptics = ref.read(hapticsServiceProvider);

    final steps = [
      (
        '1. Tap free threads',
        'Tap any thread facing an open path. It will slide smoothly out of the board along its direction.',
      ),
      (
        '2. Watch for blockers',
        'If another thread blocks the path, the tapped thread will bounce and briefly highlight the blocking obstacle.',
      ),
      (
        '3. Unwind the knots',
        'Clear the outermost threads first to free inner threads. Clear every thread to complete the level.',
      ),
    ];

    return Container(
      padding: EdgeInsets.only(
        left: Primitives.space24,
        right: Primitives.space24,
        top: Primitives.space24,
        bottom: MediaQuery.paddingOf(context).bottom + Primitives.space24,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Primitives.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How to play',
                style: tokens.typography.title,
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: tokens.inkMuted),
                tooltip: 'Close',
                onPressed: () {
                  haptics.selection();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: Primitives.space16),
          for (final step in steps) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: Primitives.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.$1,
                    style: tokens.typography.heading.copyWith(fontSize: 16.0),
                  ),
                  const SizedBox(height: Primitives.space4),
                  Text(
                    step.$2,
                    style: tokens.typography.caption.copyWith(
                      color: tokens.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: Primitives.space8),
          FilledButton(
            onPressed: () {
              haptics.selection();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: tokens.accent,
              foregroundColor: tokens.onAccent,
              minimumSize: const Size(double.infinity, 48.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Primitives.radiusButton),
              ),
            ),
            child: Text(
              'Got it',
              style: tokens.typography.label.copyWith(color: tokens.onAccent),
            ),
          ),
        ],
      ),
    );
  }
}
