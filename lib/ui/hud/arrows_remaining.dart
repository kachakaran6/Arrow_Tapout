import 'package:flutter/material.dart';
import 'package:arrowtapout/design/colors.dart';
import 'package:arrowtapout/design/typography.dart';

/// Animated "arrows remaining" counter HUD widget
class ArrowsRemaining extends StatefulWidget {
  final int remaining;
  final int total;
  const ArrowsRemaining({super.key, required this.remaining, required this.total});

  @override
  State<ArrowsRemaining> createState() => _ArrowsRemainingState();
}

class _ArrowsRemainingState extends State<ArrowsRemaining>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
    ]).animate(_popController);
  }

  @override
  void didUpdateWidget(ArrowsRemaining old) {
    super.didUpdateWidget(old);
    if (widget.remaining != old.remaining) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: GameColors.hudBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GameColors.buttonBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_up_rounded, color: Color(0xFF4ECAFF), size: 16),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Text(
                '${widget.remaining}',
                key: ValueKey(widget.remaining),
                style: GameTypography.hudValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
