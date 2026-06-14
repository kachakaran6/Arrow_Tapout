import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/typography.dart';

/// Overlay shown when the player clears all arrows
class LevelCompleteOverlay extends StatefulWidget {
  final VoidCallback onRestart;
  const LevelCompleteOverlay({super.key, required this.onRestart});

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> {
  bool _star1 = false;
  bool _star2 = false;
  bool _star3 = false;

  @override
  void initState() {
    super.initState();
    // Stagger star reveals
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _star1 = true);
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _star2 = true);
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _star3 = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF1A1F3C).withOpacity(0.95),
            const Color(0xFF0D0F1A).withOpacity(0.98),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "Puzzle Cleared!" text
            Text(
              'Puzzle Cleared!',
              style: GameTypography.puzzleCleared,
            )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                  duration: 600.ms,
                )
                .fadeIn(duration: 300.ms),

            const SizedBox(height: 24),

            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StarWidget(visible: _star1, delay: 0),
                const SizedBox(width: 12),
                _StarWidget(visible: _star2, delay: 200),
                const SizedBox(width: 12),
                _StarWidget(visible: _star3, delay: 400),
              ],
            ),

            const SizedBox(height: 48),

            // Next Level button (goes back to same level in Phase 1)
            GestureDetector(
              onTap: widget.onRestart,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECAFF), Color(0xFF78FFB8)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4ECAFF).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  'Play Again',
                  style: GameTypography.button.copyWith(
                    color: const Color(0xFF0D0F1A),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            )
                .animate(delay: 1200.ms)
                .slideY(begin: 1.0, end: 0, curve: Curves.easeOutCubic, duration: 500.ms)
                .fadeIn(duration: 300.ms),
          ],
        ),
      ),
    );
  }
}

class _StarWidget extends StatelessWidget {
  final bool visible;
  final int delay;
  const _StarWidget({required this.visible, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: GameColors.comboHighlight.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.star_rounded,
          color: GameColors.comboHighlight,
          size: 52,
        ),
      ),
    );
  }
}
